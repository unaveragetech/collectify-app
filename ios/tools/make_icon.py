"""Draws the app icon (same gold card glyph as the Android launcher) at 1024x1024."""
from PIL import Image, ImageDraw
import sys

S = 1024
k = S / 108.0
img = Image.new("RGB", (S, S), "#1a2332")
over = Image.new("RGBA", (S, S), (212, 175, 55, int(255 * 0.12)))
img = Image.alpha_composite(img.convert("RGBA"), over)
d = ImageDraw.Draw(img)

def rr(x0, y0, x1, y1, r, fill):
    d.rounded_rectangle([x0 * k, y0 * k, x1 * k, y1 * k], radius=r * k, fill=fill)

rr(29, 26, 79, 82, 6, "#f0d77b")
rr(37, 33, 71, 75, 3, "#1a2332")
# the heart
pts = []
import math
def bez(p0, p1, p2, p3, n=24):
    out = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0] + 3 * (1 - t) * t ** 2 * p2[0] + t ** 3 * p3[0]
        y = (1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1] + 3 * (1 - t) * t ** 2 * p2[1] + t ** 3 * p3[1]
        out.append((x * k, y * k))
    return out
pts += bez((54, 44), (48, 50), (44, 54), (44, 58.5))
pts += bez((44, 58.5), (44, 62), (47, 64.5), (50.3, 64.5))
pts += bez((50.3, 64.5), (52, 64.5), (53.2, 63.8), (54, 62.8))
pts += bez((54, 62.8), (54.8, 63.8), (56, 64.5), (57.7, 64.5))
pts += bez((57.7, 64.5), (61, 64.5), (64, 62), (64, 58.5))
pts += bez((64, 58.5), (64, 54), (60, 50), (54, 44))
d.polygon(pts, fill="#d4af37")
out = sys.argv[1] if len(sys.argv) > 1 else "icon.png"
img.convert("RGB").save(out)
print("wrote", out)
