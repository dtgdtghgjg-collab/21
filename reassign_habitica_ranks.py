import json, pathlib, re, collections
ROOT = pathlib.Path(r'A:\opencode\21-IOS')
P = ROOT / 'habitica_items.json'
items = json.loads(P.read_text(encoding='utf-8-sig'))

def score(it):
    s = float(it.get('value') or 0) + float(it.get('stat_points') or 0) * 18
    key = (it.get('key') or '') + ' ' + (it.get('gear_set') or '')
    m = re.search(r'20\d\d', key)
    if m:
        s += max(0, 2026 - int(m.group(0))) * 4
    if 'critical' in key or 'ks2019' in key:
        s += 40
    return s

PLANS = {
    'consumable': [('C', 0.03), ('D', 0.12), ('E', 0.30), ('F', 0.55)],
    'class': [('S', 0.04), ('A', 0.10), ('B', 0.14), ('C', 0.18), ('D', 0.18), ('E', 0.18), ('F', 0.18)],
    'armoire': [('SSS', 0.02), ('SS', 0.08), ('S', 0.15), ('A', 0.25), ('B', 0.25), ('C', 0.15), ('D', 0.10)],
    'mystery': [('R', 0.03), ('SSS', 0.10), ('SS', 0.20), ('S', 0.30), ('A', 0.22), ('B', 0.15)],
    'special': [('R', 0.01), ('SSS', 0.03), ('SS', 0.06), ('S', 0.12), ('A', 0.16), ('B', 0.18), ('C', 0.18), ('D', 0.13), ('E', 0.08), ('F', 0.05)],
}

def group(it):
    if it.get('category') != 'gear':
        return 'consumable'
    k = it.get('klass') or ''
    if k in ('warrior', 'rogue', 'healer', 'wizard', 'base', ''):
        return 'class'
    if k in PLANS:
        return k
    return 'special'

groups = collections.defaultdict(list)
for it in items:
    groups[group(it)].append(it)
for name, lst in groups.items():
    lst.sort(key=score, reverse=True)
    plan = PLANS[name]
    idx = 0
    for i, (rank, share) in enumerate(plan):
        n = len(lst) - idx if i == len(plan) - 1 else int(round(len(lst) * share))
        for it in lst[idx:idx + n]:
            it['rank'] = rank
        idx += n
P.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding='utf-8')
print('total', len(items))
print('rank', dict(collections.Counter(x['rank'] for x in items)))
for name, lst in sorted(groups.items()):
    print(name, len(lst), dict(collections.Counter(x['rank'] for x in lst)))
print('R items:', [x['id'] for x in items if x['rank'] == 'R'])
