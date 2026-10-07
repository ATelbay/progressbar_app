#!/bin/zsh
# The Android twin of tool/offline_storage_test.sh: offline workout storage
# across a real app restart on an Android emulator. Works only with the local
# Firebase emulators; production is never contacted.
#
# Before running, in another terminal (needs Java 21 or newer):
#   npx -y firebase-tools@latest emulators:start --only firestore,auth --project progressbar-app
# Then, with the Android emulator booted:
#   tool/offline_storage_test_android.sh <adb serial>
set -u
device=$1
package=com.atelbay.progressbar
log=$(mktemp -t offline-storage-android)

# The test asks the Auth emulator for the SMS code over plain HTTP on localhost.
adb -s "$device" reverse tcp:8080 tcp:8080 > /dev/null
adb -s "$device" reverse tcp:9099 tcp:9099 > /dev/null
adb -s "$device" uninstall $package > /dev/null 2>&1

for phase in first restart; do
  rtk proxy flutter build apk --debug \
    -t integration_test/offline_storage_test.dart --dart-define=PHASE=$phase | tail -1
  # Installed over the previous build, so the app's local database stays.
  adb -s "$device" install -r build/app/outputs/flutter-apk/app-debug.apk > /dev/null || exit 1
  adb -s "$device" logcat -c
  : > "$log"
  adb -s "$device" logcat -s flutter >> "$log" 2>&1 &
  stream=$!
  adb -s "$device" shell am start -n $package/.MainActivity > /dev/null
  for i in $(seq 1 60); do
    grep -qE "All tests passed|Some tests failed" "$log" && break
    sleep 2
  done
  # Killed as it is: after the first phase that is offline, with an unsent write.
  adb -s "$device" shell am force-stop $package
  kill $stream 2>/dev/null
  echo "--- $phase"
  grep "flutter" "$log" | sed -E 's/^.*flutter *: //'
  if ! grep -q "All tests passed" "$log"; then
    echo "Phase $phase failed; full log: $log"
    adb -s "$device" uninstall $package > /dev/null
    exit 1
  fi
done
adb -s "$device" uninstall $package > /dev/null
rm -f "$log"
