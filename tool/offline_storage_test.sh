#!/bin/zsh
# Checks offline workout storage across a real app restart on an iOS simulator.
# Works only with the local Firebase emulators; production is never contacted.
#
# Before running, in another terminal (needs Java 21 or newer):
#   npx -y firebase-tools@latest emulators:start --only firestore,auth --project progressbar-app
# Then, with the simulator booted:
#   tool/offline_storage_test.sh <simulator id>
#
# `flutter test` cannot do this: it removes the app, and its local database
# with it, after every run. Here the test is built as the app itself, installed
# over the previous build and its process is killed between the two phases.
set -u
device=$1
bundle=com.atelbay.progressbar
log=$(mktemp -t offline-storage)

for phase in first restart; do
  rtk proxy flutter build ios --simulator --debug \
    -t integration_test/offline_storage_test.dart --dart-define=PHASE=$phase | tail -1
  xcrun simctl install "$device" build/ios/iphonesimulator/Runner.app || exit 1
  : > "$log"
  xcrun simctl spawn "$device" log stream --style compact \
    --predicate 'process == "Runner" AND eventMessage CONTAINS "flutter"' >> "$log" 2>&1 &
  stream=$!
  sleep 2
  xcrun simctl launch --terminate-running-process "$device" $bundle > /dev/null
  for i in $(seq 1 60); do
    grep -qE "All tests passed|Some tests failed" "$log" && break
    sleep 2
  done
  # Killed as it is: after the first phase that is offline, with an unsent write.
  xcrun simctl terminate "$device" $bundle
  kill $stream 2>/dev/null
  echo "--- $phase"
  grep "flutter: " "$log" | sed -E 's/^.*flutter: //'
  if ! grep -q "All tests passed" "$log"; then
    echo "Phase $phase failed; full log: $log"
    xcrun simctl uninstall "$device" $bundle
    exit 1
  fi
done
xcrun simctl uninstall "$device" $bundle
rm -f "$log"
