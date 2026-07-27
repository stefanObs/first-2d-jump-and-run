#!/usr/bin/env python3
"""Hand-painted cowgirl player sprites — bandit-quality 3/4 western style."""

from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 64
SUPER = 4
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "player" / "cowgirl"

# Palette aligned with cowboy / bandit cel-shaded props.
INK = (20, 16, 12, 255)
SKIN = (252, 192, 116, 255)
SKIN_SHADOW = (196, 132, 68, 255)
SKIN_BLUSH = (232, 128, 118, 255)
HAT = (144, 76, 16, 255)
HAT_LIGHT = (184, 108, 32, 255)
HAT_DARK = (76, 40, 8, 255)
HAT_BAND = (196, 52, 42, 255)
HAIR = (214, 158, 62, 255)
HAIR_DARK = (118, 68, 18, 255)
HAIR_LIGHT = (248, 210, 108, 255)
SHIRT = (100, 152, 192, 255)
SHIRT_SHADOW = (68, 108, 148, 255)
SHIRT_LIGHT = (136, 176, 208, 255)
VEST = (60, 32, 4, 255)
VEST_SHADOW = (40, 20, 4, 255)
VEST_LIGHT = (92, 52, 16, 255)
CUFF = (214, 92, 108, 255)
CUFF_DARK = (178, 62, 82, 255)
BANDANA = (208, 48, 38, 255)
BANDANA_DARK = (168, 32, 28, 255)
JEANS = (80, 108, 168, 255)
JEANS_DARK = (48, 68, 120, 255)
JEANS_LIGHT = (112, 136, 192, 255)
BELT = (76, 40, 8, 255)
BRASS = (228, 188, 58, 255)
BRASS_LIGHT = (255, 220, 120, 255)
BOOT = (108, 56, 8, 255)
BOOT_DARK = (60, 32, 4, 255)
BOOT_LIGHT = (152, 84, 24, 255)
MAGIC_BOOT = (168, 88, 220, 255)
MAGIC_GLOW = (232, 196, 255, 255)
EYE_WHITE = (252, 248, 242, 255)

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
    left_arm: float = 0.0
    right_arm: float = 0.0
    left_leg: float = 0.0
    right_leg: float = 0.0
    hair_swing: float = 0.0
    celebrate: bool = False


FRAME_POSES: dict[str, Pose] = {
    "idle_0": Pose(),
    "idle_1": Pose(bob=0.4, hair_swing=0.3),
    "run_0": Pose(left_leg=-2.5, right_leg=2.5, left_arm=2.0, right_arm=-2.0, hair_swing=-1.0, bob=0.5, lean=0.6),
    "run_1": Pose(bob=0.8, left_arm=0.6, right_arm=-0.6, lean=0.4),
    "run_2": Pose(left_leg=2.5, right_leg=-2.5, left_arm=-2.0, right_arm=2.0, hair_swing=1.0, bob=0.5, lean=0.6),
    "run_3": Pose(bob=0.8, left_arm=-0.6, right_arm=0.6, lean=0.4),
    "jump": Pose(bob=-1.5, left_leg=-3.0, right_leg=2.0, left_arm=-3.0, right_arm=-3.0, hair_swing=-1.5, lean=-0.4),
    "celebrate": Pose(bob=-1.0, left_arm=4.0, right_arm=4.0, hair_swing=1.2, celebrate=True, lean=-0.2),
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
    scaled = [(x, y) for x, y in points]
    draw.polygon(scaled, fill=fill)
    if outline:
        draw.line(scaled + [scaled[0]], fill=INK, width=_iw(width))


def _capsule(
    draw: ImageDraw.ImageDraw,
    a: tuple[float, float],
    b: tuple[float, float],
    radius: float,
    fill: tuple[int, int, int, int],
    shadow: tuple[int, int, int, int],
) -> None:
    ax, ay = a
    bx, by = b
    draw.line([a, b], fill=shadow, width=max(1, int(round(_s(radius * 2.2)))), joint="curve")
    draw.line([a, b], fill=fill, width=max(1, int(round(_s(radius * 1.8)))), joint="curve")
    draw.line([a, b], fill=INK, width=max(1, int(round(_s(radius * 0.45)))), joint="curve")
    for cx, cy in (a, b):
        r = _s(radius)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill, outline=INK, width=_iw(0.55))


def _bezier2(
    start: tuple[float, float],
    control: tuple[float, float],
    end: tuple[float, float],
    steps: int,
) -> list[tuple[float, float]]:
    points: list[tuple[float, float]] = []
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


def _draw_pigtail(
    draw: ImageDraw.ImageDraw,
    root: tuple[float, float],
    control: tuple[float, float],
    tip: tuple[float, float],
    side: str,
    swing: float,
) -> None:
    sway = _s(swing * (1.4 if side == "left" else -1.4))
    points = _bezier2(
        (root[0] + sway * 0.1, root[1]),
        (control[0] + sway, control[1]),
        (tip[0] + sway * 1.5, tip[1]),
        24,
    )
    for i, (cx, cy) in enumerate(points):
        t = i / max(1, len(points) - 1)
        radius = _s(2.6 - t * 1.1)
        wave = math.sin(t * math.pi * 3.0 + (0.5 if side == "right" else 0.0)) * _s(1.0 + abs(swing) * 0.25)
        px = cx + (wave if side == "left" else -wave)
        tone = HAIR_LIGHT if t < 0.22 else HAIR if t < 0.68 else HAIR_DARK
        draw.ellipse((px - radius, cy - radius, px + radius, cy + radius), fill=tone, outline=INK, width=_iw(0.45))
    rx, ry = root
    draw.ellipse(
        (rx - _s(1.6), ry - _s(1.4), rx + _s(1.6), ry + _s(1.4)),
        fill=BANDANA,
        outline=INK,
        width=_iw(0.5),
    )


def _draw_boot(
    draw: ImageDraw.ImageDraw,
    toe: tuple[float, float],
    heel: tuple[float, float],
    magic: bool,
) -> None:
    tx, ty = toe
    hx, hy = heel
    base = MAGIC_BOOT if magic else BOOT
    dark = _shade(base, 0.72) if magic else BOOT_DARK
    light = MAGIC_GLOW if magic else BOOT_LIGHT
    sole = [
        (hx, ty + _s(0.5)),
        (tx + _s(2.0), ty + _s(0.5)),
        (tx + _s(2.5), ty - _s(1.0)),
        (hx - _s(0.5), ty - _s(1.0)),
    ]
    upper = [
        (hx, ty - _s(1.0)),
        (tx + _s(2.5), ty - _s(1.0)),
        (tx + _s(2.0), ty - _s(5.5)),
        (hx - _s(0.5), ty - _s(5.0)),
    ]
    _poly(draw, sole, dark, width=0.9)
    _poly(draw, upper, base, width=1.0)
    draw.line([(tx + _s(0.5), ty - _s(4.8)), (tx + _s(1.8), ty - _s(5.2))], fill=light, width=_iw(0.7))
    if magic:
        spark = (tx + _s(1.0), ty - _s(6.5))
        for ox, oy in ((0, 0), (_s(0.8), _s(-0.7)), (_s(-0.6), _s(-0.8))):
            sx, sy = spark[0] + ox, spark[1] + oy
            draw.line([(sx - _s(0.5), sy), (sx + _s(0.5), sy)], fill=MAGIC_GLOW, width=1)
            draw.line([(sx, sy - _s(0.5)), (sx, sy + _s(0.5))], fill=MAGIC_GLOW, width=1)


def _draw_leg(
    draw: ImageDraw.ImageDraw,
    hip: tuple[float, float],
    knee: tuple[float, float],
    toe: tuple[float, float],
    magic: bool,
    *,
    front: bool,
) -> None:
    fill = JEANS if front else JEANS_DARK
    shadow = JEANS_DARK if front else _shade(JEANS_DARK, 0.85)
    _capsule(draw, hip, knee, 2.0 if front else 1.7, fill, shadow)
    _capsule(draw, knee, toe, 1.7 if front else 1.5, fill, shadow)
    heel = (toe[0] - _s(3.2), toe[1])
    _draw_boot(draw, toe, heel, magic)


def _draw_arm(
    draw: ImageDraw.ImageDraw,
    shoulder: tuple[float, float],
    swing: float,
    side: str,
    celebrate: bool,
    *,
    front: bool,
) -> None:
    sx, sy = shoulder
    if celebrate:
        hand = (sx + (_s(0.5) if side == "right" else -_s(0.5)), sy - _s(10.5))
    else:
        hand = (
            sx + (_s(5.0 + swing) if side == "right" else -_s(4.0 + swing)),
            sy + _s(4.5 + abs(swing) * 0.35),
        )
    elbow = ((sx + hand[0]) * 0.52, (sy + hand[1]) * 0.58)
    fill = SHIRT if front else SHIRT_SHADOW
    shadow = SHIRT_SHADOW if front else _shade(SHIRT_SHADOW, 0.88)
    _capsule(draw, shoulder, elbow, 1.55 if front else 1.35, fill, shadow)
    _capsule(draw, elbow, hand, 1.35 if front else 1.2, fill, shadow)
    cuff = (hand[0] + (_s(-1.2) if side == "right" else _s(1.2)), hand[1] - _s(0.8))
    draw.rounded_rectangle(
        (cuff[0] - _s(1.8), cuff[1] - _s(1.1), cuff[0] + _s(1.8), cuff[1] + _s(1.1)),
        radius=_s(0.5),
        fill=CUFF,
        outline=CUFF_DARK,
        width=1,
    )
    draw.ellipse(
        (hand[0] - _s(1.2), hand[1] - _s(1.2), hand[0] + _s(1.2), hand[1] + _s(1.2)),
        fill=SKIN,
        outline=INK,
        width=_iw(0.45),
    )


def _draw_hat(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    brim_y = cy + _s(5.0)
    # Asymmetric brim — longer on the right for a 3/4 read.
    brim = (cx - _s(13.0), brim_y - _s(2.5), cx + _s(18.0), brim_y + _s(3.0))
    draw.pieslice(brim, start=8, end=168, fill=HAT)
    draw.pieslice((cx - _s(12.0), brim_y - _s(1.5), cx + _s(12.0), brim_y + _s(2.0)), start=10, end=155, fill=HAT_LIGHT)
    draw.arc(brim, start=8, end=168, fill=INK, width=_iw(1.0))
    crown = [
        (cx - _s(7.5), cy + _s(1.5)),
        (cx + _s(9.0), cy + _s(0.5)),
        (cx + _s(7.0), cy - _s(8.5)),
        (cx - _s(5.5), cy - _s(8.0)),
    ]
    _poly(draw, crown, HAT, width=1.0)
    draw.pieslice((cx - _s(7.0), cy - _s(9.0), cx + _s(8.0), cy + _s(2.0)), start=205, end=330, fill=HAT_DARK)
    draw.rectangle((cx - _s(7.5), cy - _s(1.5), cx + _s(9.0), cy + _s(0.5)), fill=HAT_BAND)
    draw.line([(cx - _s(7.5), cy - _s(1.5)), (cx + _s(9.0), cy - _s(1.5))], fill=INK, width=_iw(0.6))


def _draw_face(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    face = (cx - _s(6.0), cy - _s(7.0), cx + _s(7.5), cy + _s(7.0))
    draw.ellipse(face, fill=SKIN, outline=INK, width=_iw(1.0))
    draw.pieslice((cx - _s(6.0), cy - _s(7.0), cx + _s(7.5), cy + _s(7.0)), start=200, end=340, fill=SKIN_SHADOW)
    draw.ellipse((cx - _s(4.5), cy - _s(0.5), cx - _s(0.5), cy + _s(2.5)), fill=SKIN_BLUSH)
    draw.ellipse((cx + _s(1.0), cy - _s(0.5), cx + _s(4.5), cy + _s(2.0)), fill=SKIN_BLUSH)
    # 3/4 eyes — larger bandit-style ovals with gleam
    for ex, flip in ((cx - _s(2.8), 1.0), (cx + _s(3.8), -1.0)):
        draw.ellipse((ex - _s(2.0), cy - _s(3.0), ex + _s(2.0), cy + _s(1.2)), fill=EYE_WHITE, outline=INK, width=_iw(0.45))
        draw.ellipse((ex - _s(1.2), cy - _s(2.0), ex + _s(0.8), cy + _s(0.5)), fill=INK)
        gleam_x = ex + _s(0.5 * flip)
        draw.ellipse((gleam_x - _s(0.45), cy - _s(1.5), gleam_x + _s(0.2), cy - _s(0.8)), fill=EYE_WHITE)
        for dx in (-1.6, -0.7, 0.7):
            draw.point((ex + _s(dx * 0.45), cy - _s(3.2)), fill=INK)
    draw.arc((cx - _s(1.5), cy + _s(1.5), cx + _s(3.5), cy + _s(4.0)), start=10, end=165, fill=INK, width=_iw(0.75))
    draw.line([(cx + _s(4.8), cy - _s(0.5)), (cx + _s(5.8), cy + _s(1.0))], fill=_shade(SKIN, 0.88), width=_iw(0.5))


def _draw_bangs(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    for i, ox in enumerate(range(-3, 4)):
        x = cx + _s(float(ox) * 1.4 - 0.3)
        tone = HAIR_LIGHT if i % 2 == 0 else HAIR
        draw.line(
            [(x, cy - _s(7.0)), (x, cy - _s(2.5 if abs(ox) < 2 else 3.5))],
            fill=tone,
            width=max(1, int(round(_s(1.3)))),
        )


def _draw_bandana(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    _poly(
        draw,
        [(cx - _s(5.0), cy + _s(5.0)), (cx + _s(5.5), cy + _s(4.5)), (cx + _s(1.0), cy + _s(9.0))],
        BANDANA,
        width=0.9,
    )
    draw.line([(cx - _s(5.0), cy + _s(5.0)), (cx + _s(1.0), cy + _s(9.0))], fill=BANDANA_DARK, width=_iw(0.55))


def _draw_torso(draw: ImageDraw.ImageDraw, cx: float, top: float) -> None:
    shirt = [
        (cx - _s(7.5), top),
        (cx + _s(9.0), top + _s(0.5)),
        (cx + _s(7.5), top + _s(15.0)),
        (cx - _s(6.0), top + _s(14.5)),
    ]
    _poly(draw, shirt, SHIRT, width=1.0)
    draw.line([(cx + _s(2.0), top + _s(2.0)), (cx + _s(5.5), top + _s(7.0))], fill=SHIRT_LIGHT, width=_iw(0.8))
    vest = [
        (cx - _s(8.0), top + _s(6.0)),
        (cx + _s(9.2), top + _s(6.5)),
        (cx + _s(7.5), top + _s(15.0)),
        (cx - _s(6.5), top + _s(14.5)),
    ]
    _poly(draw, vest, VEST, width=1.0)
    draw.line([(cx - _s(0.5), top + _s(6.5)), (cx - _s(0.5), top + _s(14.5))], fill=VEST_SHADOW, width=_iw(0.65))
    draw.line([(cx + _s(5.5), top + _s(6.8)), (cx + _s(6.0), top + _s(14.0))], fill=VEST_LIGHT, width=_iw(0.55))
    belt_y = top + _s(13.8)
    draw.rounded_rectangle(
        (cx - _s(7.5), belt_y, cx + _s(7.8), belt_y + _s(2.2)),
        radius=_s(0.4),
        fill=BELT,
        outline=INK,
        width=_iw(0.55),
    )
    draw.rounded_rectangle(
        (cx - _s(2.2), belt_y + _s(0.25), cx + _s(2.4), belt_y + _s(1.8)),
        radius=_s(0.25),
        fill=BRASS,
        outline=_shade(BRASS, 0.82),
        width=1,
    )
    draw.point((cx - _s(1.2), belt_y + _s(0.8)), fill=BRASS_LIGHT)


def draw_cowgirl_frame(pose: Pose, *, magic_boots: bool = False) -> Image.Image:
    img, draw = _canvas()
    cx = _s(29.5 + pose.lean)
    head_y = _s(14.5 + pose.bob)
    torso_top = head_y + _s(10.5)
    hip_y = torso_top + _s(13.5)

    left_toe = (cx - _s(4.5 + pose.left_leg), _s(59.5))
    left_knee = (left_toe[0] + _s(0.5), (hip_y + left_toe[1]) * 0.58)
    right_toe = (cx + _s(6.0 + pose.right_leg), _s(59.0))
    right_knee = (right_toe[0] - _s(1.0), (hip_y + right_toe[1]) * 0.56)

    _draw_pigtail(
        draw,
        (cx - _s(9.0), head_y + _s(1.0)),
        (cx - _s(13.0), head_y + _s(16.0)),
        (cx - _s(10.0), _s(48.0)),
        "left",
        pose.hair_swing,
    )
    _draw_leg(draw, (cx - _s(3.0), hip_y), left_knee, left_toe, magic_boots, front=False)
    _draw_leg(draw, (cx + _s(3.5), hip_y), right_knee, right_toe, magic_boots, front=True)
    _draw_arm(draw, (cx - _s(7.5), torso_top + _s(4.0)), pose.left_arm, "left", pose.celebrate, front=False)
    _draw_torso(draw, cx, torso_top)
    _draw_arm(draw, (cx + _s(8.0), torso_top + _s(3.5)), pose.right_arm, "right", pose.celebrate, front=True)
    _draw_bandana(draw, cx, head_y + _s(0.5))
    _draw_face(draw, cx, head_y)
    _draw_bangs(draw, cx, head_y)
    _draw_pigtail(
        draw,
        (cx + _s(7.5), head_y + _s(1.5)),
        (cx + _s(12.0), head_y + _s(15.0)),
        (cx + _s(9.0), _s(47.0)),
        "right",
        pose.hair_swing,
    )
    _draw_hat(draw, cx, head_y - _s(1.0))
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
