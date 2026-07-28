#!/usr/bin/env python3
"""Frame dragon boss + fly/land + flameball art."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from tools.art_pipeline import cutout, frame_sprite  # noqa: E402

CONCEPT = Path(
    "/home/stefan/.cursor/projects/home-stefan-Projects-first-2d-jump-and-run/assets"
)
SOURCE = ROOT / "assets" / "source" / "dragon"
OUT = ROOT / "assets" / "world"


def main() -> int:
    SOURCE.mkdir(parents=True, exist_ok=True)
    for i in range(4):
        name = f"dragon_boss_{i}_concept.png"
        src = CONCEPT / name
        if not src.is_file():
            print("MISSING", src)
            continue
        shutil.copy2(src, SOURCE / name)
        framed = frame_sprite(cutout(src), canvas=(320, 200), target_h=180, baseline=199)
        dest = OUT / f"boss_cave_dragon_{i}.png"
        framed.save(dest)
        print("wrote", dest.relative_to(ROOT), framed.size)

    for src_name, dest_name in (
        ("dragon_fly_0_concept.png", "boss_cave_dragon_fly_0.png"),
        ("dragon_fly_1_concept.png", "boss_cave_dragon_fly_1.png"),
        ("dragon_fly_bound1_0_concept.png", "boss_cave_dragon_fly_bound1_0.png"),
        ("dragon_fly_bound1_1_concept.png", "boss_cave_dragon_fly_bound1_1.png"),
        ("dragon_fly_bound2_0_concept.png", "boss_cave_dragon_fly_bound2_0.png"),
        ("dragon_fly_bound2_1_concept.png", "boss_cave_dragon_fly_bound2_1.png"),
        ("dragon_land_concept.png", "boss_cave_dragon_land.png"),
    ):
        src = CONCEPT / src_name
        if not src.is_file():
            print("MISSING", src)
            continue
        shutil.copy2(src, SOURCE / src_name)
        framed = frame_sprite(
            cutout(src, level=185),
            canvas=(320, 200),
            target_h=180,
            baseline=199,
        )
        dest = OUT / dest_name
        framed.save(dest)
        print("wrote", dest.relative_to(ROOT), framed.size)

    flame = CONCEPT / "dragon_flameball_concept.png"
    if flame.is_file():
        shutil.copy2(flame, SOURCE / flame.name)
        framed = frame_sprite(cutout(flame), canvas=(48, 48), target_h=40, baseline=44)
        dest = OUT / "dragon_flameball.png"
        framed.save(dest)
        print("wrote", dest.relative_to(ROOT), framed.size)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
