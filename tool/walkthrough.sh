#!/bin/zsh
# Runs integration_test/walkthrough_test.dart on a booted iOS simulator and
# saves a screenshot of the device at every step it marks.
#
# Before running, in another terminal (needs Java 21 or newer):
#   npx -y firebase-tools@latest emulators:start --only firestore,auth --project progressbar-app
# Then:  tool/walkthrough.sh <simulator id> <folder for screenshots>
set -u
device=$1
out=$2
mkdir -p "$out"
log="$out/run.log"
: > "$log"
rtk proxy flutter test integration_test/walkthrough_test.dart -d "$device" > "$log" 2>&1 &
run=$!
seen=0
while kill -0 $run 2>/dev/null; do
  total=$(grep -cE "^(SHOT|FONT):" "$log")
  while [ "$seen" -lt "$total" ]; do
    seen=$((seen + 1))
    line=$(grep -E "^(SHOT|FONT):" "$log" | sed -n "${seen}p")
    case "$line" in
      SHOT:*) sleep 1; xcrun simctl io "$device" screenshot "$out/${line#SHOT:}.png" > /dev/null 2>&1 ;;
      FONT:*) xcrun simctl ui "$device" content_size "${line#FONT:}" ;;
    esac
  done
  sleep 0.3
done
xcrun simctl ui "$device" content_size large
grep -E "^[0-9]{2}:[0-9]{2} \+|Expected|Actual|Which|tests passed|tests failed|EXCEPTION" "$log" | tail -15
