#!/bin/bash
# build-ios.sh
# Builds the kuCar iOS app from the command line.
# Usage: ./ci-support/build-ios.sh [debug|release|archive]

set -e

CONFIGURATION="${1:-debug}"
SCHEME="kuCar"
PROJECT="kuCar.xcodeproj"
ARCHIVE_PATH="./build/kuCar.xcarchive"
EXPORT_OPTIONS="./ci-support/ExportOptions.plist"

echo "========================================="
echo " kuCar - iOS Build Script"
echo " Configuration: $CONFIGURATION"
echo "========================================="

case "$CONFIGURATION" in
    debug)
        echo "🔨 Building for Debug (Simulator)..."
        xcodebuild build \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration Debug \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
            -sdk iphonesimulator \
            CODE_SIGN_STYLE=Automatic \
            | xcpretty
        ;;

    release)
        echo "🔨 Building for Release (Device)..."
        xcodebuild build \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration Release \
            -destination 'generic/platform=iOS' \
            -sdk iphoneos \
            CODE_SIGN_STYLE=Manual \
            | xcpretty
        ;;

    archive)
        echo "📦 Archiving for App Store..."

        # Clean
        xcodebuild clean \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration Release

        # Archive
        xcodebuild archive \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration Release \
            -archivePath "$ARCHIVE_PATH" \
            -destination 'generic/platform=iOS' \
            CODE_SIGN_STYLE=Manual \
            | xcpretty

        echo "✅ Archive created at: $ARCHIVE_PATH"

        # Export IPA (requires valid signing)
        if [ -f "$EXPORT_OPTIONS" ]; then
            echo "📱 Exporting IPA..."
            xcodebuild -exportArchive \
                -archivePath "$ARCHIVE_PATH" \
                -exportPath "./build/" \
                -exportOptionsPlist "$EXPORT_OPTIONS" \
                -allowProvisioningUpdates \
                | xcpretty
            echo "✅ IPA exported to: ./build/"
        fi
        ;;

    *)
        echo "Usage: $0 [debug|release|archive]"
        exit 1
        ;;
esac

echo "========================================="
echo " Build completed successfully!"
echo "========================================="
