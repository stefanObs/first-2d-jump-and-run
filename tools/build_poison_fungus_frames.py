#!/usr/bin/env python3
"""Build poison fungus spore-puff animation frames from the idle mushroom art.

Frames (64x80, feet on baseline):
  0 idle — soft resting vapor
  1 swell — cap lifts, spores gather under the gills
  2 burst — spores fan outward with a toxic green puff
  3 drift — cloud thins as spores float away
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "world" / "poison_fungus.png"
OUT = ROOT / "assets" / "world"

W, H = 64, 80
# Cap sits near the top of the framed sprite; stem foot on bottom.
CAP_CX, CAP_CY = 32, 28
STEM_TOP = 34


def _load_base() -> Image.Image:
    if not SRC.exists():
        raise SystemExit(f"missing {SRC}")
    return Image.open(SRC).convert("RGBA")


def _draw_vapor(
    im: Image.Image,
    rng: random.Random,
    *,
    strength: float,
    rise: float,
    spread: float,
) -> None:
    """Soft lime vapor columns beside the stem."""
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    for side in (-1, 1):
        for i in range(5):
            x = CAP_CX + side * (10 + int(spread * (4 + i)))
            y0 = STEM_TOP + 8 - int(rise * 6)
            for step in range(10):
                t = step / 9.0
                xx = x + int(side * 2.5 * math.sin(t * math.pi * 1.4 + i))
                yy = y0 - int(t * (18 + rise * 14))
                rad = max(1, int((2.2 + strength * 2.5) * (1.0 - t * 0.45)))
                a = int((90 + strength * 90) * (1.0 - t * 0.7))
                g = 170 + rng.randint(-20, 30)
                col = (90 + rng.randint(-10, 20), g, 70 + rng.randint(-15, 20), a)
                d.ellipse((xx - rad, yy - rad, xx + rad, yy + rad), fill=col)
    im.alpha_composite(overlay)


def _draw_spores(
    im: Image.Image,
    rng: random.Random,
    *,
    count: int,
    radius: float,
    alpha: float,
    outward: float,
) -> None:
    """Bright spore dots fanning from under the cap."""
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    for i in range(count):
        ang = -math.pi * 0.15 + (math.pi * 1.3) * (i / max(1, count - 1))
        dist = radius * (0.35 + 0.65 * ((i * 37) % 10) / 10.0) * outward
        x = CAP_CX + math.cos(ang) * dist * 1.15
        y = CAP_CY + 6 + math.sin(ang) * dist * 0.55 + rng.uniform(-1.5, 1.5)
        # Mix lime and pale spores.
        if rng.random() < 0.55:
            col = (230, 255, 190, int(220 * alpha))
        else:
            col = (255, 255, 255, int(200 * alpha))
        r = 1 if rng.random() < 0.7 else 2
        d.ellipse((x - r, y - r, x + r, y + r), fill=col)
    im.alpha_composite(overlay)


def build_frames() -> list[Path]:
    base = _load_base()
    specs = [
        # strength, rise, spread, spore_count, spore_r, spore_a, outward, swell
        ("poison_fungus_0.png", 0.35, 0.2, 0.4, 6, 6.0, 0.55, 0.4, 0.0),
        ("poison_fungus_1.png", 0.7, 0.55, 0.75, 12, 9.0, 0.85, 0.7, 0.55),
        ("poison_fungus_2.png", 1.0, 1.0, 1.2, 22, 16.0, 1.0, 1.15, 0.35),
        ("poison_fungus_3.png", 0.55, 1.15, 1.0, 14, 20.0, 0.55, 1.35, 0.1),
    ]
    paths: list[Path] = []
    for name, strength, rise, spread, count, radius, alpha, outward, swell in specs:
        rng = random.Random(hash(name) & 0xFFFF)
        frame = base.copy()
        _draw_vapor(frame, rng, strength=strength, rise=rise, spread=spread)
        _draw_spores(
            frame,
            rng,
            count=count,
            radius=radius,
            alpha=alpha,
            outward=outward,
        )
        # Mild cap bob: shift a soft highlight on the crown for the swell beat.
        if swell > 0.2:
            d = ImageDraw.Draw(frame)
            a = int(40 + swell * 50)
            d.ellipse(
                (CAP_CX - 10, CAP_CY - 12, CAP_CX + 10, CAP_CY - 2),
                fill=(255, 180, 190, a),
            )
        path = OUT / name
        frame.save(path)
        paths.append(path)
        print(f"wrote {path.relative_to(ROOT)} {frame.size}")

    # Stamp / legacy path stays the idle pose.
    idle = OUT / "poison_fungus_0.png"
    if idle.exists():
        Image.open(idle).convert("RGBA").save(OUT / "poison_fungus.png")
        print("wrote assets/world/poison_fungus.png (idle)")
    return paths


if __name__ == "__main__":
    build_frames()
