#!/bin/bash
# Build a release binary and sign it with hardened runtime.
# Override the signing identity with SIGN_IDENTITY="..." ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

IDENTITY="${SIGN_IDENTITY:-Developer ID Application}"
BUNDLE_ID="com.earchibald.keyboard-cleaner"

swift build -c release --disable-sandbox
mkdir -p bin
cp "$(swift build -c release --show-bin-path)/keyboard-cleaner" bin/keyboard-cleaner

codesign --force --options runtime --timestamp \
    --identifier "$BUNDLE_ID" \
    --sign "$IDENTITY" \
    bin/keyboard-cleaner

codesign --verify --strict --verbose=2 bin/keyboard-cleaner
echo "Built and signed: bin/keyboard-cleaner"
