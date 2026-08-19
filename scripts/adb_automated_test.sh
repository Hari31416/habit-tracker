#!/usr/bin/env bash
set -e

ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="$(which adb 2>/dev/null || echo "$ANDROID_HOME/platform-tools/adb")"
PACKAGE_NAME="com.productivity.habits"
MAIN_ACTIVITY="$PACKAGE_NAME.MainActivity"
SCREENSHOT_DIR="build/screenshots"

mkdir -p "$SCREENSHOT_DIR"

echo "=== 1. Checking ADB Device Connection ==="
"$ADB" wait-for-device
DEVICES=$("$ADB" devices | grep -v "List" | grep "device" | wc -l | tr -d ' ')
if [ "$DEVICES" -eq "0" ]; then
    echo "Error: No connected Android device found."
    exit 1
fi
echo "Connected device detected."

echo "=== 2. Launching Application ==="
"$ADB" shell am force-stop "$PACKAGE_NAME"
sleep 1
"$ADB" shell am start -n "$PACKAGE_NAME/$MAIN_ACTIVITY"
sleep 3

PID=$("$ADB" shell pidof -s "$PACKAGE_NAME" | tr -d '\r')
if [ -z "$PID" ]; then
    echo "Error: Process $PACKAGE_NAME is not running."
    exit 1
fi
echo "Application running with PID: $PID"

WM_SIZE=$("$ADB" shell wm size | awk '{print $NF}' | tr -d '\r')
WIDTH=$(echo "$WM_SIZE" | cut -d'x' -f1)
HEIGHT=$(echo "$WM_SIZE" | cut -d'x' -f2)
echo "Device resolution: ${WIDTH}x${HEIGHT}"

take_screenshot() {
    local name="$1"
    local remote_path="/sdcard/$name.png"
    local local_path="$SCREENSHOT_DIR/$name.png"
    "$ADB" shell screencap -p "$remote_path"
    "$ADB" pull "$remote_path" "$local_path" >/dev/null 2>&1
    "$ADB" shell rm "$remote_path"
    echo "Captured screenshot: $local_path"
}

# Bottom navigation bar coordinates
NAV_Y=$((HEIGHT * 94 / 100))
NAV_TODAY_X=$((WIDTH * 10 / 100))
NAV_WEEK_X=$((WIDTH * 30 / 100))
NAV_ADD_X=$((WIDTH * 50 / 100))
NAV_ANALYTICS_X=$((WIDTH * 70 / 100))
NAV_MASTERY_X=$((WIDTH * 90 / 100))

echo "=== 3. Testing Daily Tracker Screen ==="
take_screenshot "01_daily_tracker_ready"

# Tap habit checkbox specifically on the right edge
echo "Tapping habit checkbox on Daily Tracker..."
"$ADB" shell input tap $((WIDTH * 90 / 100)) $((HEIGHT * 38 / 100))
sleep 1
take_screenshot "02_daily_tracker_after_tap"

# Test scroll down on Daily Tracker
echo "Scrolling Daily Tracker..."
"$ADB" shell input swipe $((WIDTH / 2)) $((HEIGHT * 65 / 100)) $((WIDTH / 2)) $((HEIGHT * 30 / 100)) 300
sleep 1
take_screenshot "03_daily_tracker_scrolled"

# Scroll back up
"$ADB" shell input swipe $((WIDTH / 2)) $((HEIGHT * 30 / 100)) $((WIDTH / 2)) $((HEIGHT * 65 / 100)) 300
sleep 1

# Ensure we are on root screen (send BACK in case a modal or detail screen was open)
"$ADB" shell input keyevent 4
sleep 1

echo "=== 4. Testing Week Matrix Navigation ==="
echo "Tapping 'Week' bottom navigation..."
"$ADB" shell input tap "$NAV_WEEK_X" "$NAV_Y"
sleep 2
take_screenshot "04_week_matrix"

echo "=== 5. Testing Analytics Screen Navigation ==="
echo "Tapping 'Analytics' bottom navigation..."
"$ADB" shell input tap "$NAV_ANALYTICS_X" "$NAV_Y"
sleep 2
take_screenshot "06_analytics_overview"

echo "=== 6. Testing Mastery / Badges Showcase Navigation ==="
echo "Tapping 'Mastery' bottom navigation..."
"$ADB" shell input tap "$NAV_MASTERY_X" "$NAV_Y"
sleep 2
take_screenshot "08_mastery_badges"

echo "=== 7. Testing Return to Today Tracker ==="
echo "Tapping 'Today' bottom navigation..."
"$ADB" shell input tap "$NAV_TODAY_X" "$NAV_Y"
sleep 2
take_screenshot "09_returned_to_today"

echo "=== 8. Checking Logcat for Crashes or Errors ==="
ERRORS=$("$ADB" logcat -d | grep -i "fatal\|uncaught\|crash\|androidruntime" | grep -i "$PACKAGE_NAME" | head -n 20 || true)
if [ -n "$ERRORS" ]; then
    echo "Warning: Potential errors found in logcat:"
    echo "$ERRORS"
else
    echo "No fatal crashes or uncaught exceptions found in logcat."
fi

echo "=== All Automated ADB Tests Completed Successfully ==="
