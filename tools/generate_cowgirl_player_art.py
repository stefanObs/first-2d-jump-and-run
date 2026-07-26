#!/usr/bin/env python3
"""Transform handcrafted cowboy player sprites into matching cowgirl frames."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

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


def _avg(colors: list[tuple[int, int, int, int]]) -> tuple[int, int, int, int]:
    if not colors:
        return (98, 58, 28, 255)
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


def _sample_hair_palette(img: Image.Image) -> tuple[tuple[int, int, int, int], tuple[int, int, int, int], tuple[int, int, int, int]]:
    px = img.load()
    w, h = img.size
    hair: list[tuple[int, int, int, int]] = []
    for y in range(0, min(h, 16)):
        for x in range(w):
            r, g, b, a = px[x, y]
            if _is_hair(r, g, b, a):
                hair.append((r, g, b, a))
    base = _avg(hair)
    return base, _shade(base, 0.82), _shade(base, 1.12)


def _sample_bandana(img: Image.Image) -> tuple[int, int, int, int]:
    px = img.load()
    w, h = img.size
    reds: list[tuple[int, int, int, int]] = []
    for y in range(12, min(h, 24)):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 40 and r > 150 and g < 90 and b < 90:
                reds.append((r, g, b, a))
    return _avg(reds) if reds else (208, 48, 38, 255)


def _jeans_to_skirt(img: Image.Image, flare_strength: int = 6) -> None:
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
        flare = int((y - y_min) / max(1, y_max - y_min) * flare_strength)
        skirt_left = max(0, left - 2 - flare // 2)
        skirt_right = min(w - 1, right + 2 + flare // 2)
        for x in range(skirt_left, skirt_right + 1):
            r, g, b, a = px[x, y]
            if a < 20 or _is_jeans(r, g, b, a):
                t = (x - skirt_left) / max(1, skirt_right - skirt_left)
                fill = denim_dark if t < 0.22 or t > 0.78 else denim if t < 0.45 or t > 0.55 else denim_light
                px[x, y] = fill


def _draw_pigtails(img: Image.Image, swing: float = 0.0) -> None:
    px = img.load()
    w, h = img.size
    base, dark, light = _sample_hair_palette(img)
    ribbon = _sample_bandana(img)
    left_x = 20
    right_x = 44
    start_y = 10
    length = 14
    for step in range(length):
        y = start_y + step
        drift = int(swing * step / max(1, length - 1))
        lx = left_x + drift
        rx = right_x + drift
        width = 5 if step < length - 3 else 3 if step < length - 1 else 2
        for i in range(width):
            if 0 <= lx - i < w and 0 <= y < h:
                color = [dark, dark, base, light, base][i]
                if px[lx - i, y][3] < 40 or _is_hair(*px[lx - i, y][:4]):
                    px[lx - i, y] = color
            if 0 <= rx + i < w and 0 <= y < h:
                color = [base, light, base, dark, dark][i]
                if px[rx + i, y][3] < 40 or _is_hair(*px[rx + i, y][:4]):
                    px[rx + i, y] = color
    for bx, by in ((left_x, start_y), (right_x, start_y)):
        if 0 <= bx < w and 0 <= by + 1 < h:
            px[bx, by] = ribbon
            px[bx, by + 1] = _shade(ribbon, 0.85)


def _swing_for_frame(name: str) -> float:
    if "idle_1" in name:
        return 1.0
    if "run_0" in name:
        return -1.5
    if "run_1" in name:
        return 0.0
    if "run_2" in name:
        return 1.5
    if "run_3" in name:
        return 0.5
    if "jump" in name:
        return -2.0
    if "celebrate" in name:
        return 2.0
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
