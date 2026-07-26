#!/usr/bin/env python3
"""Build mounted cowgirl horse sprites via conservative in-place rider edits."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
WORLD = ROOT / "assets" / "world"

FRAME_EDITS = {
    "cowboy_horse_ride_0.png": {
        "left": ((154, 35), (146, 55), (140, 82)),
        "right": ((192, 35), (200, 55), (206, 82)),
    },
    "cowboy_horse_ride_1.png": {
        "left": ((152, 35), (144, 57), (138, 84)),
        "right": ((190, 35), (198, 57), (204, 84)),
    },
    "cowboy_horse_jump.png": {
        "left": ((150, 31), (142, 52), (136, 76)),
        "right": ((188, 31), (196, 52), (202, 76)),
    },
}


def _is_rider_pants(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and b > 85 and b > r and g > 65


def _is_hair(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and 45 < r < 150 and 35 < g < 95 and 20 < b < 80 and r > g + 10 and r > b + 15


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


def _sample_palette(img: Image.Image) -> tuple[tuple[int, int, int, int], tuple[int, int, int, int], tuple[int, int, int, int], tuple[int, int, int, int]]:
    px = img.load()
    hair: list[tuple[int, int, int, int]] = []
    red: list[tuple[int, int, int, int]] = []
    pants: list[tuple[int, int, int, int]] = []
    for y in range(18, 100):
        for x in range(145, 200):
            r, g, b, a = px[x, y]
            if _is_hair(r, g, b, a):
                hair.append((r, g, b, a))
            elif _is_rider_pants(r, g, b, a):
                pants.append((r, g, b, a))
            elif a > 40 and r > 150 and g < 90 and b < 90:
                red.append((r, g, b, a))
    hair_base = _avg(hair) if hair else (92, 52, 26, 255)
    denim = _avg(pants) if pants else (78, 118, 168, 255)
    ribbon = _avg(red) if red else (208, 48, 38, 255)
    return hair_base, _shade(hair_base, 0.78), ribbon, denim


def _trim_side_hair(px, w: int, h: int) -> None:
    for y in range(24, 38):
        for x in range(145, 220):
            r, g, b, a = px[x, y]
            if a < 40 or not _is_hair(r, g, b, a):
                continue
            if x < 156 or x > 190:
                px[x, y] = (0, 0, 0, 0)


def _curve_points(anchors: tuple[tuple[int, int], tuple[int, int], tuple[int, int]], steps: int = 16) -> list[tuple[int, int]]:
    a, b, c = anchors
    points: list[tuple[int, int]] = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = int(u * u * a[0] + 2 * u * t * b[0] + t * t * c[0])
        y = int(u * u * a[1] + 2 * u * t * b[1] + t * t * c[1])
        points.append((x, y))
    return points


def _draw_pigtail(
    draw: ImageDraw.ImageDraw,
    anchors: tuple[tuple[int, int], tuple[int, int], tuple[int, int]],
    hair_base: tuple[int, int, int, int],
    hair_dark: tuple[int, int, int, int],
) -> None:
    points = _curve_points(anchors)
    draw.line(points, fill=hair_dark[:3], width=8, joint="curve")
    draw.line(points, fill=hair_base[:3], width=5, joint="curve")
    draw.line(points, fill=_shade(hair_base, 1.08)[:3], width=2, joint="curve")


def _draw_ribbon(draw: ImageDraw.ImageDraw, center: tuple[int, int], ribbon: tuple[int, int, int, int]) -> None:
    x, y = center
    draw.ellipse((x - 8, y - 5, x + 8, y + 5), fill=ribbon[:3])
    draw.ellipse((x - 5, y - 3, x + 5, y + 3), fill=_shade(ribbon, 1.12)[:3])


def _is_skin(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and r > 175 and g > 120 and b > 90


def _mounted_skirt_drape(img: Image.Image, denim: tuple[int, int, int, int], denim_dark: tuple[int, int, int, int]) -> None:
    px = img.load()
    w, h = img.size
    for y in range(78, 88):
        progress = (y - 78) / 10.0
        panels = (
            range(int(136 - progress * 6), int(152 - progress * 2)),
            range(int(194 + progress * 2), int(210 + progress * 6)),
        )
        for x_range in panels:
            for x in x_range:
                if not (0 <= x < w and 0 <= y < h):
                    continue
                r, g, b, a = px[x, y]
                if a < 40 or not _is_skin(r, g, b, a):
                    continue
                px[x, y] = denim_dark if x < 150 else denim


def _mounted_skirt(img: Image.Image, denim: tuple[int, int, int, int], denim_dark: tuple[int, int, int, int]) -> None:
    px = img.load()
    w, h = img.size
    for y in range(84, 100):
        row: list[int] = []
        for x in range(130, 210):
            r, g, b, a = px[x, y]
            if _is_rider_pants(r, g, b, a):
                row.append(x)
        if len(row) < 3:
            continue
        left = min(row)
        right = max(row)
        flare = int((y - 84) / 16 * 20)
        skirt_left = max(124, left - 8 - flare // 2)
        skirt_right = min(w - 1, right + 8 + flare // 2)
        for x in range(skirt_left, skirt_right + 1):
            r, g, b, a = px[x, y]
            if a < 40:
                continue
            if _is_rider_pants(r, g, b, a):
                t = (x - skirt_left) / max(1, skirt_right - skirt_left)
                px[x, y] = denim_dark if t < 0.18 or t > 0.82 else denim


def transform_horse(src: Path, dst: Path) -> None:
    img = Image.open(src).convert("RGBA")
    hair_base, hair_dark, ribbon, denim = _sample_palette(img)
    px = img.load()
    _trim_side_hair(px, img.width, img.height)
    draw = ImageDraw.Draw(img)
    edits = FRAME_EDITS[src.name]
    _draw_pigtail(draw, edits["left"], hair_base, hair_dark)
    _draw_pigtail(draw, edits["right"], hair_base, hair_dark)
    _draw_ribbon(draw, edits["left"][0], ribbon)
    _draw_ribbon(draw, edits["right"][0], ribbon)
    _mounted_skirt_drape(img, denim, _shade(denim, 0.78))
    _mounted_skirt(img, denim, _shade(denim, 0.78))
    img.save(dst)
    print(f"wrote {dst}")


def main() -> None:
    for cowboy_name in FRAME_EDITS:
        out_name = cowboy_name.replace("cowboy_", "cowgirl_")
        transform_horse(WORLD / cowboy_name, WORLD / out_name)


if __name__ == "__main__":
    main()
