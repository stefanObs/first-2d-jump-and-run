#!/usr/bin/env python3
"""Frame ladder prop + cowboy/cowgirl climb strips into shipped assets."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from tools.art_pipeline import cutout, frame_sprite, slice_strip  # noqa: E402

CONCEPT = Path(
    "/home/stefan/.cursor/projects/home-stefan-Projects-first-2d-jump-and-run/assets"
)
SOURCE = ROOT / "assets" / "source" / "ladder"
PLAYER = ROOT / "assets" / "player"
WORLD = ROOT / "assets" / "world"


def main() -> int:
    SOURCE.mkdir(parents=True, exist_ok=True)

    ladder_src = CONCEPT / "ladder_prop_concept.png"
    if ladder_src.is_file():
        shutil.copy2(ladder_src, SOURCE / ladder_src.name)
        cut = cutout(ladder_src)
        # Tall ladder tile ~40x120 (3 grid cells).
        framed = frame_sprite(cut, canvas=(48, 120), target_h=116, baseline=119)
        dest = WORLD / "ladder.png"
        framed.save(dest)
        print(f"wrote {dest.relative_to(ROOT)} {framed.size}")

    cowboy = CONCEPT / "cowboy_climb_strip_concept.png"
    if cowboy.is_file():
        shutil.copy2(cowboy, SOURCE / cowboy.name)
        figs = slice_strip(cutout(cowboy))
        for i, fig in enumerate(figs[:2]):
            framed = frame_sprite(fig, canvas=(64, 64), target_h=60, baseline=63)
            path = PLAYER / f"climb_{i}.png"
            framed.save(path)
            # Boots variants are identical copies (glow is in-engine).
            framed.save(PLAYER / f"climb_{i}_boots.png")
            print(f"wrote {path.relative_to(ROOT)}")

    cowgirl = CONCEPT / "cowgirl_climb_strip_concept.png"
    if cowgirl.is_file():
        shutil.copy2(cowgirl, SOURCE / cowgirl.name)
        figs = slice_strip(cutout(cowgirl))
        out_dir = PLAYER / "cowgirl"
        for i, fig in enumerate(figs[:2]):
            framed = frame_sprite(fig, canvas=(64, 64), target_h=60, baseline=63)
            path = out_dir / f"climb_{i}.png"
            framed.save(path)
            framed.save(out_dir / f"climb_{i}_boots.png")
            print(f"wrote {path.relative_to(ROOT)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
