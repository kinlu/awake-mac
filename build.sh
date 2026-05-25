#!/bin/bash
set -euo pipefail

APP_NAME="Awake"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

echo "Cleaning..."
rm -rf "${BUILD_DIR}"

echo "Creating app bundle structure..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

echo "Compiling..."
swiftc \
    -o "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" \
    -framework SwiftUI \
    -framework IOKit \
    -framework ServiceManagement \
    -target arm64-apple-macos13.0 \
    -swift-version 5 \
    -Osize \
    Awake/*.swift

echo "Copying Info.plist..."
cp Awake/Info.plist "${APP_BUNDLE}/Contents/"

echo "Generating icon..."
if [ ! -f Awake/AppIcon.icns ] || [ Awake/AppIcon.svg -nt Awake/AppIcon.icns ]; then
    ICON_TOOL="${BUILD_DIR}/svg2iconset"
    swiftc -framework AppKit -o "${ICON_TOOL}" scripts/svg2iconset.swift
    "${ICON_TOOL}"
    iconutil -c icns Awake/AppIcon.iconset -o Awake/AppIcon.icns
    rm -rf Awake/AppIcon.iconset
fi
cp Awake/AppIcon.icns "${APP_BUNDLE}/Contents/Resources/"

echo "Build complete: ${APP_BUNDLE}"
echo ""
echo "To run:  open ${APP_BUNDLE}"
echo "To install: cp -r ${APP_BUNDLE} /Applications/"
