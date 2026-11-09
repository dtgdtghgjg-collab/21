import pathlib, json
ROOT = pathlib.Path(r'A:\opencode\21-IOS')
p = ROOT / 'TwentyOne' / 'Models' / 'HabiticaPetsCatalog.swift'
t = p.read_text(encoding='utf-8')
for old, new in [('(База)', '(Базовый)'), ('(Оттенок)', '(Тень)'), ('(мерцание)', '(Мерцающий)')]:
    print(old, t.count(old))
    t = t.replace(old, new)
p.write_text(t, encoding='utf-8')
cpath = ROOT / 'habitica_translations_cache.json'
cache = json.loads(cpath.read_text(encoding='utf-8-sig')) if cpath.exists() else {}
cache.update({'Base': 'Базовый', 'Shade': 'Тень', 'Shimmer': 'Мерцающий'})
cpath.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding='utf-8')
print('done')
