#!/bin/bash
# setup-project.sh
# Runs on the CI Mac machine to generate the Xcode project from project.yml.
# Requires: XcodeGen, Xcode 15.4+

set -e

echo "========================================="
echo " kuCar - CI Project Setup"
echo "========================================="

# Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo "Installing XcodeGen via Homebrew..."
    brew install xcodegen
fi

echo "Generating Xcode project from project.yml..."
xcodegen generate --spec project.yml --use-cache

# Verify the project was created
if [ -d "kuCar.xcodeproj" ]; then
    echo "✅ Xcode project generated successfully"
else
    echo "❌ Failed to generate Xcode project"
    exit 1
fi

# Download DeepLabV3 model if not present
DEEPLAB_PATH="kuCar/Resources/CoreMLModels/DeepLabV3.mlpackage"
if [ ! -d "$DEEPLAB_PATH" ]; then
    echo "⚠️  DeepLabV3.mlpackage not found."
    echo "   Download from: https://developer.apple.com/machine-learning/models/"
    echo "   Place in: $DEEPLAB_PATH"
    echo "   Using stub — build will succeed but segmentation will fail at runtime."
fi

echo "========================================="
echo " Project setup complete. Ready to build!"
echo "========================================="
