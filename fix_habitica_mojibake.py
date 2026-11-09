import json, pathlib, re
ROOT = pathlib.Path(r"A:\opencode\21-IOS")
ITEMS = ROOT / "habitica_items.json"
CACHE = ROOT / "habitica_translations_cache.json"
items = json.loads(ITEMS.read_text(encoding="utf-8-sig"))
SLOT = {"weapon": "Инструмент", "armor": "Тело", "body": "Тело", "back": "Тело", "head": "Голова", "headAccessory": "Голова", "eyewear": "Голова", "shield": "Инструмент"}
SIMPLE = {"food": "Выносливость", "egg": "Мотивация", "potion": "Воображение", "special": "Дисциплина"}
KNOWN = {"Физическая сила", "Интеллект", "Восприятие", "Выносливость", "Мотивация", "Воображение", "Дисциплина"}
ENSTAT = {"Strength": "Физическая сила", "Intelligence": "Интеллект", "Perception": "Восприятие", "Constitution": "Выносливость"}
def fix(s):
    try:
        return s.encode("cp1251").decode("utf-8")
    except Exception:
        return s
fixed_slot = 0
fixed_stat = 0
reset_name = 0
reset_notes = 0
for it in items:
    cat = it.get("category")
    new_slot = SLOT.get(it.get("type") or "", "Аксессуар") if cat == "gear" else "Аксессуар"
    if it.get("slot") != new_slot:
        fixed_slot += 1
    it["slot"] = new_slot
    if cat in SIMPLE:
        it["stat_name"] = SIMPLE[cat]
    else:
        repaired = fix(it.get("stat_name") or "")
        if repaired in KNOWN:
            if repaired != it.get("stat_name"):
                fixed_stat += 1
            it["stat_name"] = repaired
        else:
            pairs = re.findall(r"Increases (Strength|Intelligence|Perception|Constitution) by (\d+)", it.get("notes_en") or "")
            if pairs:
                best = max(pairs, key=lambda x: int(x[1]))
                it["stat_name"] = ENSTAT[best[0]]
                fixed_stat += 1
            else:
                it["stat_name"] = "Интеллект"
    if it.get("text_en") and it.get("text_ru") == it.get("text_en"):
        it["text_ru"] = ""
        reset_name += 1
    if it.get("notes_en") and it.get("notes_ru") == it.get("notes_en"):
        it["notes_ru"] = ""
        reset_notes += 1
ITEMS.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
cache = {}
if CACHE.exists():
    try:
        cache = json.loads(CACHE.read_text(encoding="utf-8-sig"))
    except Exception:
        cache = {}
bad = [k for k, v in list(cache.items()) if k == v]
for k in bad:
    del cache[k]
CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"slots_fixed={fixed_slot} stats_fixed={fixed_stat} reset_names={reset_name} reset_notes={reset_notes} cache_bad_removed={len(bad)} total={len(items)}")
