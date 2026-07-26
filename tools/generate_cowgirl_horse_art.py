#!/usr/bin/env python3
"""Transform handcrafted cowboy mounted horse sprites into cowgirl versions."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

from generate_cowgirl_player_art import _draw_pigtails, _is_hair, _is_jeans, _jeans_to_skirt, _shade, _avg, _cluster

ROOT = Path(__file__).resolve().parents[1]
WORLD = ROOT / "assets" / "world"

PAIRS = [
    ("cowboy_horse_ride_0.png", "cowgirl_horse_ride_0.png"),
    ("cowboy_horse_ride_1.png", "cowgirl_horse_ride_1.png"),
    ("cowboy_horse_jump.png", "cowgirl_horse_jump.png"),
]


def _rider_jeans_to_skirt(img: Image.Image) -> None:
    """Skirt conversion tuned for the mounted rider's compact leg area."""
    px = img.load()
    w, h = img.size
    rows: dict[int, list[int]] = {}
    jeans_colors: list[tuple[int, int, int, int]] = []
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if _is_jeans(r, g, b, a):
                rows.setdefault(y, []).append(x)
                jeans_colors.append((r, g, b, a))
    if not rows:
        return

    denim = _avg(jeans_colors)
    denim_dark = _shade(denim, 0.78)
    denim_light = _shade(denim, 1.08)
    y_min = min(rows)
    y_max = max(rows)
    for y in range(y_min, y_max + 1):
        xs = rows.get(y, [])
        if len(xs) < 2:
            continue
        clusters = _cluster(xs)
        left = clusters[0][0]
        right = clusters[-1][-1]
        flare = int((y - y_min) / max(1, y_max - y_min) * 3)
        skirt_left = max(0, left - flare // 2)
        skirt_right = min(w - 1, right + 1 + flare)
        for x in range(skirt_left, skirt_right + 1):
            r, g, b, a = px[x, y]
            if a < 20 or _is_jeans(r, g, b, a):
                t = (x - skirt_left) / max(1, skirt_right - skirt_left)
                fill = denim_dark if t < 0.25 or t > 0.75 else denim if t < 0.45 or t > 0.55 else denim_light
                px[x, y] = fill


def _mounted_pigtails(img: Image.Image, swing: float = 0.0) -> None:
    px = img.load()
    w, h = img.size
    hair_colors: list[tuple[int, int, int, int]] = []
    crown_x: list[int] = []
    crown_y = 0
    for y in range(0, min(h, 120)):
        for x in range(w):
            r, g, b, a = px[x, y]
            if _is_hair(r, g, b, a):
                hair_colors.append((r, g, b, a))
                crown_x.append(x)
                crown_y = max(crown_y, y)
    if not crown_x:
        _draw_pigtails(img, swing)
        return

    hair = _avg(hair_colors)
    hair_dark = _shade(hair, 0.82)
    ink = (32, 14, 4, 255)
    cx = sum(crown_x) // len(crown_x)
    cy = max(18, crown_y - 4)
    draw = ImageDraw.Draw(img)
    left = [(cx - 24, cy), (cx - 30 - swing, cy + 10), (cx - 28 - swing, cy + 20), (cx - 24, cy + 14)]
    right = [(cx + 24, cy), (cx + 30 + swing, cy + 10), (cx + 28 + swing, cy + 20), (cx + 24, cy + 14)]
    for braid in (left, right):
        draw.line(braid, fill=hair_dark, width=6)
        draw.line(braid, fill=hair, width=3)
        draw.ellipse((braid[-1][0] - 3, braid[-1][1] - 3, braid[-1][0] + 3, braid[-1][1] + 3), fill=hair)
    draw.line((cx - 26, cy + 2, cx - 20, cy + 5), fill=ink, width=2)
    draw.line((cx + 26, cy + 2, cx + 20, cy + 5), fill=ink, width=2)


def transform_horse(cowboy_name: str, out_name: str, swing: float = 0.0) -> None:
    src = WORLD / cowboy_name
    out = WORLD / out_name
    img = Image.open(src).convert("RGBA")
    _rider_jeans_to_skirt(img)
    _mounted_pigtails(img, swing)
    img.save(out)
    print(f"wrote {out}")


def main() -> None:
    swings = {
        "cowboy_horse_ride_0.png": 0.0,
        "cowboy_horse_ride_1.png": 1.5,
        "cowboy_horse_jump.png": -2.0,
    }
    for cowboy_name, out_name in PAIRS:
        transform_horse(cowboy_name, out_name, swings.get(cowboy_name, 0.0))


if __name__ == "__main__":
    main()
