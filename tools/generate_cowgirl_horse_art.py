#!/usr/bin/env python3
"""Build mounted cowgirl horse sprites — horse kept, rider redone as cowgirl."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

from cowgirl_hair import draw_mounted_cowgirl_hair

ROOT = Path(__file__).resolve().parents[1]
WORLD = ROOT / "assets" / "world"

CUFF = (214, 92, 108, 255)
CUFF_DARK = (178, 62, 82, 255)

HORSE_FRAMES = [
    "cowboy_horse_ride_0.png",
    "cowboy_horse_ride_1.png",
    "cowboy_horse_jump.png",
]


def _is_shirt(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and b > 70 and abs(r - b) < 35 and g > 55 and r < 150


def _mounted_pink_cuffs(img: Image.Image) -> None:
    px = img.load()
    for y in range(68, 82):
        for x in range(130, 215):
            if _is_shirt(*px[x, y][:4]) and (x < 148 or x > 196):
                px[x, y] = CUFF if y % 2 == 0 else CUFF_DARK


def transform_horse(src: Path, dst: Path) -> None:
    img = Image.open(src).convert("RGBA")
    draw_mounted_cowgirl_hair(img, src.name)
    _mounted_pink_cuffs(img)
    img.save(dst)
    print(f"wrote {dst}")


def main() -> None:
    for cowboy_name in HORSE_FRAMES:
        out_name = cowboy_name.replace("cowboy_", "cowgirl_")
        transform_horse(WORLD / cowboy_name, WORLD / out_name)


if __name__ == "__main__":
    main()
