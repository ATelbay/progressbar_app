#!/usr/bin/env python3
# Run from the repo root through rtk proxy python3.
import pathlib
import subprocess
import sys

device, output = sys.argv[1:3]
out = pathlib.Path(output).resolve()
out.mkdir(parents=True, exist_ok=True)
command = ['rtk', 'proxy', 'flutter', 'test', 'integration_test/links_test.dart', '-d', device]
with (out / 'run.log').open('w') as log:
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in process.stdout:
        log.write(line)
        log.flush()
        if line.startswith('SHOT:'):
            name = line.strip().split(':', 1)[1]
            subprocess.run(['rtk', 'proxy', 'xcrun', 'simctl', 'io', device,
                'screenshot', str(out / (name + '.png'))], check=False, capture_output=True)
            print(name, flush=True)
        elif 'All tests passed' in line or 'EXCEPTION' in line or 'tests failed' in line:
            print(line.strip(), flush=True)
    sys.exit(process.wait())
