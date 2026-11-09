from PIL import Image, ImageDraw
import math, pathlib, subprocess, json
ASEPRITE = 'A:/Aseprite.v1.3.17/Aseprite.v1.3.17/Aseprite.v1.3.17/Aseprite.exe'
W, H = 300, 140
img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
draw = ImageDraw.Draw(img, 'RGBA')
cx, cy = 148, 66
def star(scale=1.0, dx=0, dy=0):
    pts = []
    for i in range(32):
        ang = 2 * math.pi * i / 32 - math.pi / 2
        r = 68 if i % 2 == 0 else 52
        pts.append((cx + dx + math.cos(ang) * r * 1.55 * scale, cy + dy + math.sin(ang) * r * 0.80 * scale))
    return pts
draw.polygon(star(1.0, 8, 10), fill=(0, 0, 0, 110))
draw.polygon(star(1.0), fill=(165, 10, 10, 255))
draw.polygon(star(0.96), fill=(230, 32, 32, 255))
draw.polygon(star(0.91), fill=(245, 145, 0, 255))
draw.polygon(star(0.86), fill=(255, 205, 0, 255))
draw.polygon(star(0.80, 0, -4), fill=(255, 232, 84, 255))
draw.polygon(star(0.68, -12, -10), fill=(255, 242, 150, 255))
for sx, sy, c in [(34, 24, (255, 255, 255, 255)), (266, 28, (255, 255, 255, 255)), (262, 108, (220, 30, 30, 255))]:
    draw.line([(sx - 5, sy), (sx + 5, sy)], fill=c, width=2)
    draw.line([(sx, sy - 5), (sx, sy + 5)], fill=c, width=2)
FONT = {
    'P': ['01110', '10001', '10001', '11110', '10000', '10000', '10000'],
    'e': ['00000', '00000', '01110', '10001', '11111', '10000', '01110'],
    'n': ['00000', '00000', '10110', '11001', '10001', '10001', '10001'],
    'o': ['00000', '00000', '01110', '10001', '10001', '10001', '01110'],
    '!': ['00100', '00100', '00100', '00100', '00100', '00000', '00100'],
}
text = 'PeenPoon!!'
scale = 2
char_w = 5 * scale + 2
text_w = len(text) * char_w - 2
x0 = (W - text_w) // 2
y0 = (H - 7 * scale) // 2
def draw_text(dx, dy, color):
    for ci, ch in enumerate(text):
        glyph = FONT[ch]
        ox = x0 + ci * char_w + dx
        for gy, row in enumerate(glyph):
            for gx, bit in enumerate(row):
                if bit == '1':
                    x = ox + gx * scale
                    y = y0 + gy * scale + dy
                    draw.rectangle([x, y, x + scale - 1, y + scale - 1], fill=color)
draw_text(2, 3, (150, 60, 0, 255))
draw_text(0, 0, (10, 10, 10, 255))
root = pathlib.Path('A:/opencode/21-IOS/TwentyOne/Assets.xcassets/pinpoon_badge.imageset')
root.mkdir(parents=True, exist_ok=True)
png_path = root / 'pinpoon_badge.png'
img.save(png_path)
(root / 'Contents.json').write_text(json.dumps({'images': [{'filename': 'pinpoon_badge.png', 'idiom': 'universal', 'scale': '1x'}], 'info': {'author': 'xcode', 'version': 1}}, indent=2), encoding='utf-8')
ase_path = pathlib.Path('A:/opencode/Assets/pinpoon_badge.aseprite')
ase_path.parent.mkdir(parents=True, exist_ok=True)
subprocess.run([ASEPRITE, '-b', str(png_path), '--save-as', str(ase_path)], check=False)
print(f'saved {png_path} size={img.size} aseprite={ase_path} exists={ase_path.exists()}')
