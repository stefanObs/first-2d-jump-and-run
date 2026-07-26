#!/usr/bin/env python3
"""Generate handcrafted cowgirl player sprites matching the cowboy palette."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "assets" / "player"
COWBOY = ROOT
COWGIRL = ROOT / "cowgirl"

# Western palette aligned with the cowboy frames.
INK = (32, 14, 4, 255)
SKIN = (255, 214, 178, 255)
SKIN_SHADOW = (232, 176, 138, 255)
HAIR = (98, 58, 28, 255)
HAIR_LIGHT = (132, 82, 42, 255)
HAT = (118, 68, 32, 255)
HAT_DARK = (78, 42, 18, 255)
HAT_BAND = (58, 28, 12, 255)
SHIRT = (72, 132, 212, 255)
SHIRT_DARK = (48, 98, 168, 255)
VEST = (88, 48, 22, 255)
VEST_DARK = (58, 28, 12, 255)
BANDANA = (208, 48, 38, 255)
BELT = (88, 48, 22, 255)
BUCKLE = (228, 188, 58, 255)
SKIRT = (58, 98, 168, 255)
SKIRT_DARK = (42, 72, 132, 255)
BOOT = (168, 112, 58, 255)
BOOT_DARK = (118, 72, 32, 255)
BOOT_SOLE = (58, 32, 14, 255)
MAGIC_BOOT = (228, 188, 58, 255)
MAGIC_BOOT_DARK = (168, 128, 28, 255)
MAGIC_SPARK = (255, 240, 120, 255)

SIZE = 64


def _blank() -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def _px(draw: ImageDraw.ImageDraw, x: float, y: float, color: tuple[int, int, int, int], r: float = 1.0) -> None:
    draw.ellipse((x - r, y - r, x + r, y + r), fill=color)


def _line(draw: ImageDraw.ImageDraw, a: tuple[float, float], b: tuple[float, float], color, width: int = 2) -> None:
    draw.line([a, b], fill=color, width=width)


def _poly(draw: ImageDraw.ImageDraw, pts, fill, outline: tuple | None = INK) -> None:
    draw.polygon(pts, fill=fill, outline=outline)


def _outline_ellipse(draw, box, fill, outline=INK, width=2):
    draw.ellipse(box, fill=fill, outline=outline, width=width)


def _draw_hat(draw: ImageDraw.ImageDraw, cx: float, cy: float, tilt: float = 0.0) -> None:
    brim_y = cy + 8
    _poly(
        draw,
        [
            (cx - 18 + tilt, brim_y),
            (cx + 18 + tilt, brim_y),
            (cx + 14 + tilt, brim_y + 4),
            (cx - 14 + tilt, brim_y + 4),
        ],
        HAT,
    )
    _outline_ellipse(draw, (cx - 12 + tilt, cy - 8, cx + 12 + tilt, cy + 10), HAT)
    _outline_ellipse(draw, (cx - 9 + tilt, cy - 2, cx + 9 + tilt, cy + 8), HAT_DARK)
    draw.arc((cx - 10 + tilt, cy + 1, cx + 10 + tilt, cy + 7), 10, 170, fill=HAT_BAND, width=2)


def _draw_pigtails(draw: ImageDraw.ImageDraw, cx: float, cy: float, swing: float = 0.0) -> None:
    left = [(cx - 14, cy - 2), (cx - 20 - swing, cy + 8), (cx - 16 - swing, cy + 18), (cx - 10, cy + 6)]
    right = [(cx + 14, cy - 2), (cx + 20 + swing, cy + 8), (cx + 16 + swing, cy + 18), (cx + 10, cy + 6)]
    _poly(draw, left, HAIR)
    _poly(draw, right, HAIR)
    _px(draw, cx - 18 - swing, cy + 14, HAIR_LIGHT, 2)
    _px(draw, cx + 18 + swing, cy + 14, HAIR_LIGHT, 2)


def _draw_face(draw: ImageDraw.ImageDraw, cx: float, cy: float, mouth_open: bool = False) -> None:
    _outline_ellipse(draw, (cx - 9, cy - 4, cx + 9, cy + 10), SKIN)
    _px(draw, cx - 4, cy + 1, INK, 1.6)
    _px(draw, cx + 4, cy + 1, INK, 1.6)
    _px(draw, cx - 4, cy + 1, (255, 255, 255, 255), 0.7)
    _px(draw, cx + 4, cy + 1, (255, 255, 255, 255), 0.7)
    if mouth_open:
        draw.arc((cx - 4, cy + 4, cx + 4, cy + 10), 10, 170, fill=INK, width=2)
    else:
        draw.arc((cx - 3, cy + 5, cx + 3, cy + 9), 10, 170, fill=INK, width=1)


def _draw_torso(draw: ImageDraw.ImageDraw, cx: float, top: float, arm_swing: float = 0.0) -> None:
    _poly(draw, [(cx - 10, top + 2), (cx + 10, top + 2), (cx + 9, top + 20), (cx - 9, top + 20)], SHIRT)
    _poly(draw, [(cx - 12, top + 4), (cx - 8, top + 4), (cx - 7, top + 18), (cx - 11, top + 18)], VEST)
    _poly(draw, [(cx + 12, top + 4), (cx + 8, top + 4), (cx + 7, top + 18), (cx + 11, top + 18)], VEST)
    _poly(draw, [(cx - 6, top + 18), (cx + 6, top + 18), (cx + 5, top + 22), (cx - 5, top + 22)], BELT)
    _poly(draw, [(cx - 3, top + 18), (cx + 3, top + 18), (cx + 3, top + 22), (cx - 3, top + 22)], BUCKLE)
    _poly(draw, [(cx - 8, top - 1), (cx + 8, top - 1), (cx + 6, top + 5), (cx - 6, top + 5)], BANDANA)
    # Arms
    _line(draw, (cx - 10, top + 8), (cx - 16 - arm_swing, top + 16), SHIRT_DARK, 4)
    _line(draw, (cx + 10, top + 8), (cx + 16 + arm_swing, top + 16), SHIRT_DARK, 4)
    _px(draw, cx - 16 - arm_swing, top + 16, SKIN, 2)
    _px(draw, cx + 16 + arm_swing, top + 16, SKIN, 2)


def _draw_skirt(draw: ImageDraw.ImageDraw, cx: float, top: float, spread: float = 0.0) -> None:
    _poly(
        draw,
        [
            (cx - 8, top),
            (cx + 8, top),
            (cx + 14 + spread, top + 16),
            (cx - 14 - spread, top + 16),
        ],
        SKIRT,
    )
    _line(draw, (cx - 2, top + 2), (cx - 10 - spread, top + 14), SKIRT_DARK, 2)
    _line(draw, (cx + 2, top + 2), (cx + 10 + spread, top + 14), SKIRT_DARK, 2)


def _draw_boots(
    draw: ImageDraw.ImageDraw,
    cx: float,
    top: float,
    stride: float = 0.0,
    magic: bool = False,
) -> None:
    boot = MAGIC_BOOT if magic else BOOT
    boot_dark = MAGIC_BOOT_DARK if magic else BOOT_DARK
    _poly(draw, [(cx - 12 - stride, top), (cx - 4 - stride, top), (cx - 3 - stride, top + 8), (cx - 14 - stride, top + 8)], boot)
    _poly(draw, [(cx + 12 + stride, top), (cx + 4 + stride, top), (cx + 3 + stride, top + 8), (cx + 14 + stride, top + 8)], boot)
    _line(draw, (cx - 14 - stride, top + 8), (cx - 2 - stride, top + 8), BOOT_SOLE, 3)
    _line(draw, (cx + 14 + stride, top + 8), (cx + 2 + stride, top + 8), BOOT_SOLE, 3)
    if magic:
        _px(draw, cx - 8 - stride, top + 2, MAGIC_SPARK, 1.5)
        _px(draw, cx + 8 + stride, top + 2, MAGIC_SPARK, 1.5)


def _compose(
    *,
    head_y: float = 18.0,
    head_x: float = 32.0,
    hat_tilt: float = 0.0,
    pigtail_swing: float = 0.0,
    arm_swing: float = 0.0,
    skirt_spread: float = 0.0,
    leg_stride: float = 0.0,
    mouth_open: bool = False,
    celebrate: bool = False,
    magic_boots: bool = False,
) -> Image.Image:
    img = _blank()
    draw = ImageDraw.Draw(img)
    torso_top = head_y + 14
    skirt_top = torso_top + 20
    boot_top = skirt_top + 14
    _draw_pigtails(draw, head_x, head_y, pigtail_swing)
    _draw_skirt(draw, head_x, skirt_top, skirt_spread)
    _draw_boots(draw, head_x, boot_top, leg_stride, magic_boots)
    _draw_torso(draw, head_x, torso_top, arm_swing)
    if celebrate:
        _line(draw, (head_x + 10, torso_top + 6), (head_x + 22, torso_top - 8), SHIRT_DARK, 4)
        _px(draw, head_x + 22, torso_top - 8, SKIN, 2.5)
    _draw_face(draw, head_x, head_y + 2, mouth_open)
    _draw_hat(draw, head_x, head_y - 2, hat_tilt)
    return img


def _idle_frame(bob: float) -> Image.Image:
    return _compose(head_y=18 + bob, pigtail_swing=math.sin(bob * 2) * 1.5)


def _run_frame(phase: int) -> Image.Image:
    swing = [-3.0, 0.0, 3.0, 0.0][phase % 4]
    stride = [-4.0, -1.0, 4.0, 1.0][phase % 4]
    return _compose(
        head_x=32 + swing * 0.3,
        pigtail_swing=swing,
        arm_swing=swing,
        skirt_spread=abs(swing) * 0.4,
        leg_stride=stride,
        head_y=18 + (1 if phase % 2 else 0),
    )


def _jump_frame() -> Image.Image:
    return _compose(
        head_y=16,
        pigtail_swing=-4,
        arm_swing=-6,
        skirt_spread=3,
        leg_stride=-3,
        mouth_open=True,
    )


def _celebrate_frame() -> Image.Image:
    return _compose(
        head_y=15,
        pigtail_swing=5,
        skirt_spread=4,
        leg_stride=2,
        mouth_open=True,
        celebrate=True,
    )


def _magic_variant(base: Image.Image) -> Image.Image:
    """Tint boots on an existing cowgirl frame using the cowboy boots frame as a mask guide."""
    out = base.copy()
    px = out.load()
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if y >= 50 and r > 100 and g > 70 and b < 90:
                px[x, y] = MAGIC_BOOT
            elif y >= 48 and r > 90 and g > 55 and b < 70:
                px[x, y] = MAGIC_BOOT_DARK
            elif y >= 52 and r < 70:
                px[x, y] = BOOT_SOLE
            elif magic_spark_pixel(x, y, r, g, b):
                px[x, y] = MAGIC_SPARK
    return out


def magic_spark_pixel(x: int, y: int, r: int, g: int, b: int) -> bool:
    return y in (46, 47) and (x + y) % 7 == 0 and r > 80


def generate_all() -> None:
    COWGIRL.mkdir(parents=True, exist_ok=True)
    frames = {
        "idle_0.png": _idle_frame(0),
        "idle_1.png": _idle_frame(1.5),
        "run_0.png": _run_frame(0),
        "run_1.png": _run_frame(1),
        "run_2.png": _run_frame(2),
        "run_3.png": _run_frame(3),
        "jump.png": _jump_frame(),
        "celebrate.png": _celebrate_frame(),
    }
    for name, img in frames.items():
        path = COWGIRL / name
        img.save(path)
        _magic_variant(img).save(COWGIRL / name.replace(".png", "_boots.png"))


if __name__ == "__main__":
    generate_all()
    print(f"Wrote cowgirl frames to {COWGIRL}")
