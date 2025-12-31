#!/usr/bin/env bash
# Foxhole - Build privacy-hardened Firefox profiles from Arkenfox user.js
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/dist"
ARKENFOX_VERSION="${1:-}"

cleanup() {
    rm -rf "${BUILD_DIR}" "${SCRIPT_DIR}/arkenfox"
}

build_profile() {
    local name="$1"
    local overrides_file="$2"
    local profile_dir="${BUILD_DIR}/${name}"

    echo "Building ${name} profile..."
    mkdir -p "${profile_dir}"
    cp "${SCRIPT_DIR}/arkenfox/user.js" "${profile_dir}/"
    cp "${SCRIPT_DIR}/arkenfox/updater.sh" "${profile_dir}/"
    cp "${SCRIPT_DIR}/policies.json" "${profile_dir}/"
    cp "${overrides_file}" "${profile_dir}/user-overrides.js"

    cd "${profile_dir}"
    chmod +x updater.sh
    ./updater.sh -s -u

    rm -f updater.sh user-overrides.js
    echo "${name} profile built: ${profile_dir}/user.js"
}

# Build a profile on top of another profile
build_derived_profile() {
    local name="$1"
    local base_profile="$2"
    local overrides_file="$3"
    local profile_dir="${BUILD_DIR}/${name}"

    echo "Building ${name} profile (based on ${base_profile})..."
    mkdir -p "${profile_dir}"
    cp "${BUILD_DIR}/${base_profile}/user.js" "${profile_dir}/"
    cp "${BUILD_DIR}/${base_profile}/policies.json" "${profile_dir}/"

    # Append overrides to the base profile
    echo "" >> "${profile_dir}/user.js"
    echo "/* ${name} overrides */" >> "${profile_dir}/user.js"
    cat "${overrides_file}" >> "${profile_dir}/user.js"

    echo "${name} profile built: ${profile_dir}/user.js"
}

main() {
    echo "=== Foxhole Build ==="

    cleanup

    if [[ -z "$ARKENFOX_VERSION" ]]; then
        echo "Fetching latest arkenfox version..."
        # Use sed for portability (grep -P is GNU-only, fails on macOS/BSD)
        ARKENFOX_VERSION=$(curl -s https://api.github.com/repos/arkenfox/user.js/releases/latest | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p')
    fi
    echo "Using arkenfox version: $ARKENFOX_VERSION"

    echo "Cloning arkenfox..."
    git clone --depth 1 --branch "$ARKENFOX_VERSION" \
        https://github.com/arkenfox/user.js.git "${SCRIPT_DIR}/arkenfox"

    build_profile "default" "${SCRIPT_DIR}/user-overrides.js"
    build_profile "relaxed" "${SCRIPT_DIR}/user-overrides-relaxed.js"
    build_derived_profile "ephemeral" "default" "${SCRIPT_DIR}/user-overrides-ephemeral.js"

    cat > "${BUILD_DIR}/version.txt" << EOF
Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Arkenfox Version: $ARKENFOX_VERSION
EOF

    rm -rf "${SCRIPT_DIR}/arkenfox"

    echo ""
    echo "=== Build complete ==="
    echo "Output:"
    echo "  ${BUILD_DIR}/default/user.js"
    echo "  ${BUILD_DIR}/relaxed/user.js"
    echo "  ${BUILD_DIR}/ephemeral/user.js"
    echo "  ${BUILD_DIR}/version.txt"
}

main "$@"
