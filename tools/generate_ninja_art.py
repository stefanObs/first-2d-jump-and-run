#!/usr/bin/env python3
"""Hand-painted trail ninja sprites and shuriken.

Chibi cel-shaded western style matching the bandit / cowgirl props: big head,
chunky little body, thick ink outlines, shadow + highlight layers, drawn at 4x
supersample and downscaled to the 64x80 prop size (shuriken is 28x28).
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "assets" / "world"
W, H = 64, 80
SUPER = 4

# Palette aligned with cowboy / bandit cel-shaded props (thick ink, cool navy gi).
INK = (18, 14, 22, 255)
GI = (48, 56, 84, 255)
GI_DARK = (28, 33, 54, 255)
GI_LIGHT = (78, 90, 124, 255)
MASK = (34, 40, 62, 255)
MASK_DARK = (20, 24, 42, 255)
MASK_LIGHT = (60, 70, 100, 255)
SKIN = (250, 202, 142, 255)
SKIN_SHADOW = (204, 148, 92, 255)
SASH = (200, 48, 42, 255)
SASH_DARK = (150, 28, 26, 255)
SASH_LIGHT = (234, 96, 74, 255)
HEADBAND = (206, 46, 42, 255)
HEADBAND_LIGHT = (238, 96, 72, 255)
TABI = (36, 42, 62, 255)
TABI_DARK = (22, 26, 42, 255)
TABI_LIGHT = (64, 72, 100, 255)
GLOVE = (30, 34, 52, 255)
EYE_WHITE = (248, 248, 242, 255)
BLADE = (206, 214, 226, 255)
BLADE_LIGHT = (246, 250, 255, 255)
GUARD = (198, 152, 56, 255)
HANDLE = (88, 52, 26, 255)
ROPE = (200, 152, 72, 255)
ROPE_DARK = (150, 104, 44, 255)
ROPE_LIGHT = (232, 194, 112, 255)
STAR = (202, 210, 222, 255)
STAR_LIGHT = (247, 251, 255, 255)
STAR_DARK = (118, 128, 148, 255)


@dataclass(frozen=True)
class Pose:
    bob: float = 0.0
    lean: float = 0.0
    back_hand: tuple[float, float] = (-2.5, 6.0)
    front_hand: tuple[float, float] = (4.0, 6.0)
    back_toe: float = 0.0
    front_toe: float = 0.0
    band_swing: float = 0.0


def _s(value: float) -> float:
    return value * SUPER


def _canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (W * SUPER, H * SUPER), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def _downscale(img: Image.Image, w: int = W, h: int = H) -> Image.Image:
    return img.resize((w, h), Image.Resampling.NEAREST)


def _iw(width: float = 1.0) -> int:
    return max(1, int(round(_s(width))))


def _shade(color: tuple[int, int, int, int], amount: float) -> tuple[int, int, int, int]:
    return (
        max(0, min(255, int(color[0] * amount))),
        max(0, min(255, int(color[1] * amount))),
        max(0, min(255, int(color[2] * amount))),
        color[3],
    )


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


def _draw_tabi(draw: ImageDraw.ImageDraw, toe: tuple[float, float], front: bool) -> None:
    tx, ty = toe
    base = TABI if front else TABI_DARK
    # Split-toe boot: short upper + sole wedge pointing right (facing dir).
    upper = [
        (tx - _s(3.0), ty - _s(4.5)),
        (tx + _s(2.4), ty - _s(4.5)),
        (tx + _s(2.8), ty - _s(0.5)),
        (tx - _s(3.0), ty - _s(0.5)),
    ]
    sole = [
        (tx - _s(3.2), ty - _s(1.0)),
        (tx + _s(4.6), ty - _s(1.0)),
        (tx + _s(4.8), ty + _s(0.6)),
        (tx - _s(3.2), ty + _s(0.6)),
    ]
    _poly(draw, sole, TABI_DARK, width=0.8)
    _poly(draw, upper, base, width=0.9)
    # Split-toe notch.
    draw.line([(tx + _s(2.0), ty - _s(2.0)), (tx + _s(2.0), ty - _s(0.6))], fill=INK, width=_iw(0.5))
    draw.line([(tx - _s(2.4), ty - _s(4.0)), (tx + _s(1.6), ty - _s(4.0))], fill=TABI_LIGHT, width=_iw(0.5))


def _draw_leg(
    draw: ImageDraw.ImageDraw,
    hip: tuple[float, float],
    toe: tuple[float, float],
    *,
    front: bool,
) -> None:
    fill = GI if front else GI_DARK
    shadow = GI_DARK if front else _shade(GI_DARK, 0.82)
    knee = ((hip[0] + toe[0]) * 0.5 + (_s(-0.4) if front else _s(0.4)), (hip[1] + toe[1]) * 0.54)
    ankle = (toe[0], toe[1] - _s(4.2))
    _capsule(draw, hip, knee, 2.0 if front else 1.7, fill, shadow)
    _capsule(draw, knee, ankle, 1.7 if front else 1.5, fill, shadow)
    _draw_tabi(draw, toe, front)


def _draw_arm(
    draw: ImageDraw.ImageDraw,
    shoulder: tuple[float, float],
    hand: tuple[float, float],
    *,
    front: bool,
) -> None:
    fill = GI if front else GI_DARK
    shadow = GI_DARK if front else _shade(GI_DARK, 0.85)
    elbow = ((shoulder[0] + hand[0]) * 0.5, (shoulder[1] + hand[1]) * 0.5 + _s(1.0))
    _capsule(draw, shoulder, elbow, 1.55 if front else 1.35, fill, shadow)
    _capsule(draw, elbow, hand, 1.35 if front else 1.2, fill, shadow)
    # Wrapped glove / fist.
    r = _s(1.7)
    draw.ellipse((hand[0] - r, hand[1] - r, hand[0] + r, hand[1] + r), fill=GLOVE, outline=INK, width=_iw(0.5))


def _draw_torso(draw: ImageDraw.ImageDraw, cx: float, top: float) -> None:
    # Narrow back (left), wide front (right) — same 3/4 mass as cowboy/bandit.
    gi = [
        (cx - _s(6.5), top + _s(0.5)),
        (cx + _s(9.5), top),
        (cx + _s(8.5), top + _s(16.0)),
        (cx - _s(5.5), top + _s(15.5)),
    ]
    _poly(draw, gi, GI, width=1.0)
    draw.line([(cx + _s(3.0), top + _s(2.0)), (cx + _s(6.8), top + _s(9.0))], fill=GI_LIGHT, width=_iw(0.8))
    # Crossed gi lapel.
    lapel = [
        (cx - _s(4.0), top + _s(0.8)),
        (cx + _s(4.5), top + _s(1.8)),
        (cx + _s(1.5), top + _s(10.5)),
        (cx - _s(2.5), top + _s(9.5)),
    ]
    _poly(draw, lapel, GI_DARK, width=0.6)
    draw.line([(cx + _s(4.5), top + _s(1.8)), (cx - _s(1.5), top + _s(10.8))], fill=INK, width=_iw(0.6))
    # Red obi sash at the waist with a side knot.
    obi_y = top + _s(11.5)
    draw.rectangle((cx - _s(6.0), obi_y, cx + _s(9.0), obi_y + _s(3.2)), fill=SASH)
    draw.line([(cx - _s(6.0), obi_y), (cx + _s(9.0), obi_y)], fill=SASH_DARK, width=_iw(0.5))
    draw.line([(cx - _s(6.0), obi_y + _s(3.2)), (cx + _s(9.0), obi_y + _s(3.2))], fill=SASH_DARK, width=_iw(0.5))
    draw.line([(cx - _s(5.0), obi_y + _s(1.5)), (cx + _s(8.0), obi_y + _s(1.5))], fill=SASH_LIGHT, width=_iw(0.6))
    draw.rounded_rectangle(
        (cx - _s(1.5), obi_y - _s(0.6), cx + _s(1.8), obi_y + _s(4.4)),
        radius=_s(0.6),
        fill=SASH_DARK,
        outline=INK,
        width=_iw(0.45),
    )


def _draw_head(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    band_swing: float = 0.0,
    *,
    look: float = 1.0,
    slump: float = 0.0,
) -> None:
    cy = cy + _s(slump)
    hood = (cx - _s(9.5), cy - _s(9.5), cx + _s(11.5), cy + _s(9.5))
    # Headband knot + trailing tails (behind the head, drawn first).
    knot = (cx - _s(8.5), cy - _s(3.5))
    for i, (dx, dy) in enumerate(((-8.5, 3.0), (-7.5, -2.2))):
        sway = band_swing * (1.0 if i == 0 else 0.6)
        tail = [
            knot,
            (knot[0] + _s(dx * 0.55), knot[1] + _s(dy * 0.5 + sway * 0.5)),
            (knot[0] + _s(dx), knot[1] + _s(dy + sway)),
        ]
        draw.line(tail, fill=HEADBAND if i == 0 else HEADBAND_LIGHT, width=_iw(1.5))
        tip = tail[-1]
        notch = [
            tip,
            (tip[0] - _s(1.6), tip[1] - _s(1.2)),
            (tip[0] - _s(1.2), tip[1] + _s(1.4)),
        ]
        _poly(draw, notch, HEADBAND if i == 0 else HEADBAND_LIGHT, width=0.5)

    # Hood dome (dark cloth), right-biased for the 3/4 read.
    draw.ellipse(hood, fill=MASK, outline=INK, width=_iw(1.0))
    draw.pieslice(hood, start=95, end=250, fill=MASK_DARK)
    draw.pieslice((cx - _s(7.0), cy - _s(9.0), cx + _s(9.0), cy + _s(3.5)), start=250, end=352, fill=MASK_LIGHT)
    draw.ellipse(hood, outline=INK, width=_iw(1.0))

    # Eye slit (skin) across the middle, right-biased.
    slit = (cx - _s(5.5), cy - _s(1.4), cx + _s(9.5), cy + _s(2.6))
    draw.rounded_rectangle(slit, radius=_s(1.6), fill=SKIN, outline=INK, width=_iw(0.6))
    draw.line([(cx - _s(5.0), cy + _s(2.2)), (cx + _s(9.0), cy + _s(2.2))], fill=SKIN_SHADOW, width=_iw(0.55))

    # Near (right) eye — dominant; far (left) eye — smaller.
    ex = cx + _s(4.6)
    draw.ellipse((ex - _s(2.2), cy - _s(1.0), ex + _s(2.2), cy + _s(2.2)), fill=EYE_WHITE, outline=INK, width=_iw(0.4))
    draw.ellipse(
        (ex - _s(0.8) + _s(look * 0.6), cy + _s(0.0), ex + _s(1.3) + _s(look * 0.6), cy + _s(1.9)),
        fill=INK,
    )
    fx = cx - _s(1.4)
    draw.ellipse((fx - _s(1.5), cy - _s(0.6), fx + _s(1.5), cy + _s(1.9)), fill=EYE_WHITE, outline=INK, width=_iw(0.35))
    draw.ellipse(
        (fx - _s(0.4) + _s(look * 0.4), cy + _s(0.1), fx + _s(0.8) + _s(look * 0.4), cy + _s(1.5)),
        fill=INK,
    )
    # Sharp brows.
    draw.line([(cx - _s(2.8), cy - _s(1.6)), (cx + _s(0.4), cy - _s(0.8))], fill=INK, width=_iw(0.7))
    draw.line([(cx + _s(2.6), cy - _s(1.0)), (cx + _s(6.8), cy - _s(1.8))], fill=INK, width=_iw(0.8))

    # Red headband over the forehead.
    band_y = cy - _s(3.6)
    draw.rectangle((cx - _s(9.0), band_y - _s(1.7), cx + _s(10.6), band_y + _s(1.8)), fill=HEADBAND)
    draw.line([(cx - _s(9.0), band_y - _s(1.7)), (cx + _s(10.6), band_y - _s(1.7))], fill=INK, width=_iw(0.5))
    draw.line([(cx - _s(9.0), band_y + _s(1.8)), (cx + _s(10.6), band_y + _s(1.8))], fill=INK, width=_iw(0.5))
    draw.line([(cx - _s(6.0), band_y - _s(0.2)), (cx + _s(7.0), band_y - _s(0.2))], fill=HEADBAND_LIGHT, width=_iw(0.6))
    draw.ellipse(
        (knot[0] - _s(1.7), knot[1] - _s(1.7), knot[0] + _s(1.7), knot[1] + _s(1.7)),
        fill=HEADBAND,
        outline=INK,
        width=_iw(0.5),
    )


def _draw_front_head(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    # Symmetric front-facing hood, matching the cowboy idle's straight-on look.
    hood = (cx - _s(10.0), cy - _s(9.5), cx + _s(10.0), cy + _s(9.5))
    # Headband tails knotted to the left.
    knot = (cx - _s(9.0), cy - _s(3.4))
    for i, (dx, dy) in enumerate(((-7.5, 2.8), (-6.8, -2.2))):
        tail = [knot, (knot[0] + _s(dx * 0.55), knot[1] + _s(dy * 0.5)), (knot[0] + _s(dx), knot[1] + _s(dy))]
        draw.line(tail, fill=HEADBAND if i == 0 else HEADBAND_LIGHT, width=_iw(1.5))

    draw.ellipse(hood, fill=MASK, outline=INK, width=_iw(1.0))
    draw.pieslice(hood, start=110, end=250, fill=MASK_DARK)
    draw.pieslice((cx - _s(7.5), cy - _s(9.0), cx + _s(7.5), cy + _s(2.5)), start=250, end=290, fill=MASK_LIGHT)
    draw.ellipse(hood, outline=INK, width=_iw(1.0))

    # Centered eye slit with two symmetric eyes.
    slit = (cx - _s(7.5), cy - _s(1.2), cx + _s(7.5), cy + _s(2.6))
    draw.rounded_rectangle(slit, radius=_s(1.6), fill=SKIN, outline=INK, width=_iw(0.6))
    draw.line([(cx - _s(7.0), cy + _s(2.2)), (cx + _s(7.0), cy + _s(2.2))], fill=SKIN_SHADOW, width=_iw(0.55))
    for ex in (cx - _s(3.8), cx + _s(3.8)):
        draw.ellipse((ex - _s(2.1), cy - _s(1.0), ex + _s(2.1), cy + _s(2.2)), fill=EYE_WHITE, outline=INK, width=_iw(0.4))
        draw.ellipse((ex - _s(0.9), cy + _s(0.1), ex + _s(1.1), cy + _s(1.9)), fill=INK)
        draw.ellipse((ex - _s(0.1), cy + _s(0.2), ex + _s(0.6), cy + _s(0.9)), fill=EYE_WHITE)
    # Angled brows (alert).
    draw.line([(cx - _s(5.6), cy - _s(1.8)), (cx - _s(1.8), cy - _s(0.8))], fill=INK, width=_iw(0.7))
    draw.line([(cx + _s(5.6), cy - _s(1.8)), (cx + _s(1.8), cy - _s(0.8))], fill=INK, width=_iw(0.7))

    # Headband across the forehead.
    band_y = cy - _s(3.6)
    draw.rectangle((cx - _s(9.6), band_y - _s(1.7), cx + _s(9.6), band_y + _s(1.8)), fill=HEADBAND)
    draw.line([(cx - _s(9.6), band_y - _s(1.7)), (cx + _s(9.6), band_y - _s(1.7))], fill=INK, width=_iw(0.5))
    draw.line([(cx - _s(9.6), band_y + _s(1.8)), (cx + _s(9.6), band_y + _s(1.8))], fill=INK, width=_iw(0.5))
    draw.line([(cx - _s(6.0), band_y - _s(0.2)), (cx + _s(6.0), band_y - _s(0.2))], fill=HEADBAND_LIGHT, width=_iw(0.6))
    draw.ellipse((knot[0] - _s(1.7), knot[1] - _s(1.7), knot[0] + _s(1.7), knot[1] + _s(1.7)), fill=HEADBAND, outline=INK, width=_iw(0.5))


def _draw_katana(draw: ImageDraw.ImageDraw, grip: tuple[float, float], tip: tuple[float, float]) -> None:
    draw.line([grip, tip], fill=INK, width=max(1, int(round(_s(2.3)))), joint="curve")
    draw.line([grip, tip], fill=BLADE, width=max(1, int(round(_s(1.5)))), joint="curve")
    # Edge highlight offset slightly perpendicular.
    dx, dy = tip[0] - grip[0], tip[1] - grip[1]
    length = math.hypot(dx, dy) or 1.0
    nx, ny = -dy / length, dx / length
    off = _s(0.5)
    draw.line(
        [(grip[0] + nx * off, grip[1] + ny * off), (tip[0] + nx * off, tip[1] + ny * off)],
        fill=BLADE_LIGHT,
        width=_iw(0.4),
    )
    # Handle behind the grip (opposite the tip).
    hx = grip[0] - dx * 0.24
    hy = grip[1] - dy * 0.24
    draw.line([grip, (hx, hy)], fill=HANDLE, width=max(1, int(round(_s(1.4)))), joint="curve")
    # Brass tsuba guard.
    draw.ellipse((grip[0] - _s(1.7), grip[1] - _s(1.7), grip[0] + _s(1.7), grip[1] + _s(1.7)), fill=GUARD, outline=INK, width=_iw(0.5))


def _draw_hand_shuriken(draw: ImageDraw.ImageDraw, cx: float, cy: float, rot: float, r: float = 3.6) -> None:
    pts = []
    for i in range(8):
        ang = rot + i * math.pi / 4.0
        radius = r if i % 2 == 0 else r * 0.4
        pts.append((cx + math.cos(ang) * _s(radius), cy + math.sin(ang) * _s(radius)))
    _poly(draw, pts, STAR, width=0.5)
    draw.ellipse((cx - _s(0.7), cy - _s(0.7), cx + _s(0.7), cy + _s(0.7)), fill=STAR_DARK)


def _figure_anchors(pose: Pose) -> dict[str, tuple[float, float]]:
    cx = _s(30.0 + pose.lean)
    head_y = _s(18.0 + pose.bob)
    torso_top = head_y + _s(11.0)
    front_shoulder = (cx + _s(7.0), torso_top + _s(3.5))
    back_shoulder = (cx - _s(3.0), torso_top + _s(4.0))
    return {
        "cx": (cx, 0.0),
        "head": (cx, head_y),
        "torso_top": (cx, torso_top),
        "front_shoulder": front_shoulder,
        "back_shoulder": back_shoulder,
        "front_hand": (front_shoulder[0] + _s(pose.front_hand[0]), front_shoulder[1] + _s(pose.front_hand[1])),
        "back_hand": (back_shoulder[0] + _s(pose.back_hand[0]), back_shoulder[1] + _s(pose.back_hand[1])),
    }


def _draw_figure(draw: ImageDraw.ImageDraw, pose: Pose, *, look: float = 1.0) -> dict[str, tuple[float, float]]:
    a = _figure_anchors(pose)
    cx = a["cx"][0]
    torso_top = a["torso_top"][1]
    hip_y = torso_top + _s(15.0)
    back_toe = (cx - _s(5.0) + _s(pose.back_toe), _s(74.0))
    front_toe = (cx + _s(6.5) + _s(pose.front_toe), _s(75.0))

    _draw_leg(draw, (cx - _s(1.5), hip_y), back_toe, front=False)
    _draw_arm(draw, a["back_shoulder"], a["back_hand"], front=False)
    _draw_torso(draw, cx, torso_top)
    _draw_leg(draw, (cx + _s(3.5), hip_y), front_toe, front=True)
    _draw_arm(draw, a["front_shoulder"], a["front_hand"], front=True)
    _draw_head(draw, a["head"][0], a["head"][1], pose.band_swing, look=look)
    return a


def draw_idle() -> Image.Image:
    # Front-facing ready stance, matching the cowboy's straight-on idle.
    img, draw = _canvas()
    cx = _s(30.0)
    head_y = _s(18.0)
    torso_top = head_y + _s(11.0)
    hip_y = torso_top + _s(15.0)
    feet_y = _s(74.0)
    left_shoulder = (cx - _s(6.5), torso_top + _s(3.2))
    right_shoulder = (cx + _s(6.5), torso_top + _s(3.2))
    left_hand = (cx - _s(7.3), torso_top + _s(11.5))
    right_hand = (cx + _s(7.3), torso_top + _s(11.5))

    _draw_leg(draw, (cx - _s(2.5), hip_y), (cx - _s(4.5), feet_y), front=False)
    _draw_leg(draw, (cx + _s(2.5), hip_y), (cx + _s(4.5), feet_y), front=True)
    _draw_torso(draw, cx, torso_top)
    _draw_arm(draw, left_shoulder, left_hand, front=False)
    _draw_arm(draw, right_shoulder, right_hand, front=True)
    _draw_front_head(draw, cx, head_y)
    return _downscale(img)


def draw_run(phase: int) -> Image.Image:
    # 3/4 right-facing run cycle, matching the cowboy run stride and lean.
    img, draw = _canvas()
    if phase == 0:
        pose = Pose(lean=2.0, bob=0.6, back_hand=(-4.0, 3.5), front_hand=(6.0, 2.5), back_toe=-4.5, front_toe=4.5, band_swing=-2.4)
    else:
        pose = Pose(lean=1.6, bob=1.2, back_hand=(-1.0, 6.5), front_hand=(3.0, 6.0), back_toe=3.5, front_toe=-3.5, band_swing=1.8)
    _draw_figure(draw, pose)
    return _downscale(img)


def draw_sword(phase: int) -> Image.Image:
    img, draw = _canvas()
    if phase == 0:
        pose = Pose(lean=-1.0, bob=-0.3, back_hand=(-3.0, 5.5), front_hand=(3.0, -9.0), band_swing=-1.5)
        a = _draw_figure(draw, pose, look=1.0)
        grip = a["front_hand"]
        tip = (grip[0] - _s(8.0), grip[1] - _s(9.5))
        _draw_katana(draw, grip, tip)
    else:
        pose = Pose(lean=2.0, bob=0.4, back_hand=(-2.0, 5.0), front_hand=(9.0, 4.5), band_swing=2.5)
        a = _draw_figure(draw, pose, look=1.0)
        grip = a["front_hand"]
        tip = (grip[0] + _s(11.0), grip[1] + _s(7.0))
        # Motion arc of the slash.
        draw.arc(
            (grip[0] - _s(6.0), grip[1] - _s(11.0), grip[0] + _s(13.0), grip[1] + _s(9.0)),
            start=300,
            end=20,
            fill=(255, 255, 255, 150),
            width=_iw(0.6),
        )
        _draw_katana(draw, grip, tip)
    return _downscale(img)


def draw_throw(phase: int) -> Image.Image:
    img, draw = _canvas()
    if phase == 0:
        pose = Pose(lean=-1.5, bob=-0.2, back_hand=(-3.0, 4.5), front_hand=(-1.0, -3.5), band_swing=-2.5)
        a = _draw_figure(draw, pose, look=1.0)
        hand = a["front_hand"]
        _draw_hand_shuriken(draw, hand[0], hand[1] - _s(1.5), 0.0)
    else:
        pose = Pose(lean=2.0, bob=0.3, back_hand=(-1.0, 5.5), front_hand=(10.0, -1.5), band_swing=2.0)
        a = _draw_figure(draw, pose, look=1.0)
        hand = a["front_hand"]
        _draw_hand_shuriken(draw, hand[0] + _s(3.5), hand[1] - _s(0.5), math.pi * 0.25, r=3.0)
        # Speed streaks trailing the throw.
        for oy in (-1.5, 0.0, 1.5):
            draw.line(
                [(hand[0] - _s(4.0), hand[1] + _s(oy)), (hand[0] + _s(1.0), hand[1] + _s(oy))],
                fill=(255, 255, 255, 110),
                width=_iw(0.4),
            )
    return _downscale(img)


def draw_tied() -> Image.Image:
    img, draw = _canvas()
    pose = Pose(bob=1.5, back_hand=(-1.0, 7.5), front_hand=(1.5, 7.5))
    a = _figure_anchors(pose)
    cx = a["cx"][0]
    torso_top = a["torso_top"][1]
    hip_y = torso_top + _s(15.0)
    # Slumped, seated bound ninja: knees tucked, arms pinned behind.
    left_toe = (cx - _s(3.0), _s(73.0))
    right_toe = (cx + _s(6.0), _s(73.5))
    _draw_leg(draw, (cx - _s(1.5), hip_y), left_toe, front=False)
    _draw_leg(draw, (cx + _s(3.0), hip_y), right_toe, front=True)
    _draw_torso(draw, cx, torso_top)
    # Bound arms hinted as small stubs at the sides (hands tied behind).
    _draw_arm(draw, a["back_shoulder"], (a["back_shoulder"][0] - _s(1.0), a["back_shoulder"][1] + _s(6.0)), front=False)
    _draw_arm(draw, a["front_shoulder"], (a["front_shoulder"][0] + _s(1.0), a["front_shoulder"][1] + _s(6.5)), front=True)
    _draw_head(draw, a["head"][0], a["head"][1], 0.0, look=0.4, slump=1.5)
    # Rope coils across the torso.
    for i in range(3):
        y = torso_top + _s(3.5 + i * 4.5)
        draw.line([(cx - _s(7.0), y), (cx + _s(9.5), y - _s(0.6))], fill=ROPE if i % 2 == 0 else ROPE_DARK, width=_iw(1.3))
        draw.line([(cx - _s(7.0), y - _s(0.5)), (cx + _s(4.0), y - _s(0.9))], fill=ROPE_LIGHT, width=_iw(0.4))
    # Vertical rope down the front and a knot.
    draw.line([(cx + _s(1.5), torso_top + _s(2.0)), (cx + _s(1.0), torso_top + _s(14.0))], fill=ROPE_DARK, width=_iw(0.9))
    draw.ellipse((cx - _s(0.5), torso_top + _s(7.5), cx + _s(2.5), torso_top + _s(10.5)), fill=ROPE, outline=INK, width=_iw(0.5))
    return _downscale(img)


def draw_shuriken() -> Image.Image:
    size = 28
    img = Image.new("RGBA", (size * SUPER, size * SUPER), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = cy = size * SUPER / 2.0
    ink_w = max(1, int(round(_s(0.9))))

    def star_points(tip: float, waist: float) -> list[tuple[float, float]]:
        pts = []
        for i in range(8):
            ang = i * math.pi / 4.0 - math.pi / 2.0
            radius = tip if i % 2 == 0 else waist
            pts.append((cx + math.cos(ang) * _s(radius), cy + math.sin(ang) * _s(radius)))
        return pts

    # Broad four-blade throwing star: wide waist keeps the blades solid, not spiky.
    outer = star_points(12.0, 6.4)
    draw.polygon(outer, fill=STAR)
    draw.line(outer + [outer[0]], fill=INK, width=ink_w)

    # Cel shade: light the upper-left blades, darken the lower-right.
    draw.polygon(
        [outer[0], outer[7], (cx, cy), outer[6], outer[5]],
        fill=STAR_LIGHT,
    )
    draw.polygon(
        [outer[2], outer[3], (cx, cy), outer[1]],
        fill=STAR_DARK,
    )
    # Blade centre ridges for a forged look.
    for i in range(0, 8, 2):
        draw.line([(cx, cy), outer[i]], fill=_shade(STAR, 0.88), width=max(1, int(round(_s(0.5)))))

    # Bolt hole in the middle.
    draw.ellipse((cx - _s(3.2), cy - _s(3.2), cx + _s(3.2), cy + _s(3.2)), fill=STAR_DARK, outline=INK, width=ink_w)
    draw.ellipse((cx - _s(1.7), cy - _s(1.7), cx + _s(1.7), cy + _s(1.7)), fill=(30, 34, 42, 255))

    # Crisp silhouette on top.
    draw.line(outer + [outer[0]], fill=INK, width=ink_w)
    return img.resize((size, size), Image.Resampling.NEAREST)


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    frames = {
        "ninja_idle.png": draw_idle(),
        "ninja_run_0.png": draw_run(0),
        "ninja_run_1.png": draw_run(1),
        "ninja_sword_0.png": draw_sword(0),
        "ninja_sword_1.png": draw_sword(1),
        "ninja_throw_0.png": draw_throw(0),
        "ninja_throw_1.png": draw_throw(1),
        "ninja_tied.png": draw_tied(),
        "ninja_shuriken.png": draw_shuriken(),
    }
    for name, image in frames.items():
        path = ROOT / name
        image.save(path)
        print("wrote", path)


if __name__ == "__main__":
    main()
