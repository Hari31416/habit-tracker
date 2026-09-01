#!/usr/bin/env bash
set -euo pipefail

SUITE="${1:-subset}"
APK_PATH="${2:-build/app/outputs/flutter-apk/app-debug.apk}"

echo "Installing APK: $APK_PATH"
adb install -r "$APK_PATH"

echo "Running Maestro suite mode: $SUITE"
if [ "$SUITE" = "full" ]; then
  FLOWS=$(find .maestro -maxdepth 1 -name "*.yaml" | sort)
else
  FLOWS=".maestro/smoke.yaml .maestro/create_and_check_in.yaml .maestro/archive_habit.yaml"
fi

for flow in $FLOWS; do
  echo ""
  echo "=== Running $flow ==="
  maestro test "$flow"
done

echo "All Maestro tests completed successfully."
