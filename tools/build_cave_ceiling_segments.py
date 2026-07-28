#!/usr/bin/env python3
"""Generate cave ceiling panels with fixed low/high side heights.

Each panel locks its left and right lip edges to either LOW or HIGH so adjacent
panels can only pair when heights match (end of A == start of B).

Catalog layout (3 variants each):
  low→low, low→high, high→low, high→high
"""

from __future__ import annotations

import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "world"

ROCK_MID = (78, 58, 82, 255)
FLECK = (210, 130, 165, 255)
CRYSTAL = (190, 160, 210, 255)

W = 320
H = 200
# Fixed side lip depths (pixels from top of the panel). High = hangs lower.
LOW_Y = 108.0
HIGH_Y = 156.0
EDGE_FLAT = 18  # columns kept flat at each side for clean seams


def _rock(x: int, y: int, rng: random.Random, shade: float = 1.0) -> tuple[int, int, int, int]:
    n = math.sin(x * 0.11) * 7 + math.cos(y * 0.09) * 6 + math.sin((x + y) * 0.05) * 4
    n += rng.randint(-3, 3)
    base_r = ROCK_MID[0] + int(n)
    base_g = ROCK_MID[1] + int(n * 0.7)
    base_b = ROCK_MID[2] + int(n * 0.9)
    band = 1.0 + 0.06 * math.sin(y * 0.18 + x * 0.02)
    r = int(max(28, min(140, base_r * shade * band)))
    g = int(max(22, min(120, base_g * shade * band)))
    b = int(max(36, min(150, base_b * shade * band)))
    return (r, g, b, 255)


def _side_y(side: str) -> float:
    return HIGH_Y if side == "high" else LOW_Y


def _lip_profile(start: str, end: str, x: int, w: int, seed: int) -> float:
    """Smooth lip from fixed start height to fixed end height with mid variation."""
    t = x / max(1, w - 1)
    y0 = _side_y(start)
    y1 = _side_y(end)
    # Hermite-ish blend so sides stay locked.
    if x < EDGE_FLAT:
        return y0
    if x >= w - EDGE_FLAT:
        return y1
    u = (x - EDGE_FLAT) / max(1, (w - 1 - 2 * EDGE_FLAT))
    u = u * u * (3.0 - 2.0 * u)
    base = y0 + (y1 - y0) * u
    # Mid wobble that dies out near the fixed edges.
    edge_fade = math.sin(math.pi * u)
    rng = random.Random(seed + x * 17)
    wobble = (
        10.0 * math.sin(u * math.tau * 1.15 + seed * 0.3)
        + 6.0 * math.sin(u * math.tau * 2.4 + seed * 0.7)
        + rng.uniform(-1.5, 1.5)
    )
    return base + wobble * edge_fade


def _attach_seats(start: str, end: str, w: int, seed: int) -> list[dict]:
    """One or two mid seats away from the flat side seams."""
    xs = [90, 230] if (start == end) else [110, 210]
    if seed % 3 == 2:
        xs = [160] if start != end else [100, 220]
    seats: list[dict] = []
    for x in xs:
        y = _lip_profile(start, end, x, w, seed)
        seats.append({"x": x, "y": round(y, 1)})
    return seats


def _draw_segment(start: str, end: str, seed: int) -> tuple[Image.Image, list[dict]]:
    rng = random.Random(seed)
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    seats = _attach_seats(start, end, W, seed)
    seat_xs = {int(s["x"]) for s in seats}

    lip = [_lip_profile(start, end, x, W, seed) for x in range(W)]
    # Flatten shelves at attach seats so teeth tuck under.
    for sx in seat_xs:
        flat = lip[sx]
        for dx in range(-12, 13):
            xx = sx + dx
            if 0 <= xx < W:
                blend = 1.0 - abs(dx) / 12.0
                lip[xx] = lip[xx] * (1.0 - blend) + flat * blend
                lip[xx] -= 1.2 * blend

    # Re-lock exact side columns after seat smoothing.
    for x in range(EDGE_FLAT):
        lip[x] = _side_y(start)
    for x in range(W - EDGE_FLAT, W):
        lip[x] = _side_y(end)

    for x in range(W):
        edge = int(round(max(40.0, min(H - 4.0, lip[x]))))
        for y in range(0, edge + 1):
            depth = y / max(1, edge)
            shade = 0.78 + 0.28 * (1.0 - abs(depth - 0.35))
            # Soft underside only — no ink/black outline framing the lip.
            if y >= edge - 2:
                shade *= 0.88
            px[x, y] = _rock(x, y, rng, shade)
        # Gentle highlight just above the lip (reads as rock, not a black border).
        hi = edge - 3
        if hi >= 0 and px[x, hi][3] > 0:
            r, g, b, _a = px[x, hi]
            px[x, hi] = (min(255, r + 22), min(255, g + 14), min(255, b + 18), 255)

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

    grain = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gpx = grain.load()
    for y in range(H):
        for x in range(W):
            if px[x, y][3] < 200:
                continue
            if rng.random() < 0.08:
                gpx[x, y] = (255, 230, 210, 18)
    im = Image.alpha_composite(im, grain)
    px = im.load()

    draw = ImageDraw.Draw(im)
    for i in range(5):
        y0 = 18 + i * 22 + rng.randint(-4, 4)
        pts = []
        for x in range(0, W, 18):
            if px[min(W - 1, x), min(H - 1, y0)][3] < 200:
                continue
            pts.append((x, y0 + int(3 * math.sin(x * 0.04 + i))))
        if len(pts) >= 2:
            # Soft mauve strata — not black ink strokes.
            draw.line(pts, fill=(72, 48, 68, 120), width=2)
    px = im.load()

    # Built-in fused tooth nubs at seats (blend with rock until gameplay tooth releases).
    for seat in seats:
        sx = int(seat["x"])
        sy = int(round(lip[sx]))
        for dy in range(0, 22):
            half = max(1.0, 9.0 * (1.0 - dy / 22.0) ** 0.85)
            for dx in range(-int(half) - 1, int(half) + 2):
                xx, yy = sx + dx, sy + dy
                if not (0 <= xx < W and 0 <= yy < H):
                    continue
                if abs(dx) > half:
                    continue
                edge = half - abs(dx)
                shade = 0.78 + 0.18 * (edge / max(1.0, half))
                col = _rock(xx, yy, rng, shade)
                if edge <= 1.0 or dy >= 20:
                    # Soften tip only — keep readable rock, never black outline.
                    col = (
                        max(48, col[0] - 10),
                        max(36, col[1] - 10),
                        max(52, col[2] - 8),
                        255,
                    )
                px[xx, yy] = col
        seat["y"] = round(lip[sx], 1)

    for seat in seats:
        sx = int(seat["x"])
        seat["y"] = round(lip[sx], 1)

    # Final lift: no near-black border on the underside lip or panel sides.
    for x in range(W):
        edge = int(round(max(40.0, min(H - 4.0, lip[x]))))
        for yy in range(max(0, edge - 3), edge + 1):
            r, g, b, a = px[x, yy]
            if a < 20:
                continue
            if (r + g + b) / 3.0 < 58:
                px[x, yy] = (
                    max(58, min(140, r + 28)),
                    max(44, min(120, g + 22)),
                    max(62, min(150, b + 26)),
                    255,
                )
    for y in range(H):
        for x in (0, 1, W - 2, W - 1):
            r, g, b, a = px[x, y]
            if a < 20:
                continue
            if (r + g + b) / 3.0 < 58:
                px[x, y] = (
                    max(58, min(140, r + 24)),
                    max(44, min(120, g + 18)),
                    max(62, min(150, b + 22)),
                    255,
                )

    return im, seats


def make_fill() -> None:
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


def _save(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    print(f"wrote {path.relative_to(ROOT)} {im.size}")


def main() -> int:
    # Remove old lettered segments if present.
    for old in OUT.glob("cave_ceiling_seg_*.png"):
        old.unlink()
        print(f"removed {old.name}")

    make_fill()
    catalog: dict = {
        "tile_width": W,
        "tile_height": H,
        "low_y": LOW_Y,
        "high_y": HIGH_Y,
        "segments": [],
        "by_start": {"low": [], "high": []},
    }
    combos = [
        ("low", "low"),
        ("low", "high"),
        ("high", "low"),
        ("high", "high"),
    ]
    legacy = None
    for start, end in combos:
        for variant in range(3):
            seed = 100 + variant * 17 + (0 if start == "low" else 50) + (0 if end == "low" else 90)
            im, seats = _draw_segment(start, end, seed)
            name = f"cave_ceiling_{start[0]}{end[0]}_{variant}.png"
            _save(im, OUT / name)
            entry = {
                "file": name,
                "start": start,
                "end": end,
                "attach": seats,
            }
            catalog["segments"].append(entry)
            catalog["by_start"][start].append(len(catalog["segments"]) - 1)
            if start == "low" and end == "high" and legacy is None:
                legacy = im.copy()
                _save(im, OUT / "cave_ceiling_tile.png")

    if legacy is None and catalog["segments"]:
        first = catalog["segments"][0]["file"]
        _save(Image.open(OUT / first).convert("RGBA"), OUT / "cave_ceiling_tile.png")

    meta_path = OUT / "cave_ceiling_segments.json"
    meta_path.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {meta_path.relative_to(ROOT)} ({len(catalog['segments'])} segments)")
    # Verify side locks.
    for entry in catalog["segments"]:
        im = Image.open(OUT / entry["file"]).convert("RGBA")
        px = im.load()
        def first_clear(col: int) -> int:
            for y in range(H):
                if px[col, y][3] < 20:
                    return y
            return H
        left = first_clear(2)
        right = first_clear(W - 3)
        want_l = int(round(_side_y(entry["start"])))
        want_r = int(round(_side_y(entry["end"])))
        print(
            f"  {entry['file']}: L={left} (want~{want_l}) R={right} (want~{want_r}) "
            f"{entry['start']}→{entry['end']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
