#!/usr/bin/env bash
# Builds a release APK you can install on any Android phone.
# Requires Flutter 3.29+ (https://docs.flutter.dev/get-started/install) and
# the Android SDK (Android Studio installs it).
set -euo pipefail
cd "$(dirname "$0")"

# Generates the Gradle wrapper/build files that match YOUR Flutter version.
# Existing files (icons, manifest, splash, lib/) are never overwritten.
flutter create --platforms=android --org com.atharva --project-name eon_fitness .

flutter pub get
flutter build apk --release

APK=build/app/outputs/flutter-apk/app-release.apk
cp "$APK" ./EonFitness.apk
echo
echo "Done: $(pwd)/EonFitness.apk"
echo "Install on a USB-connected phone with:  flutter install   (or adb install -r EonFitness.apk)"
