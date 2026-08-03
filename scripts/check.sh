#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")/.."

swiftformat --lint .

swift test --package-path Packages/OpenChargeKit

xcodebuild \
    -project OpenCharge.xcodeproj \
    -scheme OpenCharge \
    -configuration Debug \
    -destination 'platform=macOS' \
    build

xcodebuild \
    -project OpenCharge.xcodeproj \
    -scheme OpenCharge \
    -configuration Debug \
    -destination 'platform=macOS' \
    test

if [[ "${OPENCHARGE_VERIFY_RELEASE:-0}" == "1" ]]; then
    xcodebuild \
        -project OpenCharge.xcodeproj \
        -scheme OpenCharge \
        -configuration Release \
        -destination 'generic/platform=macOS' \
        build

    ./scripts/verify-universal.sh
fi
