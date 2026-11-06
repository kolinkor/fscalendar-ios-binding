#!/bin/bash
set -e

# Builds FSCalendar.xcframework (device arm64 + simulator arm64/x86_64) from the FSCalendar sources
# checked out next to this repository (git clone --branch 2.8.4 https://github.com/WenchaoD/FSCalendar.git).
# A fat .framework cannot carry the arm64 simulator slice next to the arm64 device one, hence the xcframework.

PROJECT_PATH="../../FSCalendar/FSCalendarExamples.xcworkspace"
SCHEME="FSCalendar"
ARCHIVES="build/archives"
SETTINGS="SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES IPHONEOS_DEPLOYMENT_TARGET=12.0"

rm -Rf "build" "FSCalendar.framework" "FSCalendar.xcframework"

echo "Archive the device framework"
xcodebuild archive -workspace $PROJECT_PATH -scheme $SCHEME -configuration Release \
    -destination "generic/platform=iOS" -archivePath "$ARCHIVES/ios" $SETTINGS > /dev/null

echo "Archive the simulator framework"
xcodebuild archive -workspace $PROJECT_PATH -scheme $SCHEME -configuration Release \
    -destination "generic/platform=iOS Simulator" -archivePath "$ARCHIVES/ios-simulator" $SETTINGS > /dev/null

echo "Create the xcframework"
xcodebuild -create-xcframework \
    -framework "$ARCHIVES/ios.xcarchive/Products/Library/Frameworks/FSCalendar.framework" \
    -framework "$ARCHIVES/ios-simulator.xcarchive/Products/Library/Frameworks/FSCalendar.framework" \
    -output "FSCalendar.xcframework"

rm -Rf "build"

echo "Verify results"
for slice in FSCalendar.xcframework/ios-*; do
    echo "$(basename "$slice"): $(lipo -archs "$slice/FSCalendar.framework/FSCalendar")"
done

# Regenerate the API definitions only when the headers change (then diff against ApiDefinitions.cs):
# sharpie bind --sdk=iphoneos --namespace=FSCalendar -scope FSCalendar.xcframework/ios-arm64/FSCalendar.framework/Headers/ FSCalendar.xcframework/ios-arm64/FSCalendar.framework/Headers/*.h
