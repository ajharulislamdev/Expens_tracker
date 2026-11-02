#!/usr/bin/env bash
# Generates the android/ios/web platform folders around the existing lib/ and pubspec.yaml.
set -e
flutter create --project-name expense_tracker --org com.example --platforms=android,ios .
flutter pub get
echo
echo "Now add the permissions from docs/AndroidManifest_snippet.xml to"
echo "android/app/src/main/AndroidManifest.xml, then run:  flutter run"
