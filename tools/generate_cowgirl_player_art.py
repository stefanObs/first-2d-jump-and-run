#!/usr/bin/env python3
"""Transform handcrafted cowboy player sprites into matching cowgirl frames."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "assets" / "player"
COWBOY = ROOT
COWGIRL = ROOT / "cowgirl"

PLAYER_FRAMES = [
    "idle_0.png",
    "idle_1.png",
    "run_0.png",
    "run_1.png",
    "run_2.png",
    "run_3.png",
    "jump.png",
    "celebrate.png",
]


def _is_jeans(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and b > 70 and b > r + 8 and b > g + 5 and g > 45


def _is_hair(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and 45 < r < 180 and g < 110 and b < 95 and r > g and r > b


def _is_ink(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and r < 70 and g < 55 and b < 45


def _avg(colors: list[tuple[int, int, int, int]]) -> tuple[int, int, int, int]:
    if not colors:
        return (70, 110, 170, 255)
    rs = [c[0] for c in colors]
    gs = [c[1] for c in colors]
    bs = [c[2] for c in colors]
    return (sum(rs) // len(rs), sum(gs) // len(gs), sum(bs) // len(bs), 255)


def _shade(color: tuple[int, int, int, int], amount: float) -> tuple[int, int, int, int]:
    return (
        max(0, min(255, int(color[0] * amount))),
        max(0, min(255, int(color[1] * amount))),
        max(0, min(255, int(color[2] * amount))),
        color[3],
    )


def _cluster(values: list[int], gap: int = 4) -> list[list[int]]:
    if not values:
        return []
    values = sorted(set(values))
    groups: list[list[int]] = [[values[0]]]
    for value in values[1:]:
        if value - groups[-1][-1] <= gap:
            groups[-1].append(value)
        else:
            groups.append([value])
    return groups


def _sample_hair_colors(img: Image.Image) -> tuple[tuple[int, int, int, int], tuple[int, int, int, int], tuple[int, int, int, int]]:
    px = img.load()
    w, h = img.size
    hair: list[tuple[int, int, int, int]] = []
    ink: list[tuple[int, int, int, int]] = []
    for y in range(0, min(h, 18)):
        for x in range(w):
            r, g, b, a = px[x, y]
            if _is_hair(r, g, b, a):
                hair.append((r, g, b, a))
            elif _is_ink(r, g, b, a):
                ink.append((r, g, b, a))
    base = _avg(hair)
    return base, _shade(base, 0.82), _avg(ink) if ink else (32, 14, 4, 255)


def _jeans_to_skirt(img: Image.Image) -> None:
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

    base, dark, _ = _sample_hair_colors(img)
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
        if not clusters:
            continue
        left = clusters[0][0]
        right = clusters[-1][-1]
        # Widen slightly into a skirt flare while keeping the cowboy foot column.
        flare = int((y - y_min) / max(1, y_max - y_min) * 4)
        skirt_left = max(0, left - 1 - flare // 2)
        skirt_right = min(w - 1, right + 1 + flare)
        for x in range(skirt_left, skirt_right + 1):
            r, g, b, a = px[x, y]
            if a < 20 or _is_jeans(r, g, b, a):
                t = (x - skirt_left) / max(1, skirt_right - skirt_left)
                fill = denim_dark if t < 0.22 or t > 0.78 else denim if t < 0.45 or t > 0.55 else denim_light
                px[x, y] = fill
        # Re-ink the skirt hem using nearby ink tones.
        for x in (skirt_left, skirt_right):
            if 0 <= x < w and px[x, y][3] > 0:
                edge = _shade(denim_dark, 0.55)
                px[x, y] = (edge[0], edge[1], edge[2], 255)


def _draw_pigtails(img: Image.Image, swing: float = 0.0) -> None:
    px = img.load()
    w, h = img.size
    hair, hair_dark, ink = _sample_hair_colors(img)
    draw = ImageDraw.Draw(img)

    # Find head center from opaque pixels near the crown.
    crown_x: list[int] = []
    for y in range(4, 16):
        for x in range(w):
            if px[x, y][3] > 40:
                crown_x.append(x)
    cx = sum(crown_x) // max(1, len(crown_x)) if crown_x else w // 2

    left_braid = [
        (cx - 14, 8),
        (cx - 18 - swing, 14),
        (cx - 17 - swing, 20),
        (cx - 15 - swing * 0.5, 26),
        (cx - 13, 22),
    ]
    right_braid = [
        (cx + 14, 8),
        (cx + 18 + swing, 14),
        (cx + 17 + swing, 20),
        (cx + 15 + swing * 0.5, 26),
        (cx + 13, 22),
    ]
    for braid in (left_braid, right_braid):
        draw.line(braid, fill=hair_dark, width=4)
        draw.line(braid, fill=hair, width=2)
        draw.ellipse((braid[-1][0] - 2, braid[-1][1] - 2, braid[-1][0] + 2, braid[-1][1] + 2), fill=hair)
    # Small ribbon ties at the hat line.
    draw.line((cx - 15, 10, cx - 11, 12), fill=ink, width=1)
    draw.line((cx + 15, 10, cx + 11, 12), fill=ink, width=1)


def _swing_for_frame(name: str) -> float:
    if "idle_1" in name:
        return 1.5
    if "run_0" in name:
        return -2.0
    if "run_1" in name:
        return 0.0
    if "run_2" in name:
        return 2.0
    if "run_3" in name:
        return 0.5
    if "jump" in name:
        return -2.5
    if "celebrate" in name:
        return 2.5
    return 0.0


def transform_frame(cowboy_path: Path, out_path: Path) -> None:
    img = Image.open(cowboy_path).convert("RGBA")
    _jeans_to_skirt(img)
    _draw_pigtails(img, _swing_for_frame(cowboy_path.name))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)
    print(f"wrote {out_path}")


def generate_all() -> None:
    COWGIRL.mkdir(parents=True, exist_ok=True)
    for name in PLAYER_FRAMES:
        transform_frame(COWBOY / name, COWGIRL / name)
        boots_name = name.replace(".png", "_boots.png")
        transform_frame(COWBOY / boots_name, COWGIRL / boots_name)


if __name__ == "__main__":
    generate_all()
    print(f"Wrote cowgirl frames to {COWGIRL}")
