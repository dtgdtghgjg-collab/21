import urllib.request, urllib.error, pathlib, json

BASE = 'https://habitica-assets.s3.amazonaws.com/mobileApp/images/'
ASSETS = pathlib.Path(r'A:\opencode\21-IOS\TwentyOne\Assets.xcassets')
NAMES = ['achievement-congrats', 'achievement-dysheartener', 'achievement-getwell', 'achievement-goodluck', 'achievement-friends', 'achievement-challenge', 'achievement-guild', 'achievement-lostMasterclasser', 'achievement-npc', 'achievement-royally-loyal']

def contents_json(asset):
    return json.dumps({'images': [{'filename': asset + '.png', 'idiom': 'universal', 'scale': '1x'}], 'info': {'author': 'xcode', 'version': 1}}, indent=2)

for name in NAMES:
    found = None
    for suf in ['', '2x']:
        url = BASE + name + suf + '.png'
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=20) as r:
                data = r.read()
            if data:
                found = suf
                dest = ASSETS / (name + '.imageset')
                dest.mkdir(parents=True, exist_ok=True)
                (dest / (name + '.png')).write_bytes(data)
                (dest / 'Contents.json').write_text(contents_json(name), encoding='utf-8')
                print(name, suf, 'OK', len(data))
                break
        except Exception as e:
            print(name, suf, 'fail', getattr(e, 'code', e))
    if not found:
        print(name, 'MISSING')
