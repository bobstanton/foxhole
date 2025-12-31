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

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Install Foxhole privacy-hardened Firefox configuration.

Options:
  --reset     Reset Firefox to fresh state (deletes all profiles and settings)
  --help      Show this help message

Examples:
  $(basename "$0")           # Install Foxhole to Firefox profiles
  $(basename "$0") --reset   # Reset Firefox, then install Foxhole
EOF
    exit 0
}

# Reset Firefox to fresh state
reset_firefox() {
    local os="$1"
    local firefox_dir cache_dir

    firefox_dir=$(get_firefox_dir "$os")
    case "$os" in
        linux)  cache_dir="$HOME/.cache/mozilla" ;;
        macos)  cache_dir="$HOME/Library/Caches/Firefox" ;;
    esac

    echo ""
    warn "This will DELETE all Firefox data including:"
    warn "  - All profiles and their data"
    warn "  - Bookmarks, history, passwords"
    warn "  - Extensions and settings"
    warn "  - Cache"
    echo ""
    warn "Firefox directory: $firefox_dir"
    warn "Cache directory: $cache_dir"
    echo ""
    echo -n "Are you sure you want to reset Firefox? Type 'yes' to confirm: "
    local confirm
    prompt confirm
    if [[ "$confirm" != "yes" ]]; then
        info "Reset cancelled"
        exit 0
    fi

    # Check if Firefox is running
    if pgrep -x "firefox" > /dev/null 2>&1 || pgrep -x "firefox-bin" > /dev/null 2>&1; then
        error "Firefox is running. Please close Firefox before resetting."
    fi

    info "Resetting Firefox..."

    if [[ -d "$firefox_dir" ]]; then
        rm -rf "$firefox_dir"
        info "Deleted $firefox_dir"
    fi

    if [[ -d "$cache_dir" ]]; then
        rm -rf "$cache_dir"
        info "Deleted $cache_dir"
    fi

    info "Firefox reset complete"
    echo ""
}

# Portable lowercase conversion (macOS has Bash 3.2 which lacks ${var,,})
to_lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }

# Calculate the Firefox Install hash using CityHash64
# This matches what Firefox computes from the install path
# Uses Perl for portability (available by default on Linux and macOS)
calculate_install_hash() {
    local install_path="$1"

    perl -e '
use strict;
use warnings;
no warnings "portable";
my ($k0,$k1,$k2)=(0xc3a5c85c97cb3127,0xb492b66fbe98f273,0x9ae16a3b2f90404f);
sub add64{my($a,$b)=@_;my $lo=($a&0xFFFFFFFF)+($b&0xFFFFFFFF);my $hi=(($a>>32)&0xFFFFFFFF)+(($b>>32)&0xFFFFFFFF)+($lo>>32);($lo&0xFFFFFFFF)|(($hi&0xFFFFFFFF)<<32)}
sub sub64{my($a,$b)=@_;add64($a,add64(~$b&0xFFFFFFFFFFFFFFFF,1))}
sub mul64{my($a,$b)=@_;my@a=($a&0xFFFF,($a>>16)&0xFFFF,($a>>32)&0xFFFF,($a>>48)&0xFFFF);my@b=($b&0xFFFF,($b>>16)&0xFFFF,($b>>32)&0xFFFF,($b>>48)&0xFFFF);my($r0,$r1,$r2,$r3)=($a[0]*$b[0],$a[0]*$b[1]+$a[1]*$b[0],$a[0]*$b[2]+$a[1]*$b[1]+$a[2]*$b[0],$a[0]*$b[3]+$a[1]*$b[2]+$a[2]*$b[1]+$a[3]*$b[0]);my$c;$c=int($r0/0x10000);$r0&=0xFFFF;$r1+=$c;$c=int($r1/0x10000);$r1&=0xFFFF;$r2+=$c;$c=int($r2/0x10000);$r2&=0xFFFF;$r3+=$c;$r3&=0xFFFF;$r0|($r1<<16)|($r2<<32)|($r3<<48)}
sub rot{my($v,$s)=@_;$s?((($v>>$s)|(($v<<(64-$s))&0xFFFFFFFFFFFFFFFF))&0xFFFFFFFFFFFFFFFF):$v}
sub mix{$_[0]^($_[0]>>47)}
sub ld64{my($b,$o)=@_;$o//=0;my@c=unpack("C8",substr($b,$o,8));$c[0]|($c[1]<<8)|($c[2]<<16)|($c[3]<<24)|($c[4]<<32)|($c[5]<<40)|($c[6]<<48)|($c[7]<<56)}
sub ld32{my($b,$o)=@_;$o//=0;my@c=unpack("C4",substr($b,$o,4));$c[0]|($c[1]<<8)|($c[2]<<16)|($c[3]<<24)}
sub h128{my($l,$h)=@_;my$m=0x9ddfea08eb382d69;my$a=mul64($l^$h,$m);$a^=($a>>47);my$b=mul64($h^$a,$m);$b^=($b>>47);mul64($b,$m)}
sub h16{h128($_[0],$_[1])}
sub h16m{my($u,$v,$m)=@_;my$a=mul64($u^$v,$m);$a^=($a>>47);my$b=mul64($v^$a,$m);$b^=($b>>47);mul64($b,$m)}
sub h0t16{my($s,$n)=@_;return h16(ld64($s,0),rot(add64(ld64($s,$n-8),$n),$n))^ld64($s,$n-8)if$n>8;return h16(add64($n,ld32($s,0)<<3),ld32($s,$n-4))if$n>=4;if($n>0){my@b=unpack("C*",substr($s,0,$n));my($y,$z)=($b[0]+($b[$n>>1]<<8),$n+($b[$n-1]<<2));return mul64(mix(mul64($y,$k2)^mul64($z,0xc949d7c7509e6557)),$k2)}$k2}
sub h17t32{my($s,$n)=@_;my($a,$b,$c,$d)=(mul64(ld64($s,0),$k1),ld64($s,8),mul64(ld64($s,$n-8),$k2),mul64(ld64($s,$n-16),$k0));h16(add64(add64(rot(sub64($a,$b),43),rot($c,30)),$d),add64(sub64(add64($a,rot($b^0xc949d7c7509e6557,20)),$c),$n))}
sub h33t64{my($s,$n)=@_;my$z=ld64($s,24);my$a=add64(ld64($s,0),mul64(add64($n,ld64($s,$n-16)),$k0));my$b=rot(add64($a,$z),52);my$c=rot($a,37);$a=add64($a,ld64($s,8));$c=add64($c,rot($a,7));$a=add64($a,ld64($s,16));my($vf,$vs)=(add64($a,$z),add64(add64($b,rot($a,31)),$c));$a=add64(ld64($s,16),ld64($s,$n-32));$z=ld64($s,$n-8);$b=rot(add64($a,$z),52);$c=rot($a,37);$a=add64($a,ld64($s,$n-24));$c=add64($c,rot($a,7));$a=add64($a,ld64($s,$n-16));my($wf,$ws)=(add64($a,$z),add64(add64($b,rot($a,31)),$c));my$r=mix(add64(mul64(add64($vf,$ws),$k2),mul64(add64($wf,$vs),$k0)));mul64(mix(add64(mul64($r,$k0),$vs)),$k2)}
sub wh32{my($s,$o,$a,$b)=@_;my($w,$x,$y,$z)=(ld64($s,$o),ld64($s,$o+8),ld64($s,$o+16),ld64($s,$o+24));$a=add64($a,$w);$b=rot(add64(add64($b,$a),$z),21);my$c=$a;$a=add64(add64($a,$x),$y);$b=add64($b,rot($a,44));(add64($a,$z),add64($b,$c))}
sub city64{my$s=shift;my$n=length($s);return h0t16($s,$n)if$n<=16;return h17t32($s,$n)if$n<=32;return h33t64($s,$n)if$n<=64;my$x=ld64($s,$n-40);my$y=add64(ld64($s,$n-16),ld64($s,$n-56));my$z=h16(add64(ld64($s,$n-48),$n),ld64($s,$n-24));my@v=wh32($s,$n-64,$n,$z);my@w=wh32($s,$n-32,add64($y,$k1),$x);$x=add64(mul64($x,$k1),ld64($s,0));my$o=0;while($o+64<=$n){$x=mul64(rot(add64(add64($x,$y),$v[0]),37),$k1);$y=mul64(rot(add64($v[1],$w[1]),42),$k1);$x^=$w[1];$y=add64($y,add64($v[0],ld64($s,$o+40)));$z=mul64(rot(add64($z,$w[0]),33),$k1);@v=wh32($s,$o,mul64($v[1],$k1),add64($x,$w[0]));@w=wh32($s,$o+32,add64($z,$w[1]),add64($y,ld64($s,$o+16)));($z,$x)=($x,$z);$o+=64}h16m(add64(h16($v[0],$w[0]),add64(mul64(mix($y),$k1),$z)),add64(h16($v[1],$w[1]),$x),add64($k1,($n&0xFF)<<1))}
my$p=$ARGV[0];my$u="";$u.=chr(ord($_)&0xFF).chr(0)for split//,$p;printf"%016X\n",city64($u);
' "$install_path"
}

# Get Firefox installation path (where firefox binary lives)
get_firefox_install_path() {
    local os="$1"
    case "$os" in
        linux)
            if [[ -d "/usr/lib64/firefox" ]]; then
                echo "/usr/lib64/firefox"
            elif [[ -d "/usr/lib/firefox" ]]; then
                echo "/usr/lib/firefox"
            fi
            ;;
        macos)
            echo "/Applications/Firefox.app/Contents/MacOS"
            ;;
    esac
}

# Get or compute Install section ID
# First checks if Firefox has already created one, otherwise computes it
get_install_id() {
    local os="$1"
    local firefox_dir
    firefox_dir=$(get_firefox_dir "$os")
    local installs_ini="$firefox_dir/installs.ini"

    # Check if Firefox has already created an Install section
    if [[ -f "$installs_ini" ]]; then
        local existing_id
        existing_id=$(grep '^\[[A-F0-9]\{16\}\]' "$installs_ini" 2>/dev/null | head -1 | sed 's/^\[//;s/\]$//')
        if [[ -n "$existing_id" ]]; then
            echo "$existing_id"
            return 0
        fi
    fi

    # Compute the Install ID from Firefox install path using CityHash64
    local install_path
    install_path=$(get_firefox_install_path "$os")
    if [[ -n "$install_path" ]]; then
        calculate_install_hash "$install_path"
        return 0
    fi

    error "Could not determine Firefox install path"
}

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

# Get Profile Groups database path (Firefox 128+ new profile system)
# If create=true and database doesn't exist, creates the directory structure and database
# Prefers the database referenced in profiles.ini if multiple exist
get_profile_groups_db() {
    local os="$1"
    local create="${2:-false}"
    local firefox_dir
    firefox_dir=$(get_firefox_dir "$os")

    local db_dir="$firefox_dir/Profile Groups"
    local profiles_ini="$firefox_dir/profiles.ini"

    # If profiles.ini exists, try to find the database it references via StoreID
    if [[ -f "$profiles_ini" ]]; then
        local store_id
        store_id=$(grep -m1 "^StoreID=" "$profiles_ini" 2>/dev/null | cut -d= -f2)
        if [[ -n "$store_id" && -f "$db_dir/${store_id}.sqlite" ]]; then
            echo "$db_dir/${store_id}.sqlite"
            return 0
        fi
    fi

    # Check for any existing database
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
        mkdir -p "$firefox_dir" || { warn "Failed to create $firefox_dir"; return 1; }
        mkdir -p "$db_dir" || { warn "Failed to create $db_dir"; return 1; }

        # Generate random 8-char hex filename like Firefox does
        local db_name
        db_name=$(LC_ALL=C tr -dc 'a-f0-9' < /dev/urandom | head -c 8)
        local db_file="$db_dir/${db_name}.sqlite"

        # Create database with Firefox's schema
        if ! sqlite3 "$db_file" "
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
        "; then
            warn "Failed to create database schema"
            return 1
        fi

        if [[ -f "$db_file" ]]; then
            # Create profiles.ini to link Firefox to our database
            if [[ ! -f "$profiles_ini" ]]; then
                cat > "$profiles_ini" << EOF
[General]
StartWithLastProfile=1
Version=2

EOF
            fi
            echo "$db_file"
            return 0
        fi
    fi

    return 1
}

# Find profile path by name (case-insensitive) from Profile Groups SQLite database
# Returns the full path to the profile directory, or empty if not found
find_profile_by_name() {
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

# List all profile names from Profile Groups SQLite database
list_profile_names() {
    local os="$1"
    local db_file

    db_file=$(get_profile_groups_db "$os")

    if [[ -z "$db_file" ]] || ! command -v sqlite3 &>/dev/null; then
        return
    fi

    sqlite3 "$db_file" "SELECT name FROM Profiles ORDER BY id" 2>/dev/null
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

# Create a profile in Firefox 128+ Profile Groups SQLite database
# Returns the full path to the created profile directory
# Creates the database if it doesn't exist (for fresh Firefox installs)
create_profile() {
    local os="$1"
    local name="$2"
    local profiles_dir db_file

    if ! command -v sqlite3 &>/dev/null; then
        return 1
    fi

    profiles_dir=$(get_firefox_dir "$os")
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

    mkdir -p "$profile_path"

    # Profile appearance settings
    # Note: These colors appear on the profile avatar/icon in the profile selector.
    # Full browser chrome theming requires Firefox's signed theme extensions.
    local avatar theme_id theme_fg theme_bg
    theme_id="default-theme@mozilla.org"
    case "$(to_lower "$name")" in
        default|primary)
            avatar="default-favicon"
            theme_fg="rgb(21,20,26)"
            theme_bg="rgb(240,240,244)"
            ;;
        relaxed)
            avatar="diamond"
            theme_fg="rgb(0,119,0)"
            theme_bg="rgb(225,255,225)"
            ;;
        ephemeral)
            avatar="history"
            theme_fg="rgb(0,83,203)"
            theme_bg="rgb(226,247,255)"
            ;;
        *)
            avatar="default-favicon"
            theme_fg="rgb(21,20,26)"
            theme_bg="rgb(240,240,244)"
            ;;
    esac

    # Get next ID
    local next_id
    next_id=$(sqlite3 "$db_file" "SELECT COALESCE(MAX(id), 0) + 1 FROM Profiles")
    if [[ -z "$next_id" ]]; then
        next_id=1
    fi

    # Insert into database
    if ! sqlite3 "$db_file" "INSERT INTO Profiles (id, path, name, avatar, themeId, themeFg, themeBg) VALUES ($next_id, '$dir_name', '$name', '$avatar', '$theme_id', '$theme_fg', '$theme_bg')" 2>&1; then
        warn "Failed to insert profile '$name' into database"
        rm -rf "$profile_path"
        return 1
    fi

    # Add entry to profiles.ini so Firefox knows about our database
    local profiles_ini="$profiles_dir/profiles.ini"
    local db_name
    db_name=$(basename "$db_file" .sqlite)

    # Count existing profile sections to get next index
    local profile_index=0
    if [[ -f "$profiles_ini" ]]; then
        profile_index=$(grep -c '^\[Profile' "$profiles_ini" 2>/dev/null) || profile_index=0
    fi

    # For the first profile, set up Install section
    if [[ "$profile_index" -eq 0 ]]; then
        local install_id
        install_id=$(get_install_id "$os")
        if [[ -n "$install_id" ]]; then
            cat > "$profiles_dir/installs.ini" << EOF
[$install_id]
Default=$dir_name
Locked=1
EOF
            cat >> "$profiles_ini" << EOF
[Install${install_id}]
Default=$dir_name
Locked=1

EOF
            info "Install ID: $install_id" >&2
        fi
    fi

    # Append profile entry
    cat >> "$profiles_ini" << EOF
[Profile${profile_index}]
Name=$name
IsRelative=1
Path=$dir_name
StoreID=$db_name
ShowSelector=1
$([[ "$profile_index" -eq 0 ]] && echo "Default=1")

EOF
    echo "$profile_path"
    return 0
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
    local do_reset=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --reset)
                do_reset=true
                shift
                ;;
            --help|-h)
                usage
                ;;
            *)
                error "Unknown option: $1. Use --help for usage."
                ;;
        esac
    done

    local os
    os=$(detect_os)
    info "Detected OS: $os"

    # Handle reset if requested
    if $do_reset; then
        reset_firefox "$os"
    fi

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
}

main "$@"
