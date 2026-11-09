import json, pathlib, urllib.request, concurrent.futures

ROOT = pathlib.Path(r"A:\opencode\21-IOS")
ITEMS = {i["sprite_name"]: i for i in json.loads((ROOT / "habitica_items.json").read_text(encoding="utf-8"))}
ASSETS = ROOT / "TwentyOne" / "Assets.xcassets"
BASE = "https://habitica-assets.s3.amazonaws.com/mobileApp/images/"
MISSING = [l.strip() for l in (ROOT / "habitica_sprites_missing.txt").read_text(encoding="utf-8").splitlines() if l.strip()]

def candidates(item):
    name = item["sprite_name"]
    key = item["key"]
    cat = item["category"]
    out = []
    def add(u):
        if u not in out:
            out.append(u)
    add(BASE + name + ".png")
    add(BASE + name + ".gif")
    if "_" in name:
        add(BASE + name.replace("_", "-") + ".png")
    if cat == "gear":
        add(BASE + key + ".png")
        add(BASE + key + ".gif")
        if key.startswith("armor_"):
            suf = key[len("armor_"):]
            for p in ("slim_armor_", "broad_armor_"):
                add(BASE + p + suf + ".png")
                add(BASE + p + suf + ".gif")
    if cat == "special":
        add(BASE + "shop_" + key + ".png")
        add(BASE + key + ".png")
        add(BASE + "inventory_present_" + key + ".png")
    if cat in ("egg", "food", "potion"):
        add(BASE + key + ".png")
        add(BASE + name.replace("_", "-") + ".gif")
    return out

def fetch_one(name):
    item = ITEMS.get(name)
    if not item:
        return (name, None, "no-item")
    asset = item["asset_name"]
    folder = ASSETS / f"{asset}.imageset"
    for url in candidates(item):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                data = r.read()
            if not data:
                continue
            ext = url.rsplit(".", 1)[-1].lower()
            if ext not in ("png", "gif"):
                ext = "png"
            folder.mkdir(parents=True, exist_ok=True)
            fname = f"{asset}.{ext}"
            (folder / fname).write_bytes(data)
            contents = {"images": [{"filename": fname, "idiom": "universal", "scale": "1x"}], "info": {"author": "xcode", "version": 1}}
            (folder / "Contents.json").write_text(json.dumps(contents, indent=2), encoding="utf-8")
            return (name, url, "ok")
        except Exception:
            continue
    return (name, None, "still-missing")

def main():
    recovered = []
    still = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
        for name, url, status in ex.map(fetch_one, MISSING):
            if status == "ok":
                recovered.append((name, url))
            else:
                still.append(name)
    (ROOT / "habitica_sprites_missing.txt").write_text("\n".join(sorted(still)), encoding="utf-8")
    (ROOT / "habitica_sprites_recovered.txt").write_text("\n".join(f"{n} <- {u}" for n, u in sorted(recovered)), encoding="utf-8")
    print(f"missing_before={len(MISSING)} recovered={len(recovered)} still_missing={len(still)}")
    for n, u in recovered[:30]:
        print(f"OK {n} <- {u}")
    print("still:", still[:30])

if __name__ == "__main__":
    main()
