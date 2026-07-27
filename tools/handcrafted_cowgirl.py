#!/usr/bin/env python3
"""Hand-painted cowgirl player sprites — drawn from scratch (no cowboy source frames)."""

from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 64
SUPER = 2
CANVAS = SIZE * SUPER
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "player" / "cowgirl"

INK = (24, 16, 12, 255)
SKIN = (238, 192, 152, 255)
SKIN_BLUSH = (232, 138, 128, 255)
HAT = (210, 162, 96, 255)
HAT_SHADOW = (148, 102, 54, 255)
HAT_BAND = (196, 52, 42, 255)
HAIR = (214, 158, 62, 255)
HAIR_DARK = (118, 68, 18, 255)
HAIR_LIGHT = (248, 210, 108, 255)
SHIRT = (236, 214, 188, 255)
SHIRT_SHADOW = (196, 168, 138, 255)
YOKE = (88, 148, 158, 255)
YOKE_DARK = (58, 108, 118, 255)
CUFF = (214, 92, 108, 255)
CUFF_DARK = (178, 62, 82, 255)
BANDANA = (208, 48, 38, 255)
VEST = (156, 92, 58, 255)
JEANS = (72, 108, 168, 255)
JEANS_DARK = (48, 72, 128, 255)
BELT = (98, 62, 34, 255)
BRASS = (228, 188, 58, 255)
BOOT = (58, 36, 24, 255)
BOOT_LIGHT = (108, 72, 48, 255)
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
    "idle_1": Pose(bob=0.5, hair_swing=0.4),
    "run_0": Pose(left_leg=-2.0, right_leg=2.2, left_arm=1.8, right_arm=-1.8, hair_swing=-0.8, bob=0.4),
    "run_1": Pose(bob=0.7, left_arm=0.4, right_arm=-0.4),
    "run_2": Pose(left_leg=2.2, right_leg=-2.0, left_arm=-1.8, right_arm=1.8, hair_swing=0.8, bob=0.4),
    "run_3": Pose(bob=0.7, left_arm=-0.4, right_arm=0.4),
    "jump": Pose(bob=-1.2, left_leg=-2.5, right_leg=1.8, left_arm=-2.8, right_arm=-2.8, hair_swing=-1.2),
    "celebrate": Pose(bob=-0.8, left_arm=3.5, right_arm=3.5, hair_swing=1.0, celebrate=True),
}


def _s(value: float) -> float:
    return value * SUPER


def _line(
    draw: ImageDraw.ImageDraw,
    a: tuple[float, float],
    b: tuple[float, float],
    color: tuple[int, int, int, int],
    width: float,
) -> None:
    draw.line([a, b], fill=color, width=max(1, int(round(_s(width)))))


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


def _stroke_dot(
    draw: ImageDraw.ImageDraw,
    center: tuple[float, float],
    radius: float,
    fill: tuple[int, int, int, int],
) -> None:
    cx, cy = center
    r = _s(radius)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill, outline=INK, width=max(1, int(round(_s(0.55)))))


def _draw_boot(
    draw: ImageDraw.ImageDraw,
    toe: tuple[float, float],
    facing: str,
    magic: bool,
) -> None:
    tx, ty = toe
    color = MAGIC_BOOT if magic else BOOT
    hi = MAGIC_GLOW if magic else BOOT_LIGHT
    if facing == "right":
        box = (tx - _s(5.5), ty - _s(5.0), tx + _s(1.0), ty + _s(1.0))
        heel_x = tx - _s(4.0)
    else:
        box = (tx - _s(1.0), ty - _s(5.0), tx + _s(5.5), ty + _s(1.0))
        heel_x = tx + _s(4.0)
    draw.rounded_rectangle(box, radius=max(1, int(_s(1.5))), fill=color, outline=INK, width=max(1, int(_s(0.8))))
    draw.line([(heel_x, ty - _s(3.5)), (tx, ty - _s(4.5))], fill=hi, width=max(1, int(_s(0.8))))
    if magic:
        spark = (tx - _s(1.5), ty - _s(6.0))
        for dx, dy in ((0, 0), (_s(1.2), _s(-1.0)), (_s(-1.0), _s(-1.2))):
            sx, sy = spark[0] + dx, spark[1] + dy
            draw.line([(sx - _s(0.7), sy), (sx + _s(0.7), sy)], fill=MAGIC_GLOW, width=1)
            draw.line([(sx, sy - _s(0.7)), (sx, sy + _s(0.7))], fill=MAGIC_GLOW, width=1)


def _draw_leg(
    draw: ImageDraw.ImageDraw,
    hip: tuple[float, float],
    toe: tuple[float, float],
    facing: str,
    magic: bool,
) -> None:
    knee = ((hip[0] + toe[0]) * 0.5, (hip[1] + toe[1]) * 0.55)
    _line(draw, hip, knee, JEANS_DARK, 3.2)
    _line(draw, knee, toe, JEANS, 2.8)
    _line(draw, hip, toe, INK, 0.9)
    _draw_boot(draw, toe, facing, magic)


def _draw_arm(
    draw: ImageDraw.ImageDraw,
    shoulder: tuple[float, float],
    swing: float,
    side: str,
    celebrate: bool,
) -> None:
    sx, sy = shoulder
    if celebrate:
        hand = (sx + (_s(1.0) if side == "right" else -_s(1.0)), sy - _s(11.0))
    else:
        hand = (
            sx + (_s(4.5 + swing) if side == "right" else -_s(4.5 + swing)),
            sy + _s(5.0 + abs(swing) * 0.4),
        )
    elbow = ((sx + hand[0]) * 0.5, (sy + hand[1]) * 0.55)
    _line(draw, shoulder, elbow, SHIRT_SHADOW, 2.4)
    _line(draw, elbow, hand, SHIRT, 2.2)
    _line(draw, shoulder, hand, INK, 0.8)
    cuff = (hand[0], hand[1] + _s(0.5))
    draw.rectangle(
        (cuff[0] - _s(1.6), cuff[1] - _s(1.0), cuff[0] + _s(1.6), cuff[1] + _s(1.0)),
        fill=CUFF,
        outline=CUFF_DARK,
        width=1,
    )


def _draw_pigtail(
    draw: ImageDraw.ImageDraw,
    root: tuple[float, float],
    control: tuple[float, float],
    tip: tuple[float, float],
    side: str,
    swing: float,
) -> None:
    sway = _s(swing * (1.0 if side == "left" else -1.0))
    points = _bezier2(
        (root[0] + sway * 0.15, root[1]),
        (control[0] + sway, control[1]),
        (tip[0] + sway * 1.4, tip[1]),
        16,
    )
    for i, (cx, cy) in enumerate(points):
        t = i / max(1, len(points) - 1)
        radius = 2.3 - t * 0.9
        wave = math.sin(t * math.pi * 2.8) * (1.0 + abs(swing) * 0.2)
        px = cx + (_s(wave) if side == "left" else -_s(wave))
        tone = HAIR_LIGHT if t < 0.25 else HAIR if t < 0.7 else HAIR_DARK
        _stroke_dot(draw, (px, cy), radius, tone)
    rx, ry = root
    draw.ellipse((rx - _s(1.8), ry - _s(1.5), rx + _s(1.8), ry + _s(1.5)), fill=BANDANA, outline=INK, width=1)


def _draw_hat(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    brim_y = cy + _s(4.0)
    brim_box = (cx - _s(13.0), brim_y - _s(2.0), cx + _s(13.0), brim_y + _s(3.0))
    draw.pieslice(brim_box, start=10, end=170, fill=HAT)
    draw.arc(brim_box, start=10, end=170, fill=INK, width=max(1, int(_s(0.9))))
    crown = [
        (cx - _s(7.0), cy + _s(1.0)),
        (cx + _s(7.0), cy + _s(1.0)),
        (cx + _s(5.5), cy - _s(7.0)),
        (cx - _s(5.5), cy - _s(7.0)),
    ]
    draw.polygon(crown, fill=HAT, outline=INK)
    draw.rectangle((cx - _s(7.0), cy - _s(1.0), cx + _s(7.0), cy + _s(0.5)), fill=HAT_BAND)
    draw.pieslice((cx - _s(7.0), cy - _s(8.0), cx + _s(7.0), cy + _s(2.0)), start=205, end=335, fill=HAT_SHADOW)


def _draw_face(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    face_box = (cx - _s(6.5), cy - _s(6.5), cx + _s(6.5), cy + _s(6.5))
    draw.ellipse(face_box, fill=SKIN, outline=INK, width=max(1, int(_s(0.9))))
    draw.ellipse((cx - _s(4.8), cy - _s(0.8), cx - _s(1.2), cy + _s(2.0)), fill=SKIN_BLUSH)
    draw.ellipse((cx + _s(1.2), cy - _s(0.8), cx + _s(4.8), cy + _s(2.0)), fill=SKIN_BLUSH)
    for ex in (cx - _s(3.2), cx + _s(3.2)):
        draw.ellipse((ex - _s(1.6), cy - _s(2.2), ex + _s(1.6), cy + _s(0.8)), fill=EYE_WHITE)
        draw.ellipse((ex - _s(0.8), cy - _s(1.2), ex + _s(0.4), cy + _s(0.2)), fill=INK)
        draw.point((ex + _s(0.2), cy - _s(0.9)), fill=EYE_WHITE)
        for dx in (-1.4, -0.6, 0.6, 1.4):
            draw.point((ex + _s(dx * 0.45), cy - _s(2.4)), fill=INK)
    draw.arc((cx - _s(2.0), cy + _s(1.0), cx + _s(2.0), cy + _s(3.2)), start=10, end=170, fill=INK, width=max(1, int(_s(0.8))))


def _draw_bangs(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    for ox in range(-3, 4):
        x = cx + _s(float(ox) * 1.3)
        draw.line(
            [(x, cy - _s(6.0)), (x, cy - _s(2.8 if abs(ox) < 2 else 3.6))],
            fill=HAIR if ox % 2 else HAIR_LIGHT,
            width=max(1, int(_s(1.2))),
        )


def _draw_torso(draw: ImageDraw.ImageDraw, cx: float, top: float) -> None:
    shirt = [
        (cx - _s(7.0), top),
        (cx + _s(7.0), top),
        (cx + _s(6.0), top + _s(14.0)),
        (cx - _s(6.0), top + _s(14.0)),
    ]
    draw.polygon(shirt, fill=SHIRT, outline=INK)
    draw.polygon(
        [
            (cx - _s(6.5), top + _s(0.5)),
            (cx + _s(6.5), top + _s(0.5)),
            (cx + _s(4.0), top + _s(6.0)),
            (cx - _s(4.0), top + _s(6.0)),
        ],
        fill=YOKE,
        outline=YOKE_DARK,
    )
    draw.polygon(
        [
            (cx - _s(7.2), top + _s(6.5)),
            (cx + _s(7.2), top + _s(6.5)),
            (cx + _s(5.8), top + _s(14.0)),
            (cx - _s(5.8), top + _s(14.0)),
        ],
        fill=VEST,
        outline=INK,
    )
    belt_y = top + _s(13.2)
    draw.rectangle((cx - _s(7.0), belt_y, cx + _s(7.0), belt_y + _s(2.0)), fill=BELT, outline=INK, width=1)
    draw.rectangle((cx - _s(2.0), belt_y + _s(0.2), cx + _s(2.0), belt_y + _s(1.6)), fill=BRASS)


def _draw_bandana(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    draw.polygon(
        [(cx - _s(4.5), cy + _s(4.5)), (cx + _s(4.5), cy + _s(4.5)), (cx, cy + _s(7.5))],
        fill=BANDANA,
        outline=INK,
    )


def draw_cowgirl_frame(pose: Pose, *, magic_boots: bool = False) -> Image.Image:
    img = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = CANVAS * 0.5 + _s(pose.lean)
    head_y = _s(20.0 + pose.bob)
    torso_top = head_y + _s(11.0)
    hip_y = torso_top + _s(14.0)

    _draw_leg(draw, (cx - _s(3.5), hip_y), (cx - _s(5.0 + pose.left_leg), _s(58.0)), "left", magic_boots)
    _draw_leg(draw, (cx + _s(3.5), hip_y), (cx + _s(6.0 + pose.right_leg), _s(58.0)), "right", magic_boots)
    _draw_torso(draw, cx, torso_top)
    _draw_arm(draw, (cx - _s(7.0), torso_top + _s(4.0)), pose.left_arm, "left", pose.celebrate)
    _draw_arm(draw, (cx + _s(7.0), torso_top + _s(4.0)), pose.right_arm, "right", pose.celebrate)
    _draw_bandana(draw, cx, head_y + _s(1.0))
    _draw_face(draw, cx, head_y)
    _draw_bangs(draw, cx, head_y)
    for side, root_x, ctrl_x, tip_x in (
        ("left", -7.5, -11.0, -8.0),
        ("right", 7.5, 11.0, 8.0),
    ):
        _draw_pigtail(
            draw,
            (cx + _s(root_x), head_y + _s(0.5)),
            (cx + _s(ctrl_x), head_y + _s(14.0)),
            (cx + _s(tip_x), _s(46.0)),
            side,
            pose.hair_swing,
        )
    _draw_hat(draw, cx, head_y - _s(1.0))
    return img.resize((SIZE, SIZE), Image.Resampling.NEAREST)


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
