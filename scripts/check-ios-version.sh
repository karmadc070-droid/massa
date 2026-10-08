#!/bin/bash
curl -s --max-time 20 'https://itunes.apple.com/lookup?id=6804698319&country=vn' \
 | python3 -c "import sys,json; r=json.load(sys.stdin)['results'][0]; print('버전', r['version'], '| 출시일', r['currentVersionReleaseDate'][:10], '|', r['trackName'])"
