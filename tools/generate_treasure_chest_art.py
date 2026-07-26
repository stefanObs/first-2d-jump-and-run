#!/usr/bin/env python3
"""Generate hand-painted western treasure chest PNGs for Cowboy Trail."""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1] / "assets" / "world"

# Palette aligned with trail props (wood plank, camp flagpole, badges).
INK = (56, 26, 10, 255)
WOOD = (158, 96, 48, 255)
WOOD_DARK = (108, 58, 26, 255)
WOOD_LIGHT = (198, 138, 72, 255)
WOOD_GRAIN = (88, 48, 20, 180)
BRASS = (184, 142, 52, 255)
BRASS_DARK = (118, 82, 28, 255)
BRASS_LIGHT = (228, 196, 88, 255)
GLOW = (255, 210, 72, 255)
TREASURE = (255, 228, 96, 255)


def _noise_seed(seed: int) -> None:
    random.seed(seed)


def _lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def _wood_tone(x: float, y: float, base: tuple[int, ...]) -> tuple[int, int, int, int]:
    wave = math.sin(x * 0.09 + y * 0.04) * 8.0 + math.sin(x * 0.23 - y * 0.11) * 5.0
    knot = max(0.0, 1.0 - math.hypot(x - 38.0, y - 22.0) / 14.0) * 18.0
    r = int(_lerp(base[0], WOOD_DARK[0], (wave + knot) / 40.0))
    g = int(_lerp(base[1], WOOD_DARK[1], (wave + knot) / 40.0))
    b = int(_lerp(base[2], WOOD_DARK[2], (wave + knot) / 40.0))
    return (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)), 255)


def _draw_wood_planks(
    draw: ImageDraw.ImageDraw,
    box: tuple[float, float, float, float],
    plank_count: int = 5,
) -> None:
    x0, y0, x1, y1 = box
    w = x1 - x0
    h = y1 - y0
    for i in range(plank_count):
        px0 = x0 + i * (w / plank_count)
        px1 = x0 + (i + 1) * (w / plank_count) + (1.0 if i < plank_count - 1 else 0.0)
        pts = [
            (px0 + (0.6 if i % 2 else -0.4), y0 + (1.2 if i % 2 else -0.8)),
            (px1 + (-0.5 if i % 2 else 0.3), y0 + (-0.6 if i % 2 else 0.9)),
            (px1 + (0.8 if i % 2 else -0.2), y1 + (0.5 if i % 2 else -0.7)),
            (px0 + (-0.3 if i % 2 else 0.6), y1 + (-0.4 if i % 2 else 0.6)),
        ]
        draw.polygon(pts, fill=WOOD)
        # Grain strokes
        for gy in range(int(y0 + 3), int(y1 - 2), 4):
            gx = px0 + 2 + (gy % 5)
            draw.line([(gx, gy), (px1 - 2, gy + (1 if i % 2 else -1))], fill=WOOD_GRAIN, width=1)
        draw.line(pts + [pts[0]], fill=INK, width=2)


def _draw_brass_band(
    draw: ImageDraw.ImageDraw,
    x: float,
    y0: float,
    y1: float,
    width: float = 7.0,
) -> None:
    draw.rectangle((x - width * 0.5, y0, x + width * 0.5, y1), fill=BRASS_DARK)
    draw.rectangle((x - width * 0.35, y0 + 1, x + width * 0.35, y1 - 1), fill=BRASS)
    draw.line([(x - width * 0.25, y0 + 2), (x - width * 0.25, y1 - 2)], fill=BRASS_LIGHT, width=1)
    # Rivets
    for ry in (y0 + 5, y0 + (y1 - y0) * 0.5, y1 - 5):
        draw.ellipse((x - 2.2, ry - 2.2, x + 2.2, ry + 2.2), fill=BRASS_LIGHT)
        draw.point((x - 0.8, ry - 0.8), fill=INK)


def _draw_lock_plate(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    draw.rounded_rectangle((cx - 9, cy - 10, cx + 9, cy + 12), radius=3, fill=BRASS_DARK)
    draw.rounded_rectangle((cx - 7, cy - 8, cx + 7, cy + 10), radius=2, fill=BRASS)
    draw.arc((cx - 4, cy - 2, cx + 4, cy + 6), start=0, end=180, fill=INK, width=2)
    draw.ellipse((cx - 1.5, cy + 5, cx + 1.5, cy + 8), fill=INK)


def _soft_glow_layer(size: tuple[int, int]) -> Image.Image:
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size[0] * 0.5, size[1] * 0.35
    for radius, alpha in ((42, 28), (28, 48), (16, 72)):
        draw.ellipse(
            (cx - radius, cy - radius * 0.6, cx + radius, cy + radius * 0.6),
            fill=(GLOW[0], GLOW[1], GLOW[2], alpha),
        )
    return img.filter(ImageFilter.GaussianBlur(radius=3))


def make_body() -> Image.Image:
    _noise_seed(42)
    w, h = 80, 52
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Ground shadow
    shadow = [
        (6, h - 6), (w - 6, h - 6), (w - 2, h - 2), (2, h - 2),
    ]
    draw.polygon(shadow, fill=(0, 0, 0, 42))

    body_box = (8.0, 18.0, w - 8.0, h - 8.0)
    _draw_wood_planks(draw, body_box, plank_count=5)

    x0, y0, x1, y1 = body_box
    for bx in (x0 + 12, (x0 + x1) * 0.5, x1 - 12):
        _draw_brass_band(draw, bx, y0 - 1, y1 + 1)

    _draw_lock_plate(draw, (x0 + x1) * 0.5, y0 + 14)

    # Weathered edge chips
    draw.line([(x0 + 2, y1 - 1), (x0 + 10, y1 + 1)], fill=WOOD_DARK, width=2)
    draw.line([(x1 - 11, y1), (x1 - 3, y1 + 1)], fill=WOOD_LIGHT, width=1)

    # Top rim where lid meets body
    draw.line([(x0 + 1, y0), (x1 - 1, y0 - 1)], fill=INK, width=2)
    draw.line([(x0 + 3, y0 + 2), (x1 - 4, y0 + 1)], fill=WOOD_LIGHT, width=1)

    return img


def make_lid() -> Image.Image:
    _noise_seed(77)
    w, h = 80, 36
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Curved lid silhouette; hinge at left edge center.
    lid_pts = [
        (4, h - 6),
        (w - 6, h - 5),
        (w - 4, 10),
        (22, 4),
        (6, 8),
    ]
    draw.polygon(lid_pts, fill=WOOD_DARK)
    draw.line(lid_pts + [lid_pts[0]], fill=INK, width=2)

    # Plank lines across lid
    for i, y in enumerate(range(10, h - 6, 5)):
        x_start = 8 + (i % 2)
        x_end = w - 8 - (i % 3)
        draw.line([(x_start, y), (x_end, y + (1 if i % 2 else -1))], fill=WOOD_GRAIN, width=1)

    draw.line([(10, 12), (w - 12, 11)], fill=WOOD_LIGHT, width=2)

    # Brass lip along front edge
    front = [(w - 6, h - 5), (w - 4, 10), (w - 8, 11), (w - 10, h - 6)]
    draw.polygon(front, fill=BRASS_DARK)
    draw.line(front + [front[0]], fill=INK, width=1)

    return img


def make_interior() -> Image.Image:
    w, h = 80, 52
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    inner_box = (14.0, 22.0, w - 14.0, h - 12.0)
    draw.rounded_rectangle(inner_box, radius=3, fill=(32, 16, 6, 220))

    # Gold coins / badge glint pile
    for i, (ox, oy, r) in enumerate(
        [
            (0, 0, 5),
            (-10, 4, 4),
            (12, 2, 4),
            (-4, 8, 3),
            (8, 10, 3),
        ]
    ):
        cx = w * 0.5 + ox
        cy = 30 + oy
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=TREASURE)
        draw.ellipse((cx - r * 0.4, cy - r * 0.5, cx, cy), fill=(255, 248, 200, 180))

    glow = _soft_glow_layer((w, h))
    img = Image.alpha_composite(img, glow)
    return img


def make_stamp() -> Image.Image:
    """Compact closed chest icon for the workshop stamp grid."""
    body = make_body()
    lid = make_lid()
    canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    # Scale down composed chest
    composed = Image.new("RGBA", (80, 56), (0, 0, 0, 0))
    composed.alpha_composite(body, (0, 4))
    composed.alpha_composite(lid, (0, 0))
    composed = composed.resize((58, 40), Image.Resampling.LANCZOS)
    canvas.alpha_composite(composed, (3, 18))
    # Closed sparkle
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((44, 14, 52, 22), fill=(255, 230, 120, 180))
    draw.ellipse((46, 16, 50, 20), fill=(255, 255, 240, 220))
    return canvas


def write_png(img: Image.Image, name: str) -> None:
    path = ROOT / name
    img.save(path, "PNG")
    print(f"wrote {path} ({img.size[0]}x{img.size[1]})")


def main() -> None:
    write_png(make_body(), "treasure_chest_body.png")
    write_png(make_lid(), "treasure_chest_lid.png")
    write_png(make_interior(), "treasure_chest_interior.png")
    write_png(make_stamp(), "treasure_chest_stamp.png")


if __name__ == "__main__":
    main()
