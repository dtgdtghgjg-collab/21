import json, pathlib, urllib.request, concurrent.futures

ROOT = pathlib.Path(r"A:\opencode\21-IOS")
ITEMS = json.loads((ROOT / "habitica_items.json").read_text(encoding="utf-8"))
ASSETS = ROOT / "TwentyOne" / "Assets.xcassets"

def fetch(item):
    asset = item["asset_name"]
    folder = ASSETS / f"{asset}.imageset"
    if folder.exists() and any(folder.iterdir()):
        return None
    data = None
    ext = "png"
    url = item["sprite_url"]
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as r:
            data = r.read()
    except Exception:
        try:
            req = urllib.request.Request(url[:-4] + ".gif", headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                data = r.read()
            ext = "gif"
        except Exception:
            return item["sprite_name"]
    if not data:
        return item["sprite_name"]
    folder.mkdir(parents=True, exist_ok=True)
    fname = f"{asset}.{ext}"
    (folder / fname).write_bytes(data)
    contents = {"images": [{"filename": fname, "idiom": "universal", "scale": "1x"}], "info": {"author": "xcode", "version": 1}}
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2), encoding="utf-8")
    return None

def main():
    missing = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=16) as ex:
        for res in ex.map(fetch, ITEMS):
            if res:
                missing.append(res)
    (ROOT / "habitica_sprites_missing.txt").write_text("\n".join(sorted(missing)), encoding="utf-8")
    print(f"total={len(ITEMS)} missing={len(missing)}")
    print("missing sample:", missing[:20])

if __name__ == "__main__":
    main()
