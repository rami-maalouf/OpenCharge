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
