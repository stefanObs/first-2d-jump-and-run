#!/usr/bin/env python3
"""Build cave_canyon_rim_left.png from the desert ridge silhouette.

Keeps the same full-height cliff shape and jagged sky lip, but remaps the warm
desert rock into cool slate / mauve cave stone with pink mineral flecks so cave
gaps match the rest of the cave biome art.
"""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "world" / "canyon_rim_left.png"
OUT = ROOT / "assets" / "world" / "cave_canyon_rim_left.png"
CRUST_ROWS = 14
OPAQUE_A = 40


def _brightness(r: int, g: int, b: int) -> float:
    return (r + g + b) / 3.0


def _to_cave(r: int, g: int, b: int, a: int, y: int, h: int, crust: bool) -> tuple[int, int, int, int]:
    if a < OPAQUE_A:
        return (0, 0, 0, 0)
    bri = _brightness(r, g, b)
    depth = y / max(1, h - 1)
    if crust:
        # Match cave floor crust — dusty mauve / cool sand.
        n = ((r * 3 + g * 5 + b) % 17) - 8
        return (
            max(70, min(150, int(118 + n + (bri - 120) * 0.15))),
            max(55, min(130, int(92 + n * 0.7 + (bri - 120) * 0.1))),
            max(70, min(150, int(112 + n * 0.8 + (bri - 120) * 0.12))),
            255,
        )
    # Warm desert rock → cool purple slate. Keep relative light/dark for cliffs.
    # Lift near-black desert shadows so the sky lip never frames black.
    t = max(0.0, min(1.0, (bri - 40.0) / 140.0))
    base_r = int(48 + t * 70)
    base_g = int(40 + t * 52)
    base_b = int(62 + t * 78)
    # Deeper rows go a touch darker, still readable slate.
    shade = 1.0 - 0.18 * depth
    n = ((r + g * 2 + y) % 13) - 6
    out_r = max(42, min(140, int(base_r * shade) + n))
    out_g = max(34, min(120, int(base_g * shade) + n // 2))
    out_b = max(52, min(160, int(base_b * shade) + n // 2))
    return (out_r, out_g, out_b, 255)


def build() -> dict:
    if not SRC.exists():
        raise SystemExit(f"missing desert rim: {SRC}")
    im = Image.open(SRC).convert("RGBA")
    w, h = im.size
    px = im.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    opx = out.load()
    lips: list[int] = []
    for y in range(h):
        lip = -1
        for x in range(w - 1, -1, -1):
            if px[x, y][3] > OPAQUE_A:
                lip = x
                break
        lips.append(lip)
        crust = y < CRUST_ROWS
        for x in range(w):
            r, g, b, a = px[x, y]
            opx[x, y] = _to_cave(r, g, b, a, y, h, crust)

    # Pink mineral flecks (match cave floor / ceiling).
    rng = random.Random(77)
    for _ in range(220):
        y = rng.randint(CRUST_ROWS + 4, h - 8)
        lip = lips[y]
        if lip < 12:
            continue
        x = rng.randint(2, max(3, lip - 4))
        if opx[x, y][3] < 200:
            continue
        fleck = (210, 130, 165, 255) if rng.random() < 0.65 else (190, 160, 210, 255)
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and opx[nx, ny][3] >= 200:
                    if abs(dx) + abs(dy) <= 1 or rng.random() < 0.35:
                        opx[nx, ny] = fleck

    # Guarantee sky-facing edge is cool rock, never near-black.
    for y in range(h):
        lip = lips[y]
        if lip < 0:
            continue
        for x in range(max(0, lip - 3), lip + 1):
            r, g, b, a = opx[x, y]
            if a < OPAQUE_A:
                continue
            if _brightness(r, g, b) < 70:
                shade = 0.78 + 0.15 * ((lip - x) / 3.0)
                opx[x, y] = (
                    max(70, min(150, int(96 * shade))),
                    max(55, min(130, int(78 * shade))),
                    max(80, min(160, int(112 * shade))),
                    255,
                )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.save(OUT)
    near_black = 0
    outer_dark = 0
    for y in range(h):
        lip = lips[y]
        if lip < 0:
            continue
        for x in range(max(0, lip - 2), lip + 1):
            r, g, b, a = opx[x, y]
            if a > OPAQUE_A and _brightness(r, g, b) <= 55:
                outer_dark += 1
        for x in range(0, lip + 1):
            r, g, b, a = opx[x, y]
            if a > OPAQUE_A and _brightness(r, g, b) <= 35:
                near_black += 1
    return {
        "path": str(OUT),
        "size": out.size,
        "near_black_body": near_black,
        "outer_dark": outer_dark,
        "rim_lip_tex_x": float(max(lips)),
    }


if __name__ == "__main__":
    info = build()
    print(info)
