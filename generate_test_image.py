#!/usr/bin/env python3
"""One test image via PositionAPI gpt-image-2."""
import base64, json, os, sys, urllib.request
from pathlib import Path

URL = "https://positionapi.top/v1/images/generations"
PROMPT = "High-resolution pixel art sprite of a worn battered notebook, crisp pixels, large chunky pixels, bold outlines, no anti-aliasing, no blur, centered and large, isolated on a transparent background, 1024x1024"
OUT = Path(__file__).resolve().parent / "ArtSamples" / "test_item_reg-notebook.png"

def get_key():
    for name in ("POSITIONAPI_API_KEY", "POSITION_API_KEY", "OPENAI_API_KEY"):
        value = os.environ.get(name)
        if value:
            return value
    auth = Path.home() / ".local" / "share" / "opencode" / "auth.json"
    try:
        data = json.loads(auth.read_text(encoding="utf-8"))
        entry = data.get("positionapi") or {}
        if isinstance(entry, dict) and entry.get("key"):
            return entry["key"]
    except Exception:
        pass
    sys.exit("PositionAPI key not found: set POSITIONAPI_API_KEY (the key is not hardcoded in this script)")

def main():
    payload = {"model": "gpt-image-2", "prompt": PROMPT, "n": 1, "size": "1024x1024"}
    request = urllib.request.Request(URL, data=json.dumps(payload).encode("utf-8"), headers={"Authorization": "Bearer " + get_key(), "Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(request, timeout=180) as response:
        result = json.loads(response.read().decode("utf-8"))
    b64_json = result["data"][0]["b64_json"]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(base64.b64decode(b64_json))
    print(f"Saved {OUT} ({OUT.stat().st_size} bytes)")

if __name__ == "__main__":
    main()
