#!/usr/bin/env python3
"""Generate cowboy-style cave ceiling segments with varied lip heights.

Each segment is opaque rock from the top down to a jagged underside, then
transparent — so fill/sky never shows through below the painted lip.
Attachment seats (flatter shelves) are written to
assets/world/cave_ceiling_segments.json for stalactite placement.
"""

from __future__ import annotations

import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "world"

# Warm cave rock (matches cowboy ink + cave purple floor palette).
INK = (42, 24, 18, 255)
ROCK_MID = (78, 58, 82, 255)
ROCK_LIGHT = (118, 92, 118, 255)
ROCK_DARK = (48, 34, 52, 255)
FLECK = (210, 130, 165, 255)
CRYSTAL = (190, 160, 210, 255)

W = 320
H = 200


def _rock(x: int, y: int, rng: random.Random, shade: float = 1.0) -> tuple[int, int, int, int]:
    n = math.sin(x * 0.11) * 7 + math.cos(y * 0.09) * 6 + math.sin((x + y) * 0.05) * 4
    n += rng.randint(-3, 3)
    base_r = ROCK_MID[0] + int(n)
    base_g = ROCK_MID[1] + int(n * 0.7)
    base_b = ROCK_MID[2] + int(n * 0.9)
    # Slight banding like cowboy saddle leather layers.
    band = 1.0 + 0.06 * math.sin(y * 0.18 + x * 0.02)
    r = int(max(28, min(140, base_r * shade * band)))
    g = int(max(22, min(120, base_g * shade * band)))
    b = int(max(36, min(150, base_b * shade * band)))
    return (r, g, b, 255)


def _lip_profile(kind: str, x: int, w: int) -> float:
    """Return underside y (pixels from top) for column x."""
    t = x / max(1, w - 1)
    if kind == "shallow":
        # High lip — more headroom below.
        base = 96.0
        wave = 10.0 * math.sin(t * math.tau * 1.2 + 0.3) + 6.0 * math.sin(t * math.tau * 2.7)
        dips = 8.0 * math.sin(t * math.tau * 0.5 + 1.1) ** 2
        return base + wave + dips
    if kind == "mid":
        base = 124.0
        wave = 14.0 * math.sin(t * math.tau * 1.0 + 0.8) + 8.0 * math.cos(t * math.tau * 2.1)
        dips = 12.0 * abs(math.sin(t * math.tau * 0.75))
        return base + wave + dips
    if kind == "deep":
        # Long hanging slabs.
        base = 148.0
        wave = 12.0 * math.sin(t * math.tau * 0.9) + 10.0 * math.sin(t * math.tau * 2.4 + 0.5)
        dips = 18.0 * (0.5 + 0.5 * math.sin(t * math.tau * 1.15 + 0.2))
        return base + wave + dips
    # mixed: starts shallow, drops mid, rises
    base = 110.0
    wave = 22.0 * math.sin(t * math.pi) + 8.0 * math.sin(t * math.tau * 2.0 + 1.4)
    return base + wave


def _attach_seats(kind: str, w: int) -> list[dict]:
    """Local flat shelves where stalactites sit flush (x centered in segment)."""
    if kind == "shallow":
        xs = [70, 250]
    elif kind == "mid":
        xs = [55, 160, 275]
    elif kind == "deep":
        xs = [90, 230]
    else:
        xs = [100, 220]
    seats: list[dict] = []
    for x in xs:
        y = _lip_profile(kind, x, w)
        # Flatten neighborhood for a stable crown seat.
        seats.append({"x": x, "y": round(y, 1)})
    return seats


def _draw_segment(kind: str, seed: int) -> tuple[Image.Image, list[dict]]:
    rng = random.Random(seed)
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    seats = _attach_seats(kind, W)
    seat_xs = {int(s["x"]) for s in seats}

    # Build lip y per column; flatten around attach seats.
    lip = [_lip_profile(kind, x, W) for x in range(W)]
    for sx in seat_xs:
        flat = lip[sx]
        for dx in range(-14, 15):
            xx = sx + dx
            if 0 <= xx < W:
                blend = 1.0 - abs(dx) / 14.0
                lip[xx] = lip[xx] * (1.0 - blend) + flat * blend
                # Slight upward shelf so the tooth crown tucks under the rock.
                lip[xx] -= 1.5 * blend

    for x in range(W):
        edge = int(round(lip[x]))
        edge = max(40, min(H - 4, edge))
        for y in range(0, edge + 1):
            # Darker near underside lip; lighter mid-body.
            depth = y / max(1, edge)
            shade = 0.78 + 0.28 * (1.0 - abs(depth - 0.35))
            if y >= edge - 3:
                shade *= 0.72
            col = _rock(x, y, rng, shade)
            px[x, y] = col

    # Thick cowboy ink outline along the underside (and soft top rim).
    for x in range(W):
        edge = int(round(lip[x]))
        edge = max(40, min(H - 4, edge))
        for t in range(0, 3):
            yy = edge - t
            if 0 <= yy < H and px[x, yy][3] > 0:
                fade = 1.0 - t * 0.28
                px[x, yy] = (
                    int(INK[0] * fade + px[x, yy][0] * (1 - fade)),
                    int(INK[1] * fade + px[x, yy][1] * (1 - fade)),
                    int(INK[2] * fade + px[x, yy][2] * (1 - fade)),
                    255,
                )
        # Tiny highlight just above the ink for a hand-painted rim.
        hi = edge - 4
        if hi >= 0 and px[x, hi][3] > 0:
            r, g, b, _a = px[x, hi]
            px[x, hi] = (min(255, r + 28), min(255, g + 18), min(255, b + 22), 255)

    # Side seams: slight darken so abutting tiles read as painted slabs.
    for y in range(H):
        for x in (0, 1, W - 2, W - 1):
            if px[x, y][3] > 0:
                r, g, b, a = px[x, y]
                px[x, y] = (max(20, r - 18), max(16, g - 18), max(24, b - 14), a)

    # Mineral flecks + crystal sparkles (cowboy stipple).
    for _ in range(90):
        x = rng.randint(4, W - 5)
        y = rng.randint(6, int(lip[x]) - 8)
        if px[x, y][3] < 200:
            continue
        col = FLECK if rng.random() < 0.7 else CRYSTAL
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H and px[nx, ny][3] >= 200:
                    if abs(dx) + abs(dy) <= 1 or rng.random() < 0.35:
                        px[nx, ny] = col

    # Soft chalk grain overlay on rock only.
    grain = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gpx = grain.load()
    for y in range(H):
        for x in range(W):
            if px[x, y][3] < 200:
                continue
            if rng.random() < 0.08:
                gpx[x, y] = (255, 230, 210, 18)
    im = Image.alpha_composite(im, grain)

    # Hand-drawn slab seams (cowboy brush strokes).
    draw = ImageDraw.Draw(im)
    for i in range(5):
        y0 = 18 + i * 22 + rng.randint(-4, 4)
        pts = []
        for x in range(0, W, 18):
            if px[min(W - 1, x), min(H - 1, y0)][3] < 200:
                continue
            pts.append((x, y0 + int(3 * math.sin(x * 0.04 + i))))
        if len(pts) >= 2:
            draw.line(pts, fill=(55, 32, 28, 160), width=2)

    # Mark attach shelves with a subtle darker notch so teeth tuck under.
    for seat in seats:
        sx = int(seat["x"])
        sy = int(round(lip[sx])) - 2
        draw.ellipse((sx - 10, sy - 4, sx + 10, sy + 3), outline=INK, width=2)

    # Refresh seat y from flattened lip.
    for seat in seats:
        sx = int(seat["x"])
        seat["y"] = round(lip[sx], 1)

    return im, seats


def make_fill() -> None:
    """Opaque rock fill used only ABOVE segment tops (never below the lip art)."""
    rng = random.Random(61)
    w, h = 256, 128
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    for y in range(h):
        for x in range(w):
            px[x, y] = _rock(x, y, rng, 0.86 + 0.1 * (y / max(1, h - 1)))
    for _ in range(50):
        x = rng.randint(2, w - 3)
        y = rng.randint(2, h - 3)
        px[x, y] = FLECK
    _save(im, OUT / "cave_ceiling_fill.png")
    print(f"cave_ceiling_fill: {im.size}")


def _save(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    print(f"wrote {path.relative_to(ROOT)} {im.size}")


def main() -> int:
    make_fill()
    catalog: dict = {"tile_width": W, "tile_height": H, "segments": []}
    kinds = [
        ("a", "shallow", 11),
        ("b", "mid", 22),
        ("c", "deep", 33),
        ("d", "mixed", 44),
        ("e", "mid", 55),
        ("f", "shallow", 66),
    ]
    # Keep legacy single-tile name as a mid segment for any old references.
    legacy = None
    for key, kind, seed in kinds:
        im, seats = _draw_segment(kind, seed)
        name = f"cave_ceiling_seg_{key}.png"
        path = OUT / name
        _save(im, path)
        entry = {"file": name, "kind": kind, "attach": seats}
        catalog["segments"].append(entry)
        if kind == "mid" and legacy is None:
            legacy = im.copy()
            # Also write as cave_ceiling_tile.png for LevelStyle.ceiling_path fallback.
            _save(im, OUT / "cave_ceiling_tile.png")

    meta_path = OUT / "cave_ceiling_segments.json"
    meta_path.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {meta_path.relative_to(ROOT)} ({len(catalog['segments'])} segments)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
