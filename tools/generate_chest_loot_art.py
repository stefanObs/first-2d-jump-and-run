#!/usr/bin/env python3
"""Generate hand-painted chest loot reveal sprites for Cowboy Trail."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1] / "assets" / "world" / "chest_loot"
MODES = Path(__file__).resolve().parents[1] / "assets" / "world" / "modes"
BADGE = Path(__file__).resolve().parents[1] / "assets" / "world" / "star_badge.png"

INK = (56, 26, 10, 255)
GLOW = (255, 210, 72, 255)
SPARK = (255, 248, 210, 255)


def _glow_ring(size: int, alpha: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = cy = size * 0.5
    for radius, a in ((size * 0.46, alpha // 3), (size * 0.34, alpha // 2), (size * 0.22, alpha)):
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=(*GLOW[:3], a))
    return img.filter(ImageFilter.GaussianBlur(radius=2))


def _spark_stars(draw: ImageDraw.ImageDraw, cx: float, cy: float, count: int = 4) -> None:
    for i in range(count):
        angle = i * (math.tau / count) + 0.4
        sx = cx + math.cos(angle) * 22
        sy = cy + math.sin(angle) * 18
        draw.line([(sx - 3, sy), (sx + 3, sy)], fill=SPARK, width=2)
        draw.line([(sx, sy - 3), (sx, sy + 3)], fill=SPARK, width=2)


def make_reveal(source: Path, out_name: str, tint: tuple[int, int, int] | None = None) -> None:
    base = Image.open(source).convert("RGBA")
    size = 72
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow = _glow_ring(size, 90)
    canvas.alpha_composite(glow, (0, 0))

    icon = base.copy()
    icon.thumbnail((46, 46), Image.Resampling.LANCZOS)
    ox = (size - icon.width) // 2
    oy = (size - icon.height) // 2 + 2
    canvas.alpha_composite(icon, (ox, oy))

    draw = ImageDraw.Draw(canvas)
    _spark_stars(draw, size * 0.5, size * 0.46)
    draw.ellipse((ox - 2, oy + icon.height - 4, ox + icon.width + 2, oy + icon.height + 2), fill=(0, 0, 0, 35))

    if tint is not None:
        tint_layer = Image.new("RGBA", canvas.size, (*tint, 40))
        canvas = Image.alpha_composite(canvas, tint_layer)

    outline = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    odraw = ImageDraw.Draw(outline)
    odraw.ellipse((8, 8, size - 8, size - 8), outline=INK, width=2)
    canvas = Image.alpha_composite(canvas, outline)

    out = ROOT / out_name
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out, "PNG")
    print(f"wrote {out} ({canvas.size[0]}x{canvas.size[1]})")


def main() -> None:
    make_reveal(MODES / "wings.png", "wings_reveal.png", (180, 220, 255))
    make_reveal(MODES / "magic_boots.png", "boots_reveal.png", (255, 210, 160))
    make_reveal(MODES / "speed_badge.png", "speed_reveal.png", (255, 240, 120))
    make_reveal(MODES / "bubble_shield.png", "shield_reveal.png", (180, 230, 255))
    make_reveal(BADGE, "badge_reveal.png", (255, 220, 80))


if __name__ == "__main__":
    main()
