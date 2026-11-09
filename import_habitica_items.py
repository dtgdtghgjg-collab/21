import json, collections, pathlib

SRC = pathlib.Path(r"A:\opencode\habitica-iOS\Habitica API Client\Habitica API ClientTests\Fixtures\content.json")
OUT_JSON = pathlib.Path(r"A:\opencode\21-IOS\habitica_items.json")
OUT_URLS = pathlib.Path(r"A:\opencode\21-IOS\habitica_sprites.txt")
OUT_REPORT = pathlib.Path(r"A:\opencode\21-IOS\habitica_items_report.md")
BASE = "https://habitica-assets.s3.amazonaws.com/mobileApp/images/"

def rank_for_value(v):
    try:
        v = float(v or 0)
    except Exception:
        v = 0
    if v <= 3:
        return "F"
    if v <= 10:
        return "E"
    if v <= 20:
        return "D"
    if v <= 35:
        return "C"
    if v <= 55:
        return "B"
    if v <= 75:
        return "A"
    if v <= 100:
        return "S"
    if v <= 130:
        return "SS"
    if v <= 170:
        return "SSS"
    return "R"

def gear_points(n):
    n = int(n or 0)
    if n <= 3:
        return 1
    if n <= 6:
        return 2
    if n <= 9:
        return 3
    if n <= 14:
        return 4
    if n <= 19:
        return 5
    if n <= 24:
        return 6
    if n <= 29:
        return 7
    return 8

STAT_RU = {"str": "Физическая сила", "int": "Интеллект", "per": "Восприятие", "con": "Выносливость"}
SLOT_RU = {"weapon": "Инструмент", "armor": "Тело", "body": "Тело", "back": "Тело", "head": "Голова", "headAccessory": "Голова", "eyewear": "Голова", "shield": "Инструмент"}

def asset_id(cat, key):
    s = f"hab-{cat}-{key}".lower().replace("_", "-").replace(" ", "-")
    return "".join(c for c in s if c.isalnum() or c == "-")

def main():
    raw = json.loads(SRC.read_text(encoding="utf-8"))
    data = raw.get("data", raw)
    items = []
    gear = (data.get("gear") or {}).get("flat") or {}
    for key in sorted(gear):
        g = gear[key] or {}
        stats = {k: int(g.get(k) or 0) for k in ("str", "int", "per", "con")}
        best = max(stats, key=lambda k: stats[k])
        best_val = stats[best]
        value = float(g.get("value") or 0)
        sprite = f"shop_{key}"
        items.append({"category": "gear", "key": key, "id": asset_id("gear", key), "text_en": g.get("text") or "", "notes_en": g.get("notes") or "", "text_ru": "", "notes_ru": "", "value": value, "type": g.get("type") or "", "klass": g.get("klass") or "", "gear_set": g.get("set") or "", "slot": SLOT_RU.get(g.get("type") or "", "Аксессуар"), "stat_name": STAT_RU[best] if best_val > 0 else "Интеллект", "stat_points": gear_points(best_val), "rank": rank_for_value(value), "sprite_name": sprite, "sprite_url": BASE + sprite + ".png", "asset_name": "item_" + asset_id("gear", key)})
    def add_simple(cat, mapping, sprite_prefix, slot, stat_name):
        for key in sorted(mapping or {}):
            v = mapping[key] or {}
            value = float(v.get("value") or 0)
            sprite = f"{sprite_prefix}{key}"
            items.append({"category": cat, "key": key, "id": asset_id(cat, key), "text_en": v.get("text") or "", "notes_en": v.get("notes") or "", "text_ru": "", "notes_ru": "", "value": value, "type": v.get("itemType") or cat, "klass": "", "gear_set": "", "slot": slot, "stat_name": stat_name, "stat_points": 2 if value > 5 else 1, "rank": rank_for_value(value), "sprite_name": sprite, "sprite_url": BASE + sprite + ".png", "asset_name": "item_" + asset_id(cat, key)})
    add_simple("food", data.get("food"), "Pet_Food_", "Аксессуар", "Выносливость")
    add_simple("egg", data.get("eggs"), "Pet_Egg_", "Аксессуар", "Мотивация")
    add_simple("potion", data.get("hatchingPotions"), "Pet_HatchingPotion_", "Аксессуар", "Воображение")
    add_simple("special", data.get("special"), "inventory_special_", "Аксессуар", "Дисциплина")
    OUT_JSON.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
    OUT_URLS.write_text("\n".join(i["sprite_url"] for i in items), encoding="utf-8")
    by_cat = collections.Counter(i["category"] for i in items)
    by_rank = collections.Counter(i["rank"] for i in items)
    by_slot = collections.Counter(i["slot"] for i in items)
    vals = sorted(i["value"] for i in items)
    lines = ["# Habitica -> 21: отчет по выгрузке", "", f"Всего: {len(items)}", ""]
    lines.append("## По категориям")
    for k, v in sorted(by_cat.items()):
        lines.append(f"- {k}: {v}")
    lines.append("")
    lines.append("## По рангам (предварительно, по value)")
    for k in ("F", "E", "D", "C", "B", "A", "S", "SS", "SSS", "R"):
        lines.append(f"- {k}: {by_rank.get(k, 0)}")
    lines.append("")
    lines.append("## По слотам")
    for k, v in sorted(by_slot.items()):
        lines.append(f"- {k}: {v}")
    lines.append("")
    if vals:
        lines.append(f"Value: min={vals[0]} max={vals[-1]} median={vals[len(vals)//2]}")
    lines.append("")
    lines.append("Источник: content.json (fixture habitica-iOS). Спрайты: habitica-assets S3, .png; gif-исключения из ImageManager пока не учтены - проверятся при скачивании по 404.")
    OUT_REPORT.write_text("\n".join(lines), encoding="utf-8")
    print(f"total={len(items)} by_cat={dict(by_cat)} by_rank={dict(by_rank)}")
    print(f"value min={vals[0] if vals else 0} max={vals[-1] if vals else 0} median={vals[len(vals)//2] if vals else 0}")
    print(f"wrote {OUT_JSON} {OUT_URLS} {OUT_REPORT}")

if __name__ == "__main__":
    main()
