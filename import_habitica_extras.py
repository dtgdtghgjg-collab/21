import json, pathlib, urllib.request, shutil
from concurrent.futures import ThreadPoolExecutor

SRC = pathlib.Path(r'A:\opencode\habitica-iOS\Habitica API Client\Habitica API ClientTests\Fixtures\content.json')
ROOT = pathlib.Path(r'A:\opencode\21-IOS')
ASSETS = ROOT / 'TwentyOne' / 'Assets.xcassets'
BASE = 'https://habitica-assets.s3.amazonaws.com/mobileApp/images/'
HABSRC = pathlib.Path(r'A:\opencode\habitica-iOS\HabitRPG\Images.xcassets')

def sanitize(s):
    s = s.lower().replace('_', '-').replace(' ', '-')
    return ''.join(c for c in s if c.isalnum() or c == '-')

def contents_json(asset):
    return json.dumps({'images': [{'filename': asset + '.png', 'idiom': 'universal', 'scale': '1x'}], 'info': {'author': 'xcode', 'version': 1}}, indent=2)

def download(args):
    sprite, asset = args
    dest = ASSETS / (asset + '.imageset')
    png = dest / (asset + '.png')
    if png.exists() and png.stat().st_size > 0:
        return None
    try:
        req = urllib.request.Request(BASE + sprite + '.png', headers={'User-Agent': 'Mozilla/5.0'})
        data = urllib.request.urlopen(req, timeout=30).read()
    except Exception:
        return sprite
    dest.mkdir(parents=True, exist_ok=True)
    png.write_bytes(data)
    (dest / 'Contents.json').write_text(contents_json(asset), encoding='utf-8')
    return None

def main():
    data = json.loads(SRC.read_text(encoding='utf-8')).get('data', {})
    gear = (data.get('gear') or {}).get('flat') or {}
    month_season = {12: 'Зима', 1: 'Зима', 2: 'Зима', 3: 'Весна', 4: 'Весна', 5: 'Весна', 6: 'Лето', 7: 'Лето', 8: 'Лето', 9: 'Осень', 10: 'Осень', 11: 'Осень'}
    seasonal = []
    for key in sorted(gear):
        g = gear[key] or {}
        ev = g.get('event')
        if not ev:
            continue
        start = ev.get('start') or ''
        month = int(start[5:7]) if len(start) >= 7 else 1
        seasonal.append({'key': key, 'catalog_id': 'hab-gear-' + sanitize(key), 'asset_name': 'item_hab-gear-' + sanitize(key), 'season': month_season[month], 'season_label': month_season[month] + ' ' + start[:4], 'start': start, 'end': ev.get('end') or '', 'value': float(g.get('value') or 0)})
    pets = []
    for key in sorted(data.get('petInfo') or {}):
        p = data['petInfo'][key] or {}
        pets.append({'key': key, 'type': p.get('type') or '', 'egg': p.get('egg') or '', 'potion': p.get('potion') or '', 'text_en': p.get('text') or key, 'sprite_name': 'stable_Pet-' + key, 'asset_name': 'pet_' + sanitize(key)})
    achievements = []
    for key in sorted(data.get('achievements') or {}):
        a = data['achievements'][key] or {}
        icon = a.get('icon') or ('achievement-' + key)
        achievements.append({'key': key, 'icon': icon, 'title_key': a.get('titleKey') or '', 'text_key': a.get('textKey') or '', 'asset_name': sanitize(icon)})
    jobs = [(p['sprite_name'], p['asset_name']) for p in pets] + [(a['icon'], a['asset_name']) for a in achievements]
    with ThreadPoolExecutor(max_workers=16) as ex:
        missing = [m for m in ex.map(download, jobs) if m]
    for name in ('Winter', 'Spring', 'Summer', 'Fall'):
        srcpng = HABSRC / ('menu_SeasonalShop' + name + '.imageset') / ('menu_SeasonalShop' + name + '.png')
        asset = 'seasonal_shop_' + name.lower()
        dest = ASSETS / (asset + '.imageset')
        dest.mkdir(parents=True, exist_ok=True)
        if srcpng.exists():
            shutil.copyfile(srcpng, dest / (asset + '.png'))
            (dest / 'Contents.json').write_text(contents_json(asset), encoding='utf-8')
    out = {'seasonal': seasonal, 'pets': pets, 'achievements': achievements, 'missing_sprites': missing}
    (ROOT / 'habitica_extras.json').write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding='utf-8')
    print('seasonal', len(seasonal), 'pets', len(pets), 'achievements', len(achievements), 'missing', len(missing))
    print('missing sample', missing[:20])

if __name__ == '__main__':
    main()
