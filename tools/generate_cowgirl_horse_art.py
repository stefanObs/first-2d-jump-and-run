#!/usr/bin/env python3
"""Build mounted cowgirl horse sprites — horse kept, rider redone as cowgirl."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

from cowgirl_character import mounted_pink_cuffs, trim_mounted_sideburns
from cowgirl_hair import draw_mounted_cowgirl_hair

ROOT = Path(__file__).resolve().parents[1]
WORLD = ROOT / "assets" / "world"

HORSE_FRAMES = [
    "cowboy_horse_ride_0.png",
    "cowboy_horse_ride_1.png",
    "cowboy_horse_jump.png",
]


def transform_horse(src: Path, dst: Path) -> None:
    img = Image.open(src).convert("RGBA")
    px = img.load()
    trim_mounted_sideburns(px, img.width, img.height)
    draw_mounted_cowgirl_hair(img, src.name)
    mounted_pink_cuffs(img)
    img.save(dst)
    print(f"wrote {dst}")


def main() -> None:
    for cowboy_name in HORSE_FRAMES:
        out_name = cowboy_name.replace("cowboy_", "cowgirl_")
        transform_horse(WORLD / cowboy_name, WORLD / out_name)


if __name__ == "__main__":
    main()
