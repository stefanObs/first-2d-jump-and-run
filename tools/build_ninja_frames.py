"""Build the ninja enemy sprite set from the approved hand-drawn concept art.

The ninja frames are hand-drawn (image-tool generated) concept art, keyed out
and framed into game-ready sprites via ``art_pipeline``. Source concepts live in
``assets/source/ninja/``; run this to regenerate ``assets/world/ninja_*.png``.

    python tools/build_ninja_frames.py

See ``.cursor/rules/art-style.mdc`` for the shared style + pipeline conventions.
Enemy character frames use a 64x80 canvas, body ~67 px tall, feet on y=76.
Idle/run/sword/throw/jump are 3/4 view facing right (the engine flips for the other
direction); action frames keep the katana compact so the body scale stays
consistent across the animation.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

from art_pipeline import cutout, slice_strip, frame_sprite

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "source" / "ninja"
OUT = ROOT / "assets" / "world"

CANVAS = (64, 80)
BASELINE = 76  # feet line
BODY_H = 67    # head-to-foot height, shared across the set


def _fig(path: str, target_h: int = BODY_H, baseline: int = BASELINE) -> Image.Image:
    return frame_sprite(cutout(str(SRC / path)), canvas=CANVAS, target_h=target_h, baseline=baseline)


def _strip(path: str, *, level: int = 208, sat: int = 22) -> list[Image.Image]:
    """Cut a horizontal strip into left-to-right figures (two largest if extras)."""
    keyed = cutout(str(SRC / path), level=level, sat=sat)
    segs = slice_strip(keyed, min_gap_frac=0.02)
    if len(segs) <= 2:
        return segs
    ranked = sorted(
        range(len(segs)),
        key=lambda i: segs[i].size[0] * segs[i].size[1],
        reverse=True,
    )[:2]
    return [segs[i] for i in sorted(ranked)]


def build() -> None:
    frames: dict[str, Image.Image] = {}
    frames["idle"] = _fig("idle.png")

    run = _strip("run_strip.png")
    frames["run_0"], frames["run_1"] = (
        frame_sprite(run[0], canvas=CANVAS, target_h=BODY_H, baseline=BASELINE),
        frame_sprite(run[1], canvas=CANVAS, target_h=BODY_H, baseline=BASELINE),
    )

    sword = _strip("sword_strip.png")
    frames["sword_0"], frames["sword_1"] = (
        frame_sprite(sword[0], canvas=CANVAS, target_h=BODY_H, baseline=BASELINE),
        frame_sprite(sword[1], canvas=CANVAS, target_h=BODY_H, baseline=BASELINE),
    )

    throw = _strip("throw_strip.png")
    frames["throw_0"], frames["throw_1"] = (
        frame_sprite(throw[0], canvas=CANVAS, target_h=BODY_H, baseline=BASELINE),
        frame_sprite(throw[1], canvas=CANVAS, target_h=BODY_H, baseline=BASELINE),
    )

    # Jump concept uses a flatter gray matte (~197) — lower cutout threshold.
    jump = _strip("jump_strip.png", level=185, sat=30)
    frames["jump_0"], frames["jump_1"] = (
        frame_sprite(jump[0], canvas=CANVAS, target_h=BODY_H, baseline=BASELINE),
        frame_sprite(jump[1], canvas=CANVAS, target_h=BODY_H, baseline=BASELINE),
    )

    # Seated captured pose sits a touch lower/shorter than the standing frames.
    frames["tied"] = _fig("tied.png", target_h=63, baseline=75)

    # Thrown-star projectile: centered in a 28x28 prop, not baseline-aligned.
    star = cutout(str(SRC / "shuriken.png"))
    star = star.crop(star.getbbox()).resize((26, 26), Image.LANCZOS)
    shuriken = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
    shuriken.alpha_composite(star, (1, 1))
    frames["shuriken"] = shuriken

    for name, img in frames.items():
        img.save(OUT / f"ninja_{name}.png")
        print(f"wrote assets/world/ninja_{name}.png {img.size}")


if __name__ == "__main__":
    build()
