#!/usr/bin/env python3
# Read-only check before/after deploy. Never prints credentials.
import argparse
import hashlib
import json
import pathlib
import subprocess
import urllib.request

parser = argparse.ArgumentParser()
parser.add_argument('--expected-file')
parser.add_argument('--expected-revision', default='HEAD')
args = parser.parse_args()
expected = pathlib.Path(args.expected_file).read_text() if args.expected_file else subprocess.check_output(
    ['rtk', 'proxy', 'git', 'show', args.expected_revision + ':firestore.rules'], text=True)
token = subprocess.check_output(['rtk', 'proxy', 'gcloud', 'auth', 'print-access-token',
    '--account=arystantelbay@gmail.com', '--project=progressbar-app'], text=True).strip()

def get(path):
    request = urllib.request.Request('https://firebaserules.googleapis.com/v1/' + path,
        headers={'Authorization': 'Bearer ' + token, 'x-goog-user-project': 'progressbar-app'})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)

release = get('projects/progressbar-app/releases/cloud.firestore')
ruleset = get(release['rulesetName'])
files = ruleset['source']['files']
actual = next(file['content'] for file in files if file['name'] == 'firestore.rules')
folder = pathlib.Path('build/rules-verification')
folder.mkdir(parents=True, exist_ok=True)
(folder / 'deployed.rules').write_text(actual)
print('Release:', release['name'])
print('Ruleset:', release['rulesetName'])
print('SHA256:', hashlib.sha256(actual.encode()).hexdigest())
if actual != expected:
    raise SystemExit('MISMATCH: deployed rules differ from the expected repository version. Do not deploy.')
print('MATCH: deployed rules equal the expected repository version.')
