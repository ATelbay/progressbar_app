#!/usr/bin/env python3
# Runs an integration test on an Android emulator against the local Firebase
# emulators and saves a screenshot at every step the test marks.
#
# Before running (needs Java 21 or newer):
#   npx -y firebase-tools@latest emulators:start --only firestore,auth --project progressbar-app
# Then, from the repo root:
#   rtk proxy python3 tool/android_walkthrough.py <adb serial> <test file> <folder for screenshots>
#
# Lines the test prints and this script acts on:
#   SHOT:<name>  screenshot of the device
#   FONT:<size>  system font size, named as on iOS
#   LINK:<url>   open the link the way Android opens one from the camera
#   BACK:        the system «back» button
import pathlib
import subprocess
import sys
import time

device, test, output = sys.argv[1:4]
out = pathlib.Path(output).resolve()
out.mkdir(parents=True, exist_ok=True)
font_scales = {'large': '1.0', 'accessibility-large': '1.5'}


def adb(*args, **kwargs):
    return subprocess.run(['adb', '-s', device, *args], check=False, capture_output=True, **kwargs)


# The test asks the Auth emulator for the SMS code over plain HTTP on localhost.
for port in ('8080', '9099'):
    adb('reverse', 'tcp:' + port, 'tcp:' + port)
adb('shell', 'settings', 'put', 'system', 'font_scale', '1.0')
failures = 0
command = ['rtk', 'proxy', 'flutter', 'test', test, '-d', device]
with (out / 'run.log').open('w') as log:
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in process.stdout:
        log.write(line)
        log.flush()
        kind, _, value = line.strip().partition(':')
        if kind == 'SHOT':
            time.sleep(1)
            (out / (value + '.png')).write_bytes(adb('exec-out', 'screencap', '-p').stdout)
            print(value, flush=True)
        elif kind == 'FONT':
            adb('shell', 'settings', 'put', 'system', 'font_scale', font_scales[value])
        elif kind == 'LINK':
            adb('shell', 'am', 'start', '-a', 'android.intent.action.VIEW', '-d', value)
        elif kind == 'BACK':
            adb('shell', 'input', 'keyevent', 'BACK')
        elif 'All tests passed' in line or 'EXCEPTION' in line or 'tests failed' in line:
            print(line.strip(), flush=True)
            if 'EXCEPTION' in line:
                failures += 1
                (out / f'failure-{failures}.png').write_bytes(adb('exec-out', 'screencap', '-p').stdout)
    code = process.wait()
adb('shell', 'settings', 'put', 'system', 'font_scale', '1.0')
sys.exit(code)
