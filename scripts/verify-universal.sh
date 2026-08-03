#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")/.."

build_settings="$(xcodebuild \
    -project OpenCharge.xcodeproj \
    -scheme OpenCharge \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -showBuildSettings)"

build_setting() {
    local key="$1"

    awk -F ' = ' -v requested_key="$key" '$1 ~ "^[[:space:]]*" requested_key "$" { print $2; exit }' <<< "$build_settings"
}

target_build_dir="$(build_setting TARGET_BUILD_DIR)"
full_product_name="$(build_setting FULL_PRODUCT_NAME)"
executable_name="$(build_setting EXECUTABLE_NAME)"

if [[ -z "$target_build_dir" || -z "$full_product_name" || -z "$executable_name" ]]; then
    printf 'unable to resolve release build product settings\n' >&2
    exit 1
fi

app_path="$target_build_dir/$full_product_name"
app_executable="$app_path/Contents/MacOS/$executable_name"
finder_executable="$app_path/Contents/PlugIns/OpenChargeFinder.appex/Contents/MacOS/OpenChargeFinder"

verify_executable() {
    local executable_path="$1"

    if [[ ! -f "$executable_path" ]]; then
        printf 'missing release executable: %s\n' "$executable_path" >&2
        exit 1
    fi

    local architectures
    architectures="$(lipo -archs "$executable_path")"

    if [[ " $architectures " != *" arm64 "* || " $architectures " != *" x86_64 "* ]]; then
        printf 'expected arm64 and x86_64 in %s, found: %s\n' "$executable_path" "$architectures" >&2
        exit 1
    fi

    printf 'verified universal executable: %s (%s)\n' "$executable_path" "$architectures"
}

verify_executable "$app_executable"
verify_executable "$finder_executable"
