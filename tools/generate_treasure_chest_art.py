#!/usr/bin/env python3
"""Generate hand-painted western treasure chest PNGs at 0.75× player height."""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1] / "assets" / "world"

PLAYER_HEIGHT = 44.0
HEIGHT_RATIO = 0.75
CHEST_HEIGHT = PLAYER_HEIGHT * HEIGHT_RATIO
BASE_CLOSED_HEIGHT = 56.0
ART_SCALE = CHEST_HEIGHT / BASE_CLOSED_HEIGHT
# Supersample for weathered wood/brass detail, then downscale to game pixel size.
SUPER_SAMPLE = 2.0

# High-contrast western palette — darker wood + bright brass so the chest reads on sand.
INK = (32, 14, 4, 255)
WOOD = (118, 62, 22, 255)
WOOD_DARK = (68, 34, 10, 255)
WOOD_LIGHT = (162, 102, 48, 255)
WOOD_GRAIN = (52, 26, 8, 200)
BRASS = (228, 178, 38, 255)
BRASS_DARK = (148, 98, 18, 255)
BRASS_LIGHT = (255, 228, 88, 255)
GLOW = (255, 210, 72, 255)
TREASURE = (255, 228, 96, 255)
NAIL = (72, 38, 14, 220)


def _s(value: float) -> float:
    return value * ART_SCALE * SUPER_SAMPLE


def _downscale(img: Image.Image, design_w: float, design_h: float) -> Image.Image:
    target = (
        max(1, int(round(design_w * ART_SCALE))),
        max(1, int(round(design_h * ART_SCALE))),
    )
    if img.size == target:
        return img
    return img.resize(target, Image.Resampling.LANCZOS)


def _noise_seed(seed: int) -> None:
    random.seed(seed)


def _lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def _draw_wood_planks(
    draw: ImageDraw.ImageDraw,
    box: tuple[float, float, float, float],
    plank_count: int = 5,
) -> None:
    x0, y0, x1, y1 = box
    w = x1 - x0
    for i in range(plank_count):
        px0 = x0 + i * (w / plank_count)
        px1 = x0 + (i + 1) * (w / plank_count) + (1.0 if i < plank_count - 1 else 0.0)
        pts = [
            (px0 + (0.8 if i % 2 else -0.5), y0 + (1.4 if i % 2 else -0.9)),
            (px1 + (-0.6 if i % 2 else 0.4), y0 + (-0.7 if i % 2 else 1.0)),
            (px1 + (1.0 if i % 2 else -0.3), y1 + (0.6 if i % 2 else -0.8)),
            (px0 + (-0.4 if i % 2 else 0.7), y1 + (-0.5 if i % 2 else 0.7)),
        ]
        tone = WOOD if i % 2 == 0 else WOOD_LIGHT
        draw.polygon(pts, fill=tone)
        for gy in range(int(y0 + 4), int(y1 - 3), max(2, int(5 * _s(1.0)))):
            gx = px0 + 3 + (gy % 7)
            draw.line(
                [(gx, gy), (px1 - 3, gy + (1 if i % 2 else -1))],
                fill=WOOD_GRAIN,
                width=max(1, int(round(1.5 * ART_SCALE * SUPER_SAMPLE))),
            )
        draw.line(pts + [pts[0]], fill=INK, width=max(1, int(round(3.2 * ART_SCALE * SUPER_SAMPLE))))
        for ny in range(int(y0 + 8), int(y1 - 6), max(6, int(14 * ART_SCALE * SUPER_SAMPLE))):
            nx = px0 + (3 if i % 2 else 5)
            r = max(1, int(round(1.8 * ART_SCALE * SUPER_SAMPLE)))
            draw.ellipse((nx - r, ny - r, nx + r, ny + r), fill=NAIL)
            draw.point((nx - 0.5, ny - 0.5), fill=BRASS_LIGHT)


def _draw_brass_band(
    draw: ImageDraw.ImageDraw,
    x: float,
    y0: float,
    y1: float,
    width: float = 7.0,
) -> None:
    width *= ART_SCALE * SUPER_SAMPLE
    draw.rectangle((x - width * 0.5, y0, x + width * 0.5, y1), fill=BRASS_DARK)
    draw.rectangle((x - width * 0.35, y0 + 1, x + width * 0.35, y1 - 1), fill=BRASS)
    draw.line(
        [(x - width * 0.25, y0 + 2), (x - width * 0.25, y1 - 2)],
        fill=BRASS_LIGHT,
        width=max(1, int(round(1.5 * ART_SCALE * SUPER_SAMPLE))),
    )
    for ry in (y0 + 6, y0 + (y1 - y0) * 0.5, y1 - 6):
        r = 2.6 * ART_SCALE * SUPER_SAMPLE
        draw.ellipse((x - r, ry - r, x + r, ry + r), fill=BRASS_LIGHT)
        draw.ellipse((x - r * 0.55, ry - r * 0.55, x + r * 0.35, ry + r * 0.35), fill=BRASS)
        draw.point((x - 0.8, ry - 0.8), fill=INK)


def _draw_lock_plate(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    sx, sy = _s(10), _s(11)
    draw.rounded_rectangle(
        (cx - sx, cy - sy, cx + sx, cy + sy * 1.2),
        radius=max(1, int(_s(3.5))),
        fill=BRASS_DARK,
    )
    draw.rounded_rectangle(
        (cx - sx * 0.78, cy - sy * 0.8, cx + sx * 0.78, cy + sy),
        radius=max(1, int(_s(2.5))),
        fill=BRASS,
    )
    draw.arc(
        (cx - _s(4.5), cy - _s(2.5), cx + _s(4.5), cy + _s(6.5)),
        start=0,
        end=180,
        fill=INK,
        width=max(1, int(_s(2.5))),
    )
    draw.ellipse((cx - _s(1.8), cy + _s(5.5), cx + _s(1.8), cy + _s(8.5)), fill=INK)


def _soft_glow_layer(size: tuple[int, int]) -> Image.Image:
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size[0] * 0.5, size[1] * 0.35
    for radius, alpha in ((42, 28), (28, 48), (16, 72)):
        rr = radius * ART_SCALE * SUPER_SAMPLE
        draw.ellipse(
            (cx - rr, cy - rr * 0.6, cx + rr, cy + rr * 0.6),
            fill=(GLOW[0], GLOW[1], GLOW[2], alpha),
        )
    return img.filter(ImageFilter.GaussianBlur(radius=max(1, int(round(4 * ART_SCALE * SUPER_SAMPLE)))))


def make_body() -> Image.Image:
    _noise_seed(42)
    w, h = int(round(80 * ART_SCALE * SUPER_SAMPLE)), int(round(52 * ART_SCALE * SUPER_SAMPLE))
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    shadow = [
        (_s(6), h - _s(6)),
        (w - _s(6), h - _s(6)),
        (w - _s(2), h - _s(2)),
        (_s(2), h - _s(2)),
    ]
    draw.polygon(shadow, fill=(0, 0, 0, 48))

    body_box = (_s(8.0), _s(18.0), w - _s(8.0), h - _s(8.0))
    _draw_wood_planks(draw, body_box, plank_count=5)

    x0, y0, x1, y1 = body_box
    for bx in (x0 + _s(12), (x0 + x1) * 0.5, x1 - _s(12)):
        _draw_brass_band(draw, bx, y0 - 1, y1 + 1)

    _draw_lock_plate(draw, (x0 + x1) * 0.5, y0 + _s(14))

    draw.line([(x0 + 2, y1 - 1), (x0 + 10, y1 + 1)], fill=WOOD_DARK, width=max(1, int(_s(2.5))))
    draw.line([(x1 - 11, y1), (x1 - 3, y1 + 1)], fill=WOOD_LIGHT, width=max(1, int(_s(1.5))))
    draw.line([(x0 + 1, y0), (x1 - 1, y0 - 1)], fill=INK, width=max(1, int(_s(2.5))))
    draw.line([(x0 + 3, y0 + 2), (x1 - 4, y0 + 1)], fill=WOOD_LIGHT, width=max(1, int(_s(1.5))))

    return _downscale(img, 80.0, 52.0)


def make_lid() -> Image.Image:
    _noise_seed(77)
    w, h = int(round(80 * ART_SCALE * SUPER_SAMPLE)), int(round(36 * ART_SCALE * SUPER_SAMPLE))
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    lid_pts = [
        (_s(4), h - _s(6)),
        (w - _s(6), h - _s(5)),
        (w - _s(4), _s(10)),
        (_s(22), _s(4)),
        (_s(6), _s(8)),
    ]
    draw.polygon(lid_pts, fill=WOOD_DARK)
    draw.line(lid_pts + [lid_pts[0]], fill=INK, width=max(1, int(_s(3.2))))

    for i, y in enumerate(range(int(_s(10)), h - int(_s(6)), max(2, int(_s(5))))):
        x_start = _s(8) + (i % 2)
        x_end = w - _s(8) - (i % 3)
        draw.line(
            [(x_start, y), (x_end, y + (1 if i % 2 else -1))],
            fill=WOOD_GRAIN,
            width=max(1, int(_s(1.5))),
        )

    draw.line(
        [(_s(10), _s(12)), (w - _s(12), _s(11))],
        fill=WOOD_LIGHT,
        width=max(1, int(_s(2.5))),
    )

    front = [
        (w - _s(6), h - _s(5)),
        (w - _s(4), _s(10)),
        (w - _s(8), _s(11)),
        (w - _s(10), h - _s(6)),
    ]
    draw.polygon(front, fill=BRASS_DARK)
    draw.line(front + [front[0]], fill=INK, width=max(1, int(_s(1.5))))

    return _downscale(img, 80.0, 36.0)


def make_interior() -> Image.Image:
    w, h = int(round(80 * ART_SCALE * SUPER_SAMPLE)), int(round(52 * ART_SCALE * SUPER_SAMPLE))
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    inner_box = (_s(14.0), _s(22.0), w - _s(14.0), h - _s(12.0))
    draw.rounded_rectangle(inner_box, radius=max(1, int(_s(3.5))), fill=(32, 16, 6, 220))

    for ox, oy, r in [
        (0, 0, 5),
        (-10, 4, 4),
        (12, 2, 4),
        (-4, 8, 3),
        (8, 10, 3),
    ]:
        cx = w * 0.5 + _s(ox)
        cy = _s(30 + oy)
        rr = _s(r)
        draw.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=TREASURE)
        draw.ellipse((cx - rr * 0.4, cy - rr * 0.5, cx, cy), fill=(255, 248, 200, 180))

    glow = _soft_glow_layer((w, h))
    img = Image.alpha_composite(img, glow)
    return _downscale(img, 80.0, 52.0)


def make_stamp() -> Image.Image:
    """Compact closed chest icon for the workshop stamp grid."""
    body = make_body()
    lid = make_lid()
    canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    composed = Image.new("RGBA", (body.width, body.height + lid.height // 2), (0, 0, 0, 0))
    composed.alpha_composite(body, (0, max(1, int(round(4 * ART_SCALE)))))
    composed.alpha_composite(lid, (0, 0))
    target_h = int(round(CHEST_HEIGHT * 0.95))
    target_w = int(round(composed.width * (target_h / composed.height)))
    composed = composed.resize((max(32, target_w), max(24, target_h)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(composed, (max(0, (64 - composed.width) // 2), 64 - composed.height - 6))
    draw = ImageDraw.Draw(canvas)
    sx = 64 - 14
    draw.ellipse((sx, 12, sx + 8, 20), fill=(255, 230, 120, 180))
    draw.ellipse((sx + 2, 14, sx + 6, 18), fill=(255, 255, 240, 220))
    return canvas


def write_png(img: Image.Image, name: str) -> None:
    path = ROOT / name
    img.save(path, "PNG")
    print(f"wrote {path} ({img.size[0]}x{img.size[1]})")


def main() -> None:
    print(
        f"chest art scale {ART_SCALE:.3f} super {SUPER_SAMPLE:.1f} "
        f"(target height {CHEST_HEIGHT:.2f}px, ratio {HEIGHT_RATIO:.2f})"
    )
    write_png(make_body(), "treasure_chest_body.png")
    write_png(make_lid(), "treasure_chest_lid.png")
    write_png(make_interior(), "treasure_chest_interior.png")
    write_png(make_stamp(), "treasure_chest_stamp.png")


if __name__ == "__main__":
    main()
