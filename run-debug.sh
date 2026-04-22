#!/usr/bin/env bash
# Build & install debug APK on connected Android device, passing the Gemini API key from
# android/gemini.properties (git-ignored). Run from repo root: ./run-debug.sh

set -e

PROPS="android/gemini.properties"
if [ ! -f "$PROPS" ]; then
  echo "Missing $PROPS. Create it with: GEMINI_API_KEY=AIza..."
  exit 1
fi

GEMINI_KEY="$(grep '^GEMINI_API_KEY=' "$PROPS" | cut -d'=' -f2- | tr -d '[:space:]')"
if [ -z "$GEMINI_KEY" ]; then
  echo "GEMINI_API_KEY not set in $PROPS"
  exit 1
fi

ADB="/c/Users/UTENTE/AppData/Local/Android/Sdk/platform-tools/adb.exe"
DEVICE="$(${ADB} devices | awk 'NR==2 {print $1}')"
if [ -z "$DEVICE" ]; then
  echo "No device connected."
  exit 1
fi

echo "==> Building debug APK (device: $DEVICE)"
flutter build apk --debug --dart-define=GEMINI_API_KEY="$GEMINI_KEY"

echo "==> Installing on device"
"$ADB" -s "$DEVICE" install -r build/app/outputs/flutter-apk/app-debug.apk

echo "==> Launching app"
"$ADB" -s "$DEVICE" shell am start -n com.docflow.docflow_immigrati/.MainActivity

echo "Done."
