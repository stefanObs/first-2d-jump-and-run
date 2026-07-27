#!/usr/bin/env python3
"""Hand-painted cowgirl player sprites.

Original chibi cel-shaded art in the same big-head western style as the cowboy
and bandit props: an oversized friendly head (~40% of the sprite), a small
chunky body, thick warm ink outlines and shadow/highlight cel layers, drawn at
4x supersample and downscaled to 64x64. The cowgirl is kept visually distinct
from the cowboy with twin pigtails, a hat flower, a teal shirt, a denim skirt
and tall boots -- she is NOT derived from the cowboy frames.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 64
SUPER = 4
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "player" / "cowgirl"

# Warm western palette matching the cowboy / bandit props (dark warm ink, cel shading).
INK = (34, 24, 22, 255)
SKIN = (250, 206, 158, 255)
SKIN_SHADOW = (212, 158, 112, 255)
BLUSH = (240, 148, 138, 255)
HAT = (198, 152, 92, 255)
HAT_LIGHT = (226, 190, 132, 255)
HAT_DARK = (150, 108, 60, 255)
HAT_BAND = (200, 58, 50, 255)
HAT_BAND_DARK = (158, 38, 34, 255)
FLOWER = (244, 176, 96, 255)
FLOWER_CORE = (232, 108, 72, 255)
HAIR = (188, 118, 56, 255)
HAIR_DARK = (134, 78, 34, 255)
HAIR_LIGHT = (222, 160, 90, 255)
RIBBON = (208, 60, 52, 255)
SHIRT = (72, 178, 170, 255)
SHIRT_SHADOW = (44, 134, 128, 255)
SHIRT_LIGHT = (132, 214, 204, 255)
VEST = (120, 74, 40, 255)
VEST_SHADOW = (84, 50, 24, 255)
VEST_LIGHT = (156, 104, 60, 255)
KERCHIEF = (210, 62, 52, 255)
KERCHIEF_DARK = (166, 40, 36, 255)
KERCHIEF_LIGHT = (240, 108, 92, 255)
SKIRT = (92, 120, 182, 255)
SKIRT_DARK = (60, 84, 138, 255)
SKIRT_LIGHT = (128, 156, 210, 255)
BELT = (92, 56, 28, 255)
BRASS = (228, 190, 70, 255)
BRASS_LIGHT = (255, 226, 130, 255)
BOOT = (120, 70, 32, 255)
BOOT_DARK = (78, 44, 20, 255)
BOOT_LIGHT = (162, 102, 54, 255)
MAGIC_BOOT = (168, 96, 220, 255)
MAGIC_BOOT_DARK = (112, 56, 158, 255)
MAGIC_GLOW = (234, 200, 255, 255)
EYE_WHITE = (250, 250, 246, 255)

FRAME_NAMES = (
    "idle_0",
    "idle_1",
    "run_0",
    "run_1",
    "run_2",
    "run_3",
    "jump",
    "celebrate",
)


@dataclass(frozen=True)
class Pose:
    bob: float = 0.0
    lean: float = 0.0
    # Foot offsets (dx, dy) in design pixels from each planted base position.
    left_foot: tuple[float, float] = (0.0, 0.0)
    right_foot: tuple[float, float] = (0.0, 0.0)
    # Hand offsets (dx, dy) from each resting-at-side base position.
    left_hand: tuple[float, float] = (0.0, 0.0)
    right_hand: tuple[float, float] = (0.0, 0.0)
    hair_swing: float = 0.0
    celebrate: bool = False
    # When True the frame is drawn as a 3/4 right-facing pose (matches the
    # cowboy run/jump); otherwise it is a front-facing pose (idle/celebrate).
    # For profile frames right_* = near (front) limb, left_* = far (back) limb.
    profile: bool = False


FRAME_POSES: dict[str, Pose] = {
    # Front-facing, matching the cowboy idle stance.
    "idle_0": Pose(),
    # Idle is a single in-game frame; keep idle_1 near-identical to avoid flicker.
    "idle_1": Pose(bob=0.35, hair_swing=0.3),
    # 3/4 right-facing run cycle, matching the cowboy run poses.
    "run_0": Pose(
        profile=True,
        lean=1.2,
        bob=0.3,
        right_foot=(5.5, 0.0),
        left_foot=(-6.0, -2.5),
        right_hand=(-3.0, -1.0),
        left_hand=(4.0, -3.0),
        hair_swing=1.6,
    ),
    "run_1": Pose(
        profile=True,
        lean=0.7,
        bob=-0.5,
        right_foot=(-1.0, -0.5),
        left_foot=(-2.5, -6.0),
        right_hand=(1.5, 0.5),
        left_hand=(-1.0, -1.0),
        hair_swing=0.9,
    ),
    "run_2": Pose(
        profile=True,
        lean=1.2,
        bob=0.3,
        right_foot=(-6.0, -2.5),
        left_foot=(5.5, 0.0),
        right_hand=(4.0, -3.0),
        left_hand=(-3.0, -1.0),
        hair_swing=1.6,
    ),
    "run_3": Pose(
        profile=True,
        lean=0.7,
        bob=-0.5,
        right_foot=(2.5, -6.0),
        left_foot=(-1.0, -0.5),
        right_hand=(-1.0, -1.0),
        left_hand=(1.5, 0.5),
        hair_swing=0.9,
    ),
    # 3/4 right-facing leap, matching the cowboy jump.
    "jump": Pose(
        profile=True,
        bob=-1.4,
        lean=0.4,
        right_foot=(2.0, -5.5),
        left_foot=(-3.5, -3.0),
        right_hand=(2.5, -2.0),
        left_hand=(-2.0, -8.0),
        hair_swing=2.0,
    ),
    # Front-facing cheer, matching the cowboy celebrate.
    "celebrate": Pose(
        bob=-1.0,
        left_hand=(-1.5, -13.0),
        right_hand=(1.5, -13.0),
        hair_swing=1.0,
        celebrate=True,
    ),
}


def _s(value: float) -> float:
    return value * SUPER


def _shade(color: tuple[int, int, int, int], amount: float) -> tuple[int, int, int, int]:
    return (
        max(0, min(255, int(color[0] * amount))),
        max(0, min(255, int(color[1] * amount))),
        max(0, min(255, int(color[2] * amount))),
        color[3],
    )


def _canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (SIZE * SUPER, SIZE * SUPER), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def _downscale(img: Image.Image) -> Image.Image:
    return img.resize((SIZE, SIZE), Image.Resampling.NEAREST)


def _iw(width: float = 1.0) -> int:
    return max(1, int(round(_s(width))))


def _poly(
    draw: ImageDraw.ImageDraw,
    points: list[tuple[float, float]],
    fill: tuple[int, int, int, int],
    *,
    outline: bool = True,
    width: float = 1.0,
) -> None:
    draw.polygon(points, fill=fill)
    if outline:
        draw.line(points + [points[0]], fill=INK, width=_iw(width))


def _capsule(
    draw: ImageDraw.ImageDraw,
    a: tuple[float, float],
    b: tuple[float, float],
    radius: float,
    fill: tuple[int, int, int, int],
    shadow: tuple[int, int, int, int],
) -> None:
    draw.line([a, b], fill=shadow, width=max(1, int(round(_s(radius * 2.2)))), joint="curve")
    draw.line([a, b], fill=fill, width=max(1, int(round(_s(radius * 1.8)))), joint="curve")
    draw.line([a, b], fill=INK, width=max(1, int(round(_s(radius * 0.42)))), joint="curve")
    for cx, cy in (a, b):
        r = _s(radius)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill, outline=INK, width=_iw(0.5))


def _bezier2(
    start: tuple[float, float],
    control: tuple[float, float],
    end: tuple[float, float],
    steps: int,
) -> list[tuple[float, float]]:
    points = []
    for i in range(steps + 1):
        t = i / steps
        u = 1.0 - t
        points.append(
            (
                u * u * start[0] + 2 * u * t * control[0] + t * t * end[0],
                u * u * start[1] + 2 * u * t * control[1] + t * t * end[1],
            )
        )
    return points


def _draw_boot(draw: ImageDraw.ImageDraw, foot: tuple[float, float], magic: bool) -> None:
    fx, fy = foot
    base = MAGIC_BOOT if magic else BOOT
    dark = MAGIC_BOOT_DARK if magic else BOOT_DARK
    light = MAGIC_GLOW if magic else BOOT_LIGHT
    # Tall boot shaft (knee to ankle) plus a rounded toe box.
    shaft = [
        (fx - _s(2.6), fy - _s(11.0)),
        (fx + _s(2.6), fy - _s(11.0)),
        (fx + _s(2.9), fy - _s(1.5)),
        (fx - _s(2.9), fy - _s(1.5)),
    ]
    _poly(draw, shaft, base, width=0.9)
    draw.line([(fx - _s(1.4), fy - _s(10.0)), (fx - _s(1.4), fy - _s(2.5))], fill=light, width=_iw(0.6))
    draw.line([(fx + _s(1.6), fy - _s(9.5)), (fx + _s(1.9), fy - _s(2.5))], fill=dark, width=_iw(0.6))
    toe = [
        (fx - _s(2.9), fy - _s(2.5)),
        (fx + _s(4.4), fy - _s(2.5)),
        (fx + _s(4.8), fy + _s(0.4)),
        (fx - _s(2.9), fy + _s(0.4)),
    ]
    _poly(draw, toe, dark, width=0.9)
    # Boot cuff at the top and a little heel spur.
    draw.line([(fx - _s(3.0), fy - _s(11.0)), (fx + _s(2.8), fy - _s(11.0))], fill=light, width=_iw(0.7))
    if magic:
        for ox, oy in ((0.0, -12.5), (1.2, -13.4), (-1.2, -13.2)):
            sx, sy = fx + _s(ox), fy + _s(oy)
            draw.line([(sx - _s(0.6), sy), (sx + _s(0.6), sy)], fill=MAGIC_GLOW, width=1)
            draw.line([(sx, sy - _s(0.6)), (sx, sy + _s(0.6))], fill=MAGIC_GLOW, width=1)


def _draw_arm(
    draw: ImageDraw.ImageDraw,
    shoulder: tuple[float, float],
    hand: tuple[float, float],
    *,
    celebrate: bool,
) -> None:
    elbow = ((shoulder[0] + hand[0]) * 0.5, (shoulder[1] + hand[1]) * 0.5 + _s(0.8))
    _capsule(draw, shoulder, elbow, 1.7, SHIRT, SHIRT_SHADOW)
    _capsule(draw, elbow, hand, 1.5, SHIRT, SHIRT_SHADOW)
    # Rolled cuff.
    draw.ellipse(
        (hand[0] - _s(1.8), hand[1] - _s(1.7), hand[0] + _s(1.8), hand[1] + _s(1.7)),
        fill=SHIRT_LIGHT,
        outline=INK,
        width=_iw(0.45),
    )
    # Hand.
    draw.ellipse(
        (hand[0] - _s(1.5), hand[1] + _s(0.3), hand[0] + _s(1.5), hand[1] + _s(3.0)),
        fill=SKIN,
        outline=INK,
        width=_iw(0.45),
    )


def _draw_leg(draw: ImageDraw.ImageDraw, hip: tuple[float, float], foot: tuple[float, float], magic: bool) -> None:
    # Short thigh (mostly hidden by the skirt) into the tall boot.
    knee = ((hip[0] + foot[0]) * 0.5, (hip[1] + foot[1]) * 0.5)
    _capsule(draw, hip, knee, 1.8, SKIN, SKIN_SHADOW)
    _draw_boot(draw, foot, magic)


def _draw_skirt(draw: ImageDraw.ImageDraw, cx: float, top: float) -> None:
    hem = top + _s(7.0)
    skirt = [
        (cx - _s(7.5), top),
        (cx + _s(7.5), top),
        (cx + _s(10.5), hem),
        (cx - _s(10.5), hem),
    ]
    _poly(draw, skirt, SKIRT, width=1.0)
    # Pleat shading.
    for ox in (-6.0, -2.0, 2.0, 6.0):
        tone = SKIRT_DARK if int(ox) % 4 == 0 else SKIRT_LIGHT
        draw.line(
            [(cx + _s(ox * 0.7), top + _s(0.8)), (cx + _s(ox), hem - _s(0.4))],
            fill=tone,
            width=_iw(0.6),
        )
    # Lighter hem band.
    draw.line([(cx - _s(10.3), hem - _s(0.4)), (cx + _s(10.3), hem - _s(0.4))], fill=SKIRT_LIGHT, width=_iw(0.7))


def _draw_torso(draw: ImageDraw.ImageDraw, cx: float, top: float) -> None:
    # Chunky little torso: teal shirt with a brown open vest.
    shirt = [
        (cx - _s(7.0), top),
        (cx + _s(7.0), top),
        (cx + _s(7.8), top + _s(13.0)),
        (cx - _s(7.8), top + _s(13.0)),
    ]
    _poly(draw, shirt, SHIRT, width=1.0)
    draw.line([(cx - _s(1.0), top + _s(1.0)), (cx - _s(1.0), top + _s(12.0))], fill=SHIRT_SHADOW, width=_iw(0.6))
    draw.line([(cx + _s(3.5), top + _s(2.0)), (cx + _s(4.5), top + _s(9.0))], fill=SHIRT_LIGHT, width=_iw(0.7))
    # Vest panels on each side.
    left_vest = [
        (cx - _s(7.2), top + _s(0.3)),
        (cx - _s(2.5), top + _s(1.2)),
        (cx - _s(3.2), top + _s(12.6)),
        (cx - _s(7.8), top + _s(12.8)),
    ]
    right_vest = [
        (cx + _s(7.2), top + _s(0.3)),
        (cx + _s(2.5), top + _s(1.2)),
        (cx + _s(3.2), top + _s(12.6)),
        (cx + _s(7.8), top + _s(12.8)),
    ]
    _poly(draw, left_vest, VEST, width=0.9)
    _poly(draw, right_vest, VEST, width=0.9)
    draw.line([(cx - _s(6.8), top + _s(2.0)), (cx - _s(6.8), top + _s(11.5))], fill=VEST_LIGHT, width=_iw(0.55))
    draw.line([(cx + _s(6.8), top + _s(2.0)), (cx + _s(6.8), top + _s(11.5))], fill=VEST_SHADOW, width=_iw(0.55))
    # Belt + brass buckle.
    belt_y = top + _s(12.2)
    draw.rounded_rectangle(
        (cx - _s(7.6), belt_y, cx + _s(7.6), belt_y + _s(2.4)),
        radius=_s(0.5),
        fill=BELT,
        outline=INK,
        width=_iw(0.5),
    )
    draw.rounded_rectangle(
        (cx - _s(1.8), belt_y + _s(0.3), cx + _s(1.8), belt_y + _s(2.1)),
        radius=_s(0.3),
        fill=BRASS,
        outline=_shade(BRASS, 0.8),
        width=1,
    )
    draw.point((cx - _s(0.8), belt_y + _s(0.9)), fill=BRASS_LIGHT)


def _draw_kerchief(draw: ImageDraw.ImageDraw, cx: float, y: float) -> None:
    # Knotted triangle neckerchief at the collar.
    tri = [(cx - _s(4.0), y), (cx + _s(4.0), y), (cx, y + _s(5.0))]
    _poly(draw, tri, KERCHIEF, width=0.9)
    draw.line([(cx - _s(2.0), y + _s(0.6)), (cx, y + _s(4.2))], fill=KERCHIEF_DARK, width=_iw(0.5))
    draw.line([(cx + _s(2.0), y + _s(0.6)), (cx, y + _s(4.2))], fill=KERCHIEF_LIGHT, width=_iw(0.5))
    draw.ellipse((cx - _s(1.4), y - _s(1.2), cx + _s(1.4), y + _s(1.4)), fill=KERCHIEF, outline=INK, width=_iw(0.45))


def _draw_pigtail(
    draw: ImageDraw.ImageDraw,
    root: tuple[float, float],
    tip: tuple[float, float],
    side: int,
    swing: float,
) -> None:
    control = ((root[0] + tip[0]) * 0.5 + _s(side * 2.5), (root[1] + tip[1]) * 0.5)
    tip = (tip[0] + _s(side * swing), tip[1])
    points = _bezier2(root, control, tip, 16)
    for i, (px, py) in enumerate(points):
        t = i / max(1, len(points) - 1)
        radius = _s(2.8 - t * 1.9)
        tone = HAIR_LIGHT if t < 0.25 else HAIR if t < 0.7 else HAIR_DARK
        draw.ellipse((px - radius, py - radius, px + radius, py + radius), fill=tone, outline=INK, width=_iw(0.4))
    # Ribbon tie at the root.
    draw.ellipse(
        (root[0] - _s(1.7), root[1] - _s(1.4), root[0] + _s(1.7), root[1] + _s(1.4)),
        fill=RIBBON,
        outline=INK,
        width=_iw(0.45),
    )


def _draw_face(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    face = (cx - _s(9.5), cy - _s(9.0), cx + _s(9.5), cy + _s(9.5))
    draw.ellipse(face, fill=SKIN, outline=INK, width=_iw(1.0))
    # Cel shadow on the lower-left of the face.
    draw.pieslice((cx - _s(9.5), cy - _s(9.0), cx + _s(9.5), cy + _s(9.5)), start=95, end=210, fill=SKIN_SHADOW)
    # Blush cheeks.
    draw.ellipse((cx - _s(7.2), cy + _s(1.5), cx - _s(3.6), cy + _s(4.4)), fill=BLUSH)
    draw.ellipse((cx + _s(3.6), cy + _s(1.5), cx + _s(7.2), cy + _s(4.4)), fill=BLUSH)
    # Big friendly eyes.
    for ex in (cx - _s(4.2), cx + _s(4.2)):
        draw.ellipse((ex - _s(2.4), cy - _s(3.4), ex + _s(2.4), cy + _s(1.8)), fill=EYE_WHITE, outline=INK, width=_iw(0.5))
        draw.ellipse((ex - _s(1.4), cy - _s(2.0), ex + _s(1.4), cy + _s(1.2)), fill=INK)
        draw.ellipse((ex - _s(0.4), cy - _s(1.6), ex + _s(0.7), cy - _s(0.4)), fill=EYE_WHITE)
        # Lashes.
        draw.line([(ex + _s(2.2), cy - _s(2.8)), (ex + _s(3.4), cy - _s(3.4))], fill=INK, width=_iw(0.5))
    # Little smile.
    draw.arc((cx - _s(3.0), cy + _s(3.0), cx + _s(3.0), cy + _s(7.0)), start=15, end=165, fill=INK, width=_iw(0.7))
    # Nose dot.
    draw.point((cx, cy + _s(2.6)), fill=SKIN_SHADOW)


def _draw_bangs(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    # Rounded fringe of hair peeking under the hat brim.
    fringe = [
        (cx - _s(9.2), cy - _s(6.5)),
        (cx - _s(6.0), cy - _s(9.0)),
        (cx - _s(2.5), cy - _s(6.8)),
        (cx, cy - _s(9.0)),
        (cx + _s(2.5), cy - _s(6.8)),
        (cx + _s(6.0), cy - _s(9.0)),
        (cx + _s(9.2), cy - _s(6.5)),
        (cx + _s(9.2), cy - _s(8.5)),
        (cx - _s(9.2), cy - _s(8.5)),
    ]
    _poly(draw, fringe, HAIR, width=0.7)
    draw.line([(cx - _s(6.0), cy - _s(8.4)), (cx - _s(4.0), cy - _s(7.2))], fill=HAIR_LIGHT, width=_iw(0.5))
    draw.line([(cx + _s(2.5), cy - _s(8.4)), (cx + _s(4.5), cy - _s(7.2))], fill=HAIR_LIGHT, width=_iw(0.5))


def _draw_hat(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    # Wide western brim (cowboy-style) with an upturned edge.
    brim = (cx - _s(13.5), cy - _s(2.0), cx + _s(13.5), cy + _s(4.5))
    draw.ellipse(brim, fill=HAT, outline=INK, width=_iw(1.0))
    draw.ellipse((cx - _s(12.0), cy - _s(1.0), cx + _s(12.0), cy + _s(3.0)), fill=HAT_LIGHT)
    draw.ellipse(brim, outline=INK, width=_iw(1.0))
    # Crown.
    crown = [
        (cx - _s(6.5), cy + _s(1.0)),
        (cx - _s(5.5), cy - _s(8.5)),
        (cx + _s(5.5), cy - _s(8.5)),
        (cx + _s(6.5), cy + _s(1.0)),
    ]
    _poly(draw, crown, HAT, width=1.0)
    draw.pieslice((cx - _s(6.5), cy - _s(9.5), cx + _s(6.5), cy + _s(1.5)), start=200, end=340, fill=HAT_DARK)
    draw.line([(cx - _s(4.5), cy - _s(8.0)), (cx - _s(4.0), cy + _s(0.5))], fill=HAT_LIGHT, width=_iw(0.7))
    # Red hat band.
    draw.rectangle((cx - _s(6.2), cy - _s(1.0), cx + _s(6.2), cy + _s(1.2)), fill=HAT_BAND)
    draw.line([(cx - _s(6.2), cy + _s(1.2)), (cx + _s(6.2), cy + _s(1.2))], fill=HAT_BAND_DARK, width=_iw(0.5))
    # Flower tucked on the band (cowgirl signature).
    fcx, fcy = cx + _s(4.6), cy - _s(0.2)
    for ang in range(0, 360, 72):
        px = fcx + math.cos(math.radians(ang)) * _s(1.7)
        py = fcy + math.sin(math.radians(ang)) * _s(1.7)
        draw.ellipse((px - _s(1.1), py - _s(1.1), px + _s(1.1), py + _s(1.1)), fill=FLOWER, outline=INK, width=_iw(0.35))
    draw.ellipse((fcx - _s(1.0), fcy - _s(1.0), fcx + _s(1.0), fcy + _s(1.0)), fill=FLOWER_CORE, outline=INK, width=_iw(0.35))


def _draw_stream_pigtail(draw: ImageDraw.ImageDraw, root: tuple[float, float], swing: float) -> None:
    # Pigtail trailing back (to the left) and lifting as the cowgirl runs right.
    tip = (root[0] - _s(11.0 + swing * 1.6), root[1] - _s(1.0 + swing * 1.0))
    control = (root[0] - _s(5.0), root[1] + _s(2.5))
    points = _bezier2(root, control, tip, 16)
    for i, (px, py) in enumerate(points):
        t = i / max(1, len(points) - 1)
        radius = _s(2.7 - t * 1.9)
        tone = HAIR_LIGHT if t < 0.25 else HAIR if t < 0.7 else HAIR_DARK
        draw.ellipse((px - radius, py - radius, px + radius, py + radius), fill=tone, outline=INK, width=_iw(0.4))
    draw.ellipse(
        (root[0] - _s(1.7), root[1] - _s(1.4), root[0] + _s(1.7), root[1] + _s(1.4)),
        fill=RIBBON,
        outline=INK,
        width=_iw(0.45),
    )


def _draw_profile_leg(draw: ImageDraw.ImageDraw, hip: tuple[float, float], foot: tuple[float, float], *, near: bool, magic: bool) -> None:
    # Bent-knee running leg: short skin thigh into the tall boot (boot is the shin).
    boot_top = (foot[0], foot[1] - _s(11.0))
    knee = ((hip[0] + boot_top[0]) * 0.5 + _s(1.6 if near else 1.0), (hip[1] + boot_top[1]) * 0.5)
    shade = SKIN_SHADOW if near else _shade(SKIN_SHADOW, 0.9)
    _capsule(draw, hip, knee, 1.9 if near else 1.7, SKIN, shade)
    _capsule(draw, knee, boot_top, 1.7 if near else 1.5, SKIN, shade)
    _draw_boot(draw, foot, magic)


def _draw_profile_arm(draw: ImageDraw.ImageDraw, shoulder: tuple[float, float], hand: tuple[float, float], *, near: bool) -> None:
    fill = SHIRT if near else SHIRT_SHADOW
    shadow = SHIRT_SHADOW if near else _shade(SHIRT_SHADOW, 0.88)
    elbow = ((shoulder[0] + hand[0]) * 0.5, (shoulder[1] + hand[1]) * 0.5 + _s(0.8))
    _capsule(draw, shoulder, elbow, 1.6 if near else 1.4, fill, shadow)
    _capsule(draw, elbow, hand, 1.4 if near else 1.25, fill, shadow)
    draw.ellipse(
        (hand[0] - _s(1.6), hand[1] - _s(1.5), hand[0] + _s(1.6), hand[1] + _s(1.5)),
        fill=SHIRT_LIGHT if near else SHIRT_SHADOW,
        outline=INK,
        width=_iw(0.4),
    )
    draw.ellipse(
        (hand[0] - _s(1.4), hand[1] + _s(0.4), hand[0] + _s(1.4), hand[1] + _s(2.9)),
        fill=SKIN,
        outline=INK,
        width=_iw(0.4),
    )


def _draw_profile_torso(draw: ImageDraw.ImageDraw, cx: float, top: float) -> None:
    # Narrower profile torso leaning right: teal shirt + brown vest + belt.
    shirt = [
        (cx - _s(4.5), top),
        (cx + _s(6.0), top + _s(0.5)),
        (cx + _s(6.5), top + _s(12.5)),
        (cx - _s(4.0), top + _s(13.0)),
    ]
    _poly(draw, shirt, SHIRT, width=1.0)
    draw.line([(cx + _s(3.0), top + _s(2.0)), (cx + _s(4.0), top + _s(9.0))], fill=SHIRT_LIGHT, width=_iw(0.7))
    vest = [
        (cx - _s(4.4), top + _s(0.4)),
        (cx + _s(1.0), top + _s(1.0)),
        (cx + _s(0.5), top + _s(12.4)),
        (cx - _s(4.2), top + _s(12.6)),
    ]
    _poly(draw, vest, VEST, width=0.9)
    draw.line([(cx - _s(4.0), top + _s(2.0)), (cx - _s(4.0), top + _s(11.5))], fill=VEST_LIGHT, width=_iw(0.55))
    belt_y = top + _s(12.0)
    draw.rounded_rectangle(
        (cx - _s(4.6), belt_y, cx + _s(6.4), belt_y + _s(2.3)),
        radius=_s(0.5),
        fill=BELT,
        outline=INK,
        width=_iw(0.5),
    )
    draw.rounded_rectangle(
        (cx + _s(1.6), belt_y + _s(0.3), cx + _s(4.4), belt_y + _s(2.0)),
        radius=_s(0.3),
        fill=BRASS,
        outline=_shade(BRASS, 0.8),
        width=1,
    )


def _draw_profile_skirt(draw: ImageDraw.ImageDraw, cx: float, top: float) -> None:
    hem = top + _s(7.0)
    skirt = [
        (cx - _s(5.0), top),
        (cx + _s(6.5), top),
        (cx + _s(8.5), hem),
        (cx - _s(8.0), hem),
    ]
    _poly(draw, skirt, SKIRT, width=1.0)
    for ox in (-4.0, 0.0, 4.0):
        tone = SKIRT_DARK if int(ox) == 0 else SKIRT_LIGHT
        draw.line([(cx + _s(ox * 0.7), top + _s(0.8)), (cx + _s(ox), hem - _s(0.4))], fill=tone, width=_iw(0.6))
    draw.line([(cx - _s(7.8), hem - _s(0.4)), (cx + _s(8.3), hem - _s(0.4))], fill=SKIRT_LIGHT, width=_iw(0.7))


def _draw_profile_head(draw: ImageDraw.ImageDraw, hcx: float, hcy: float, swing: float) -> None:
    # Hair mass at the back of the head (left) + a streaming pigtail.
    draw.ellipse((hcx - _s(9.5), hcy - _s(7.5), hcx - _s(1.5), hcy + _s(6.5)), fill=HAIR, outline=INK, width=_iw(0.6))
    _draw_stream_pigtail(draw, (hcx - _s(5.5), hcy + _s(2.5)), swing)

    # Face, right-biased for the 3/4 read.
    face = (hcx - _s(7.5), hcy - _s(9.0), hcx + _s(9.0), hcy + _s(9.0))
    draw.ellipse(face, fill=SKIN, outline=INK, width=_iw(1.0))
    draw.pieslice(face, start=95, end=215, fill=SKIN_SHADOW)
    # Nose bump on the leading edge.
    _poly(draw, [(hcx + _s(8.2), hcy + _s(0.3)), (hcx + _s(10.2), hcy + _s(1.7)), (hcx + _s(8.0), hcy + _s(3.0))], SKIN, width=0.6)
    # Blush + smile + eyes (near eye dominant, far eye a sliver).
    draw.ellipse((hcx + _s(3.0), hcy + _s(2.0), hcx + _s(6.6), hcy + _s(4.8)), fill=BLUSH)
    ex = hcx + _s(4.2)
    draw.ellipse((ex - _s(2.4), hcy - _s(3.2), ex + _s(2.4), hcy + _s(2.0)), fill=EYE_WHITE, outline=INK, width=_iw(0.5))
    draw.ellipse((ex - _s(1.2), hcy - _s(1.8), ex + _s(1.6), hcy + _s(1.3)), fill=INK)
    draw.ellipse((ex - _s(0.2), hcy - _s(1.4), ex + _s(0.9), hcy - _s(0.4)), fill=EYE_WHITE)
    draw.line([(ex + _s(2.2), hcy - _s(2.6)), (ex + _s(3.4), hcy - _s(3.1))], fill=INK, width=_iw(0.5))
    fx = hcx - _s(0.8)
    draw.ellipse((fx - _s(1.1), hcy - _s(1.4), fx + _s(0.9), hcy + _s(0.9)), fill=INK)
    draw.arc((hcx + _s(1.5), hcy + _s(3.2), hcx + _s(6.8), hcy + _s(6.6)), start=10, end=150, fill=INK, width=_iw(0.7))

    # Fringe under the brim.
    fringe = [
        (hcx - _s(7.0), hcy - _s(6.5)),
        (hcx - _s(3.5), hcy - _s(8.8)),
        (hcx, hcy - _s(6.6)),
        (hcx + _s(3.5), hcy - _s(8.8)),
        (hcx + _s(8.5), hcy - _s(6.4)),
        (hcx + _s(8.5), hcy - _s(8.4)),
        (hcx - _s(7.0), hcy - _s(8.4)),
    ]
    _poly(draw, fringe, HAIR, width=0.7)

    # Hat with a right-swept brim (running into the wind).
    haty = hcy - _s(6.8)
    brim = (hcx - _s(9.5), haty - _s(1.5), hcx + _s(13.5), haty + _s(4.0))
    draw.ellipse(brim, fill=HAT, outline=INK, width=_iw(1.0))
    draw.ellipse((hcx - _s(8.0), haty - _s(0.5), hcx + _s(12.0), haty + _s(2.6)), fill=HAT_LIGHT)
    draw.ellipse(brim, outline=INK, width=_iw(1.0))
    crown = [
        (hcx - _s(4.5), haty + _s(0.8)),
        (hcx - _s(3.5), haty - _s(8.5)),
        (hcx + _s(6.5), haty - _s(8.0)),
        (hcx + _s(7.8), haty + _s(1.0)),
    ]
    _poly(draw, crown, HAT, width=1.0)
    draw.pieslice((hcx - _s(4.5), haty - _s(9.5), hcx + _s(7.8), haty + _s(1.5)), start=200, end=340, fill=HAT_DARK)
    draw.line([(hcx - _s(2.5), haty - _s(8.0)), (hcx - _s(2.0), haty + _s(0.5))], fill=HAT_LIGHT, width=_iw(0.7))
    draw.rectangle((hcx - _s(4.0), haty - _s(1.0), hcx + _s(7.2), haty + _s(1.2)), fill=HAT_BAND)
    draw.line([(hcx - _s(4.0), haty + _s(1.2)), (hcx + _s(7.2), haty + _s(1.2))], fill=HAT_BAND_DARK, width=_iw(0.5))
    # Flower on the band.
    fcx, fcy = hcx + _s(5.6), haty - _s(0.2)
    for ang in range(0, 360, 72):
        px = fcx + math.cos(math.radians(ang)) * _s(1.6)
        py = fcy + math.sin(math.radians(ang)) * _s(1.6)
        draw.ellipse((px - _s(1.0), py - _s(1.0), px + _s(1.0), py + _s(1.0)), fill=FLOWER, outline=INK, width=_iw(0.35))
    draw.ellipse((fcx - _s(0.9), fcy - _s(0.9), fcx + _s(0.9), fcy + _s(0.9)), fill=FLOWER_CORE, outline=INK, width=_iw(0.35))


def draw_profile_frame(pose: Pose, *, magic_boots: bool = False) -> Image.Image:
    img, draw = _canvas()
    cx = _s(29.5 + pose.lean)
    torso_top = _s(31.0 + pose.bob)
    hip_y = _s(44.0 + pose.bob)
    feet_y = _s(60.0)
    hcx = cx + _s(2.5)
    hcy = _s(19.0 + pose.bob)

    near_shoulder = (cx + _s(3.5), torso_top + _s(2.5))
    far_shoulder = (cx - _s(1.5), torso_top + _s(3.0))
    near_hand = (cx + _s(4.5) + _s(pose.right_hand[0]), torso_top + _s(11.0) + _s(pose.right_hand[1]))
    far_hand = (cx - _s(2.5) + _s(pose.left_hand[0]), torso_top + _s(11.0) + _s(pose.left_hand[1]))
    near_foot = (cx + _s(2.5) + _s(pose.right_foot[0]), feet_y + _s(pose.right_foot[1]))
    far_foot = (cx - _s(2.0) + _s(pose.left_foot[0]), feet_y + _s(pose.left_foot[1]))

    _draw_profile_arm(draw, far_shoulder, far_hand, near=False)
    _draw_profile_leg(draw, (cx - _s(1.0), hip_y), far_foot, near=False, magic=magic_boots)
    _draw_profile_leg(draw, (cx + _s(1.5), hip_y), near_foot, near=True, magic=magic_boots)
    _draw_profile_skirt(draw, cx, hip_y - _s(1.5))
    _draw_profile_torso(draw, cx, torso_top)
    _draw_kerchief(draw, hcx - _s(1.0), torso_top - _s(0.5))
    _draw_profile_arm(draw, near_shoulder, near_hand, near=True)
    _draw_profile_head(draw, hcx, hcy, pose.hair_swing)
    return _downscale(img)


def draw_cowgirl_frame(pose: Pose, *, magic_boots: bool = False) -> Image.Image:
    if pose.profile:
        return draw_profile_frame(pose, magic_boots=magic_boots)
    img, draw = _canvas()
    cx = _s(32.0 + pose.lean)
    head_cy = _s(19.0 + pose.bob)
    torso_top = _s(30.5 + pose.bob)
    hip_y = _s(43.5 + pose.bob)
    feet_y = _s(60.0)

    left_foot = (cx - _s(4.5) + _s(pose.left_foot[0]), feet_y + _s(pose.left_foot[1]))
    right_foot = (cx + _s(4.5) + _s(pose.right_foot[0]), feet_y + _s(pose.right_foot[1]))
    left_shoulder = (cx - _s(7.0), torso_top + _s(2.0))
    right_shoulder = (cx + _s(7.0), torso_top + _s(2.0))
    left_hand = (cx - _s(8.5) + _s(pose.left_hand[0]), torso_top + _s(11.0) + _s(pose.left_hand[1]))
    right_hand = (cx + _s(8.5) + _s(pose.right_hand[0]), torso_top + _s(11.0) + _s(pose.right_hand[1]))

    # Pigtails hang behind the head/shoulders.
    _draw_pigtail(draw, (cx - _s(8.5), head_cy + _s(1.0)), (cx - _s(11.5), head_cy + _s(13.0)), -1, pose.hair_swing)
    _draw_pigtail(draw, (cx + _s(8.5), head_cy + _s(1.0)), (cx + _s(11.5), head_cy + _s(13.0)), 1, pose.hair_swing)

    # Legs behind the skirt, then body, then arms in front.
    _draw_leg(draw, (cx - _s(3.0), hip_y), left_foot, magic_boots)
    _draw_leg(draw, (cx + _s(3.0), hip_y), right_foot, magic_boots)
    _draw_skirt(draw, cx, hip_y - _s(1.5))
    _draw_torso(draw, cx, torso_top)
    _draw_kerchief(draw, cx, torso_top - _s(0.5))
    _draw_arm(draw, left_shoulder, left_hand, celebrate=pose.celebrate)
    _draw_arm(draw, right_shoulder, right_hand, celebrate=pose.celebrate)

    # Big head on top.
    _draw_face(draw, cx, head_cy)
    _draw_bangs(draw, cx, head_cy)
    _draw_hat(draw, cx, head_cy - _s(6.5))
    return _downscale(img)


def generate_all(output_dir: Path = OUTPUT_DIR) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    for name in FRAME_NAMES:
        pose = FRAME_POSES[name]
        for magic, suffix in ((False, ""), (True, "_boots")):
            path = output_dir / f"{name}{suffix}.png"
            draw_cowgirl_frame(pose, magic_boots=magic).save(path)
            print(f"wrote {path}")


if __name__ == "__main__":
    generate_all()
    print(f"Wrote handcrafted cowgirl frames to {OUTPUT_DIR}")
