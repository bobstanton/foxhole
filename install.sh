#!/usr/bin/env bash
set -euo pipefail

REPO="bobstanton/foxhole"
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || echo "")"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Portable lowercase conversion (macOS has Bash 3.2 which lacks ${var,,})
to_lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }

# Read from terminal even when piped
prompt() {
    read -r "$@" </dev/tty
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "linux" ;;
        Darwin*) echo "macos" ;;
        *)       error "Unsupported OS: $(uname -s)" ;;
    esac
}

# Get Firefox base directory (where profiles and Profile Groups are stored)
get_firefox_dir() {
    local os="$1"
    case "$os" in
        linux)  echo "$HOME/.mozilla/firefox" ;;
        macos)  echo "$HOME/Library/Application Support/Firefox" ;;
    esac
}

# Get profiles.ini path
get_profiles_ini() {
    local os="$1"
    case "$os" in
        linux)  echo "$HOME/.mozilla/firefox/profiles.ini" ;;
        macos)  echo "$HOME/Library/Application Support/Firefox/profiles.ini" ;;
    esac
}

# Get Profile Groups database path (Firefox 128+ new profile system)
# If create=true and database doesn't exist, creates the directory structure and database
get_profile_groups_db() {
    local os="$1"
    local create="${2:-false}"
    local profiles_dir
    profiles_dir=$(get_firefox_dir "$os")

    local db_dir="$profiles_dir/Profile Groups"

    # Check for existing database
    if [[ -d "$db_dir" ]]; then
        local db_file
        db_file=$(find "$db_dir" -maxdepth 1 -name "*.sqlite" 2>/dev/null | head -1)
        if [[ -n "$db_file" && -f "$db_file" ]]; then
            echo "$db_file"
            return 0
        fi
    fi

    # Create new database if requested
    if [[ "$create" == "true" ]] && command -v sqlite3 &>/dev/null; then
        mkdir -p "$profiles_dir"
        mkdir -p "$db_dir"

        # Generate random 8-char hex filename like Firefox does
        local db_name
        db_name=$(LC_ALL=C tr -dc 'a-f0-9' < /dev/urandom | head -c 8)
        local db_file="$db_dir/${db_name}.sqlite"

        # Create database with Firefox's schema
        sqlite3 "$db_file" "
            CREATE TABLE IF NOT EXISTS \"Profiles\" (
                id      INTEGER NOT NULL,
                path    TEXT NOT NULL UNIQUE,
                name    TEXT NOT NULL,
                avatar  TEXT NOT NULL,
                themeId TEXT NOT NULL,
                themeFg TEXT NOT NULL,
                themeBg TEXT NOT NULL,
                PRIMARY KEY(id)
            );
            CREATE TABLE IF NOT EXISTS \"SharedPrefs\" (
                id        INTEGER NOT NULL,
                name      TEXT NOT NULL UNIQUE,
                value     BLOB,
                isBoolean INTEGER,
                PRIMARY KEY(id)
            );
        " 2>/dev/null

        if [[ -f "$db_file" ]]; then
            echo "$db_file"
            return 0
        fi
    fi

    return 1
}

# Find profile path by name from Profile Groups SQLite database (Firefox 128+)
# Returns the full path to the profile directory, or empty if not found
find_profile_by_name_sqlite() {
    local os="$1"
    local name="$2"
    local profiles_dir db_file

    profiles_dir=$(get_firefox_dir "$os")
    db_file=$(get_profile_groups_db "$os")

    if [[ -z "$db_file" ]]; then
        return
    fi

    if ! command -v sqlite3 &>/dev/null; then
        return
    fi

    # Query for matching profile name (case-insensitive)
    local path
    path=$(sqlite3 "$db_file" "SELECT path FROM Profiles WHERE LOWER(name) = LOWER('$name') LIMIT 1" 2>/dev/null)

    if [[ -n "$path" ]]; then
        echo "$profiles_dir/$path"
    fi
}

# List all profile names from Profile Groups SQLite database (Firefox 128+)
list_profile_names_sqlite() {
    local os="$1"
    local db_file

    db_file=$(get_profile_groups_db "$os")

    if [[ -z "$db_file" ]] || ! command -v sqlite3 &>/dev/null; then
        return
    fi

    sqlite3 "$db_file" "SELECT name FROM Profiles ORDER BY id" 2>/dev/null
}

# Find profile path by name (case-insensitive)
# Tries Profile Groups SQLite database first (Firefox 128+), then falls back to profiles.ini
# Returns the full path to the profile directory, or empty if not found
find_profile_by_name() {
    local os="$1"
    local name="$2"
    local result

    # Try Profile Groups SQLite database first (Firefox 128+)
    result=$(find_profile_by_name_sqlite "$os" "$name")
    if [[ -n "$result" ]]; then
        echo "$result"
        return
    fi

    # Fall back to profiles.ini
    local profiles_ini profiles_dir
    profiles_ini=$(get_profiles_ini "$os")
    profiles_dir=$(get_firefox_dir "$os")

    if [[ ! -f "$profiles_ini" ]]; then
        return
    fi

    # Parse profiles.ini to find profile with matching name (case-insensitive)
    local current_section="" current_name="" current_path="" is_relative=""
    local name_lower
    name_lower=$(to_lower "$name")

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Section header
        if [[ "$line" =~ ^\[.*\]$ ]]; then
            # Check if previous section matched (case-insensitive)
            if [[ "$(to_lower "$current_name")" == "$name_lower" && -n "$current_path" ]]; then
                if [[ "$is_relative" == "1" ]]; then
                    echo "$profiles_dir/$current_path"
                else
                    echo "$current_path"
                fi
                return
            fi
            current_section="$line"
            current_name=""
            current_path=""
            is_relative=""
        elif [[ "$line" =~ ^Name=(.*)$ ]]; then
            current_name="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^Path=(.*)$ ]]; then
            current_path="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^IsRelative=(.*)$ ]]; then
            is_relative="${BASH_REMATCH[1]}"
        fi
    done < "$profiles_ini"

    # Check last section (case-insensitive)
    if [[ "$(to_lower "$current_name")" == "$name_lower" && -n "$current_path" ]]; then
        if [[ "$is_relative" == "1" ]]; then
            echo "$profiles_dir/$current_path"
        else
            echo "$current_path"
        fi
    fi
}

# List all profile names
# Tries Profile Groups SQLite database first (Firefox 128+), then falls back to profiles.ini
list_profile_names() {
    local os="$1"
    local result

    # Try Profile Groups SQLite database first (Firefox 128+)
    result=$(list_profile_names_sqlite "$os")
    if [[ -n "$result" ]]; then
        echo "$result"
        return
    fi

    # Fall back to profiles.ini
    local profiles_ini
    profiles_ini=$(get_profiles_ini "$os")

    if [[ ! -f "$profiles_ini" ]]; then
        return
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^Name=(.*)$ ]]; then
            echo "${BASH_REMATCH[1]}"
        fi
    done < "$profiles_ini"
}

# Find default Firefox profile (fallback)
find_default_profile() {
    local os="$1"
    local profiles_dir

    profiles_dir=$(get_firefox_dir "$os")

    if [[ ! -d "$profiles_dir" ]]; then
        error "Firefox profiles directory not found: $profiles_dir"
    fi

    # Find default-release profile, or fall back to any .default profile
    local profile
    profile=$(find "$profiles_dir" -maxdepth 1 -type d -name "*.default-release" 2>/dev/null | head -1)
    if [[ -z "$profile" ]]; then
        profile=$(find "$profiles_dir" -maxdepth 1 -type d -name "*.default" 2>/dev/null | head -1)
    fi

    if [[ -z "$profile" ]]; then
        error "No Firefox profile found in $profiles_dir"
    fi

    echo "$profile"
}

# Generate a random 8-character alphanumeric string for profile directory names
random_hash() {
    LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8
}

# Create a profile in Firefox 128+ new profile system (Profile Groups SQLite database)
# Returns the full path to the created profile directory
# Creates the database if it doesn't exist (for fresh Firefox installs)
create_profile_new() {
    local os="$1"
    local name="$2"
    local profiles_dir db_file

    if ! command -v sqlite3 &>/dev/null; then
        return 1
    fi

    profiles_dir=$(get_firefox_dir "$os")
    # Create database if it doesn't exist
    db_file=$(get_profile_groups_db "$os" "true")

    if [[ -z "$db_file" ]]; then
        return 1
    fi

    # Check if profile already exists
    local existing
    existing=$(sqlite3 "$db_file" "SELECT path FROM Profiles WHERE LOWER(name) = LOWER('$name') LIMIT 1" 2>/dev/null)
    if [[ -n "$existing" ]]; then
        warn "Profile '$name' already exists"
        echo "$profiles_dir/$existing"
        return 0
    fi

    # Generate directory name
    local hash dir_name profile_path
    hash=$(random_hash)
    dir_name="${hash}.${name}"
    profile_path="$profiles_dir/$dir_name"

    # Create directory
    mkdir -p "$profile_path"

    # Pick avatar and theme colors per profile
    local avatar theme_id theme_fg theme_bg
    case "$(to_lower "$name")" in
        default|primary)
            avatar="default-favicon"
            theme_id="default-theme@mozilla.org"
            theme_fg="rgb(21,20,26)"
            theme_bg="rgb(240,240,244)"
            ;;
        relaxed)
            avatar="diamond"
            theme_id="default-theme@mozilla.org"
            theme_fg="rgb(0,119,0)"
            theme_bg="rgb(225,255,225)"
            ;;
        ephemeral)
            avatar="history"
            theme_id="default-theme@mozilla.org"
            theme_fg="rgb(0,83,203)"
            theme_bg="rgb(226,247,255)"
            ;;
        *)
            avatar="default-favicon"
            theme_id="default-theme@mozilla.org"
            theme_fg="rgb(21,20,26)"
            theme_bg="rgb(240,240,244)"
            ;;
    esac

    # Get next ID
    local next_id
    next_id=$(sqlite3 "$db_file" "SELECT COALESCE(MAX(id), 0) + 1 FROM Profiles" 2>/dev/null)

    # Insert into database
    if sqlite3 "$db_file" "INSERT INTO Profiles (id, path, name, avatar, themeId, themeFg, themeBg) VALUES ($next_id, '$dir_name', '$name', '$avatar', '$theme_id', '$theme_fg', '$theme_bg')" 2>/dev/null; then
        echo "$profile_path"
        return 0
    else
        warn "Failed to insert profile '$name' into database"
        rm -rf "$profile_path"
        return 1
    fi
}

# Create a profile in the Profile Groups database
# Requires Firefox 128+ with the new profile system and sqlite3
create_profile() {
    local os="$1"
    local name="$2"

    create_profile_new "$os" "$name"
}

# Get Firefox distribution directory
get_distribution_dir() {
    local os="$1"

    case "$os" in
        linux)
            if [[ -d "/usr/lib/firefox" ]]; then
                echo "/usr/lib/firefox/distribution"
            elif [[ -d "/usr/lib64/firefox" ]]; then
                echo "/usr/lib64/firefox/distribution"
            elif [[ -d "/snap/firefox/current/usr/lib/firefox" ]]; then
                error "Snap Firefox detected. Policies must be installed differently for Snap packages."
            elif [[ -d "$HOME/.var/app/org.mozilla.firefox" ]]; then
                echo "$HOME/.var/app/org.mozilla.firefox/current/active/files/lib/firefox/distribution"
            else
                error "Firefox installation not found"
            fi
            ;;
        macos)
            echo "/Applications/Firefox.app/Contents/Resources/distribution"
            ;;
    esac
}

# Download latest release
download_release() {
    local tmp_dir="$1"

    info "Fetching latest release info..."
    local release_url api_response
    api_response=$(curl --proto '=https' --tlsv1.2 -sf --max-time 10 "https://api.github.com/repos/${REPO}/releases/latest") || {
        error "Failed to fetch release info from GitHub API"
    }
    release_url=$(echo "$api_response" | grep "browser_download_url.*foxhole.zip" | cut -d '"' -f 4)

    if [[ -z "$release_url" ]]; then
        error "Could not find release download URL"
    fi

    info "Downloading $release_url..."
    if ! curl --proto '=https' --tlsv1.2 -fSL --max-time 60 "$release_url" -o "$tmp_dir/foxhole.zip"; then
        error "Failed to download release"
    fi

    # Verify download
    if [[ ! -f "$tmp_dir/foxhole.zip" ]]; then
        error "Download failed - file not found"
    fi
    local filesize
    filesize=$(stat -c%s "$tmp_dir/foxhole.zip" 2>/dev/null || stat -f%z "$tmp_dir/foxhole.zip" 2>/dev/null)
    info "Downloaded $filesize bytes"

    info "Extracting to $tmp_dir..."
    if ! unzip -qo "$tmp_dir/foxhole.zip" -d "$tmp_dir" </dev/null; then
        error "Failed to extract archive"
    fi
    info "Extraction complete"
}

# Select profile variant (interactive)
select_profile() {
    echo "" >/dev/tty
    echo "Available profiles:" >/dev/tty
    echo "  1) default   - Maximum privacy, may break some sites" >/dev/tty
    echo "  2) relaxed   - Balanced for banking/payment sites" >/dev/tty
    echo "  3) ephemeral - Session restore with data cleared on shutdown" >/dev/tty
    echo "" >/dev/tty
    echo -n "Select profile [1-3, default=1]: " >/dev/tty
    local choice
    prompt choice

    case "${choice:-1}" in
        1|default)   echo "default" ;;
        2|relaxed)   echo "relaxed" ;;
        3|ephemeral) echo "ephemeral" ;;
        *)           echo "default" ;;
    esac
}

# Install user.js to a profile
install_user_js() {
    local source_file="$1"
    local target_dir="$2"
    local profile_name="$3"

    if [[ -f "$target_dir/user.js" ]]; then
        local backup="$target_dir/user.js.backup.$(date +%Y%m%d_%H%M%S)"
        info "Backing up existing user.js in $profile_name to $backup"
        cp "$target_dir/user.js" "$backup"
    fi
    cp "$source_file" "$target_dir/user.js"
    info "Installed $profile_name user.js -> $target_dir"
}

# Install policies.json
install_policies() {
    local source_file="$1"
    local dist_dir="$2"

    local needs_sudo=false
    if [[ ! -w "$(dirname "$dist_dir")" ]]; then
        needs_sudo=true
    fi

    if $needs_sudo; then
        info "Installing policies.json (requires sudo)..."
        sudo mkdir -p "$dist_dir"
        sudo cp "$source_file" "$dist_dir/policies.json"
    else
        mkdir -p "$dist_dir"
        cp "$source_file" "$dist_dir/policies.json"
    fi
    info "Installed policies.json -> $dist_dir"
}

# Main installation
main() {
    local os
    os=$(detect_os)
    info "Detected OS: $os"

    # Check for local files first
    local source_dir=""

    if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/dist/default" ]]; then
        source_dir="$SCRIPT_DIR/dist"
        info "Using local dist/ directory"
    elif [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/default/user.js" ]]; then
        source_dir="$SCRIPT_DIR"
        info "Using local directory"
    else
        # Download from GitHub
        local tmp_dir
        tmp_dir=$(mktemp -d)
        trap "rm -rf '$tmp_dir'" EXIT

        download_release "$tmp_dir"
        source_dir="$tmp_dir"
    fi

    # sqlite3 is required for Firefox 128+ profile system
    if ! command -v sqlite3 &>/dev/null; then
        error "sqlite3 is required but not installed.
       Install it to enable profile management:
         Fedora/RHEL: sudo dnf install sqlite
         Ubuntu/Debian: sudo apt install sqlite3
         Arch: sudo pacman -S sqlite
         macOS: sqlite3 is included by default"
    fi

    # Check for named profiles (Default/Primary, Relaxed, Ephemeral)
    # "Primary" is Firefox's default name in the new profile system, treat as "Default"
    local default_profile relaxed_profile ephemeral_profile
    default_profile=$(find_profile_by_name "$os" "Default")
    if [[ -z "$default_profile" ]]; then
        default_profile=$(find_profile_by_name "$os" "Primary")
    fi
    relaxed_profile=$(find_profile_by_name "$os" "Relaxed")
    ephemeral_profile=$(find_profile_by_name "$os" "Ephemeral")

    local found_named_profiles=false
    local profiles_to_install=()

    if [[ -n "$default_profile" && -d "$default_profile" ]]; then
        profiles_to_install+=("default:$default_profile")
        found_named_profiles=true
    fi
    if [[ -n "$relaxed_profile" && -d "$relaxed_profile" ]]; then
        profiles_to_install+=("relaxed:$relaxed_profile")
        found_named_profiles=true
    fi
    if [[ -n "$ephemeral_profile" && -d "$ephemeral_profile" ]]; then
        profiles_to_install+=("ephemeral:$ephemeral_profile")
        found_named_profiles=true
    fi

    # Get distribution directory
    local dist_dir
    dist_dir=$(get_distribution_dir "$os")

    if $found_named_profiles; then
        # Auto-install to named profiles
        info "Found named Firefox profiles:"
        for entry in "${profiles_to_install[@]}"; do
            local profile_type="${entry%%:*}"
            local profile_path="${entry#*:}"
            info "  $profile_type -> $profile_path"
        done
        echo ""
        echo "This will install:"
        for entry in "${profiles_to_install[@]}"; do
            local profile_type="${entry%%:*}"
            local profile_path="${entry#*:}"
            echo "  $profile_type/user.js -> $profile_path/user.js"
        done
        echo "  policies.json -> $dist_dir/policies.json"
        echo ""
        echo -n "Continue? [y/N]: "
        local confirm
        prompt confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            info "Installation cancelled"
            exit 0
        fi

        # Install to each named profile
        for entry in "${profiles_to_install[@]}"; do
            local profile_type="${entry%%:*}"
            local profile_path="${entry#*:}"
            local user_js="$source_dir/$profile_type/user.js"

            if [[ ! -f "$user_js" ]]; then
                warn "user.js not found for $profile_type, skipping"
                continue
            fi
            install_user_js "$user_js" "$profile_path" "$profile_type"
        done
    else
        # No named profiles found - show existing and offer options
        info "No named profiles (Default/Primary, Relaxed, Ephemeral) found"

        # Show existing profiles
        local existing_profiles
        existing_profiles=$(list_profile_names "$os")
        if [[ -n "$existing_profiles" ]]; then
            echo "" >/dev/tty
            echo "Existing Firefox profiles:" >/dev/tty
            while IFS= read -r pname; do
                echo "  - $pname" >/dev/tty
            done <<< "$existing_profiles"
            echo "" >/dev/tty
            echo "Tip: Name profiles 'Default' (or 'Primary'), 'Relaxed', 'Ephemeral'" >/dev/tty
            echo "     for automatic detection on future runs." >/dev/tty
        fi

        echo "" >/dev/tty
        echo "Options:" >/dev/tty
        echo "  1) Create all three profiles (Default, Relaxed, Ephemeral)" >/dev/tty
        echo "  2) Install to existing default profile" >/dev/tty
        echo "" >/dev/tty
        echo -n "Select option [1-2, default=2]: " >/dev/tty
        local option
        prompt option

        if [[ "${option:-2}" == "1" ]]; then
            # Create profiles
            info "Creating Firefox profiles..."
            warn "Firefox must be closed for profile creation."

            profiles_to_install=()
            for profile_name in Default Relaxed Ephemeral; do
                local profile_path
                profile_path=$(create_profile "$os" "$profile_name")
                if [[ -n "$profile_path" ]]; then
                    local profile_type
                    profile_type=$(to_lower "$profile_name")
                    profiles_to_install+=("$profile_type:$profile_path")
                    info "Created profile: $profile_name -> $profile_path"
                else
                    warn "Failed to create profile: $profile_name"
                fi
            done

            if [[ ${#profiles_to_install[@]} -eq 0 ]]; then
                error "Failed to create profiles. Is Firefox closed?"
            fi

            echo ""
            echo "This will install:"
            for entry in "${profiles_to_install[@]}"; do
                local profile_type="${entry%%:*}"
                local profile_path="${entry#*:}"
                echo "  $profile_type/user.js -> $profile_path/user.js"
            done
            echo "  policies.json -> $dist_dir/policies.json"
            echo ""
            echo -n "Continue? [y/N]: "
            local confirm
            prompt confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                info "Installation cancelled"
                exit 0
            fi

            # Install to each profile
            for entry in "${profiles_to_install[@]}"; do
                local profile_type="${entry%%:*}"
                local profile_path="${entry#*:}"
                local user_js="$source_dir/$profile_type/user.js"

                if [[ ! -f "$user_js" ]]; then
                    warn "user.js not found for $profile_type, skipping"
                    continue
                fi
                install_user_js "$user_js" "$profile_path" "$profile_type"
            done
        else
            # Single profile selection
            local profile_choice
            profile_choice=$(select_profile)
            info "Selected profile: $profile_choice"

            local user_js="$source_dir/$profile_choice/user.js"

            if [[ ! -f "$user_js" ]]; then
                error "user.js not found: $user_js"
            fi

            # Find Firefox profile
            local firefox_profile
            firefox_profile=$(find_default_profile "$os")
            info "Firefox profile: $firefox_profile"

            echo ""
            echo "This will install:"
            echo "  user.js       -> $firefox_profile/user.js"
            echo "  policies.json -> $dist_dir/policies.json"
            echo ""
            echo -n "Continue? [y/N]: "
            local confirm
            prompt confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                info "Installation cancelled"
                exit 0
            fi

            install_user_js "$user_js" "$firefox_profile" "$profile_choice"
        fi
    fi

    # Install policies.json (same for all profiles)
    local policies_json="$source_dir/default/policies.json"
    if [[ ! -f "$policies_json" ]]; then
        error "policies.json not found: $policies_json"
    fi
    install_policies "$policies_json" "$dist_dir"

    echo ""
    info "Installation complete!"
    info "Restart Firefox and visit about:policies to verify"
}

main "$@"
