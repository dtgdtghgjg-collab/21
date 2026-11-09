import json, pathlib, urllib.request, urllib.parse, time

ROOT = pathlib.Path(r"A:\opencode\21-IOS")
ITEMS_PATH = ROOT / "habitica_items.json"
CACHE_PATH = ROOT / "habitica_translations_cache.json"
OUT_SWIFT = ROOT / "TwentyOne" / "Models" / "HabiticaCatalog.swift"

def load_cache():
    if CACHE_PATH.exists():
        try:
            return json.loads(CACHE_PATH.read_text(encoding="utf-8-sig"))
        except Exception:
            return {}
    return {}

def translate(text, cache):
    text = (text or "").strip()
    if not text:
        return ""
    if text in cache:
        return cache[text]
    last_err = None
    for attempt in range(6):
        try:
            q = urllib.parse.quote(text)
            url = f"https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ru&dt=t&q={q}"
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=15) as r:
                data = json.loads(r.read().decode("utf-8"))
            res = "".join(seg[0] for seg in data[0] if seg and seg[0]).strip()
            if res:
                cache[text] = res
                time.sleep(0.8)
                return res
        except Exception as e:
            last_err = e
            time.sleep(5.0 * (2 ** attempt))
    print(f"translate failed, keeping EN: {text[:60]} err={last_err}")
    return ""

def swift_str(s):
    return (s or "").replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ").replace("\r", " ").strip()

def main():
    items = json.loads(ITEMS_PATH.read_text(encoding="utf-8-sig"))
    cache = load_cache()
    done = 0
    for i, it in enumerate(items):
        if not it.get("text_ru"):
            it["text_ru"] = translate(it.get("text_en", ""), cache)
        if it.get("notes_en") and not it.get("notes_ru"):
            it["notes_ru"] = translate(it.get("notes_en", ""), cache)
        elif not it.get("notes_en"):
            it["notes_ru"] = ""
        done += 1
        if i % 50 == 0:
            CACHE_PATH.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
            ITEMS_PATH.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"progress {i+1}/{len(items)}")
    CACHE_PATH.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
    ITEMS_PATH.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
    lines = []
    lines.append("// HabiticaCatalog.swift")
    lines.append("// Auto-generated from habitica-iOS content.json (fixture).")
    lines.append("// 844 items: gear 720 + food 31 + eggs 54 + potions 23 + special 16.")
    lines.append("// 8 items have no sprite in Assets.xcassets and fall back to ItemArtwork icon.")
    lines.append("// Names/descriptions translated EN -> RU via translate.googleapis.com; see habitica_items.json for originals.")
    lines.append("")
    lines.append("let habiticaCatalog: [CatalogItem] = [")
    for it in items:
        name = swift_str(it.get("text_ru") or it.get("text_en", ""))
        desc = swift_str(it.get("notes_ru") or it.get("notes_en", ""))
        lines.append(f'    CatalogItem(id: "{swift_str(it["id"])}", name: "{name}", rank: "{it["rank"]}", desc: "{desc}", slot: "{swift_str(it["slot"])}", statName: "{swift_str(it["stat_name"])}", statPoints: {int(it["stat_points"])}),')
    lines.append("]")
    lines.append("")
    OUT_SWIFT.parent.mkdir(parents=True, exist_ok=True)
    OUT_SWIFT.write_text("\n".join(lines), encoding="utf-8")
    no_sprite = [it["id"] for it in items if not it.get("hasSprite")]
    print(f"done items={len(items)} swift={OUT_SWIFT} no_sprite={len(no_sprite)} {no_sprite}")

if __name__ == "__main__":
    main()
