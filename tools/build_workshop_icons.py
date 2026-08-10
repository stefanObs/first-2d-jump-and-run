#!/usr/bin/env python3
"""Build kid-readable workshop action icons (simple western shapes)."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "ui"
SIZE = 96
CX = SIZE // 2
CY = SIZE // 2

INK = (48, 22, 8, 255)
CREAM = (255, 236, 180, 255)
BANDANA = (180, 48, 28, 255)
WOOD = (196, 118, 52, 255)
SKY = (120, 180, 220, 255)
GREEN = (72, 150, 56, 255)


def _canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def _outline_poly(draw: ImageDraw.ImageDraw, pts: list[tuple[float, float]], fill, outline=INK, width=3) -> None:
    draw.polygon(pts, fill=fill, outline=outline)
    draw.line(pts + [pts[0]], fill=outline, width=width)


def icon_back() -> Image.Image:
    img, d = _canvas()
    # Boot / arrow left for "go back".
    arrow = [
        (72, 28), (40, 28), (40, 18), (16, 48), (40, 78), (40, 68), (72, 68),
    ]
    _outline_poly(d, arrow, WOOD)
    d.ellipse((58, 52, 78, 72), fill=INK)
    return img


def icon_edit() -> Image.Image:
    img, d = _canvas()
    # Pencil.
    body = [(28, 70), (58, 22), (72, 32), (42, 80)]
    _outline_poly(d, body, CREAM)
    tip = [(28, 70), (22, 84), (36, 78)]
    _outline_poly(d, tip, BANDANA)
    d.line((58, 22, 72, 32), fill=INK, width=4)
    d.rectangle((54, 24, 66, 34), fill=WOOD)
    return img


def icon_add() -> Image.Image:
    img, d = _canvas()
    # Plus on a trail disk.
    d.ellipse((14, 14, 82, 82), fill=WOOD, outline=INK, width=4)
    d.rectangle((42, 28, 54, 68), fill=CREAM, outline=INK, width=2)
    d.rectangle((28, 42, 68, 54), fill=CREAM, outline=INK, width=2)
    return img


def icon_remove() -> Image.Image:
    img, d = _canvas()
    # Trash can with X lid vibe.
    d.rounded_rectangle((28, 34, 68, 78), radius=6, fill=WOOD, outline=INK, width=3)
    d.rectangle((24, 28, 72, 40), fill=BANDANA, outline=INK, width=3)
    d.line((38, 46, 38, 70), fill=INK, width=3)
    d.line((48, 46, 48, 70), fill=INK, width=3)
    d.line((58, 46, 58, 70), fill=INK, width=3)
    d.line((40, 20, 56, 20), fill=INK, width=4)
    return img


def icon_restore() -> Image.Image:
    img, d = _canvas()
    # Circular undo arrow.
    d.arc((18, 18, 78, 78), start=40, end=300, fill=WOOD, width=12)
    d.arc((18, 18, 78, 78), start=40, end=300, fill=INK, width=4)
    tip = [(70, 22), (86, 38), (62, 42)]
    _outline_poly(d, tip, CREAM)
    return img


def icon_export() -> Image.Image:
    img, d = _canvas()
    # Pack leaving right.
    d.rounded_rectangle((18, 28, 58, 72), radius=6, fill=WOOD, outline=INK, width=3)
    d.rectangle((28, 22, 48, 34), fill=BANDANA, outline=INK, width=2)
    arrow = [(56, 36), (82, 48), (56, 60), (56, 52), (44, 52), (44, 44), (56, 44)]
    _outline_poly(d, arrow, CREAM)
    return img


def icon_import() -> Image.Image:
    img, d = _canvas()
    # Pack arriving left into box.
    d.rounded_rectangle((38, 28, 78, 72), radius=6, fill=WOOD, outline=INK, width=3)
    d.rectangle((48, 22, 68, 34), fill=GREEN, outline=INK, width=2)
    arrow = [(40, 36), (14, 48), (40, 60), (40, 52), (52, 52), (52, 44), (40, 44)]
    _outline_poly(d, arrow, CREAM)
    return img


def icon_add_trail() -> Image.Image:
    img, d = _canvas()
    # Path with big plus.
    d.ellipse((10, 50, 34, 74), fill=SKY, outline=INK, width=3)
    d.ellipse((62, 50, 86, 74), fill=SKY, outline=INK, width=3)
    d.line((22, 62, 74, 62), fill=WOOD, width=10)
    d.line((22, 62, 74, 62), fill=INK, width=3)
    d.rectangle((42, 18, 54, 48), fill=CREAM, outline=INK, width=2)
    d.rectangle((30, 28, 66, 40), fill=CREAM, outline=INK, width=2)
    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    mapping = {
        "menu_icon_back.png": icon_back,
        "menu_icon_edit.png": icon_edit,
        "menu_icon_add.png": icon_add,
        "menu_icon_remove.png": icon_remove,
        "menu_icon_restore.png": icon_restore,
        "menu_icon_export.png": icon_export,
        "menu_icon_import.png": icon_import,
        "menu_icon_add_trail.png": icon_add_trail,
    }
    for name, builder in mapping.items():
        builder().save(OUT / name)
        print("wrote", name)


if __name__ == "__main__":
    main()
