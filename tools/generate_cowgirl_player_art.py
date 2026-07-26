#!/usr/bin/env python3
"""Build handcrafted cowgirl player sprites from cowboy frames + reference cues."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

from cowgirl_character import (
    add_eyelashes,
    add_pink_cuffs,
    jeans_to_skirt,
    trim_boyish_sideburns,
)
from cowgirl_hair import draw_player_cowgirl_hair

ROOT = Path(__file__).resolve().parents[1] / "assets" / "player"
COWBOY = ROOT
COWGIRL = ROOT / "cowgirl"

PLAYER_FRAMES = [
    "idle_0.png",
    "idle_1.png",
    "run_0.png",
    "run_1.png",
    "run_2.png",
    "run_3.png",
    "jump.png",
    "celebrate.png",
]


def _swing_for_frame(name: str) -> float:
    if "idle_1" in name:
        return 1.0
    if "run_0" in name:
        return -1.5
    if "run_1" in name:
        return 0.0
    if "run_2" in name:
        return 1.5
    if "run_3" in name:
        return 0.5
    if "jump" in name:
        return -2.0
    if "celebrate" in name:
        return 2.0
    return 0.0


def transform_frame(cowboy_path: Path, out_path: Path) -> None:
    img = Image.open(cowboy_path).convert("RGBA")
    jeans_to_skirt(img)
    add_pink_cuffs(img)
    trim_boyish_sideburns(img)
    draw_player_cowgirl_hair(img, _swing_for_frame(cowboy_path.name))
    add_eyelashes(img)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)
    print(f"wrote {out_path}")


def generate_all() -> None:
    COWGIRL.mkdir(parents=True, exist_ok=True)
    for name in PLAYER_FRAMES:
        transform_frame(COWBOY / name, COWGIRL / name)
        boots_name = name.replace(".png", "_boots.png")
        transform_frame(COWBOY / boots_name, COWGIRL / boots_name)


if __name__ == "__main__":
    generate_all()
    print(f"Wrote cowgirl frames to {COWGIRL}")
