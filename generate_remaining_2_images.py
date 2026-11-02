#!/usr/bin/env python3
import base64, json, os, sys, urllib.request
from pathlib import Path
URL = "https://positionapi.top/v1/images/generations"
OUT_DIR = Path(__file__).resolve().parent / "ArtSamples"
ITEMS = [
    ("item_unique-death-note", "High-resolution pixel art sprite of an ominous black Death Note notebook with stylized white gothic lettering on the cover, crisp pixels, large chunky pixels, bold outlines, no anti-aliasing, no blur, centered and large, isolated on a transparent background, 1024x1024"),
    ("item_black-mjolnir", "High-resolution pixel art sprite of Mjolnir, Thors mighty hammer with a short brown handle, engraved grey head and crackling blue lightning, crisp pixels, large chunky pixels, bold outlines, no anti-aliasing, no blur, centered and large, isolated on a transparent background, 1024x1024"),
]
def main():
    key = os.environ.get("POSITIONAPI_API_KEY")
    if not key:
        sys.exit("POSITIONAPI_API_KEY not found in process env")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, prompt in ITEMS:
        payload = {"model": "gpt-image-2", "prompt": prompt, "n": 1, "size": "1024x1024"}
        req = urllib.request.Request(URL, data=json.dumps(payload).encode("utf-8"), headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"}, method="POST")
        with urllib.request.urlopen(req, timeout=180) as resp:
            result = json.loads(resp.read().decode("utf-8"))
        out = OUT_DIR / (name + ".png")
        out.write_bytes(base64.b64decode(result["data"][0]["b64_json"]))
        print(f"Saved {out} ({out.stat().st_size} bytes)")
if __name__ == "__main__":
    main()
