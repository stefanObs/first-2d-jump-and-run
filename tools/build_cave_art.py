#!/usr/bin/env python3
"""Cut out and frame cave biome concept art into shipped world assets."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from tools.art_pipeline import cutout, frame_sprite, slice_strip  # noqa: E402

# Generated concepts land in the Cursor project assets folder.
CONCEPT_DIR = Path(
    "/home/stefan/.cursor/projects/home-stefan-Projects-first-2d-jump-and-run/assets"
)
SOURCE_DIR = ROOT / "assets" / "source" / "cave"
OUT_DIR = ROOT / "assets" / "world"

MAP = {
    "cave_poison_fungus_concept.png": "poison_fungus.png",
    "cave_lizard_stand_concept.png": "cave_lizard.png",
    "cave_lizard_tied_concept.png": "cave_lizard_tied_legs.png",
    "cave_lizard_down_concept.png": "cave_lizard_down.png",
    "cave_skeleton_idle_concept.png": "skeleton.png",
    "cave_skeleton_tied_concept.png": "skeleton_tied.png",
    "cave_scorpion_idle_concept.png": "scorpion_idle.png",
    "cave_scorpion_sting_concept.png": "scorpion_sting.png",
    "cave_crystal_gate_concept.png": "goal_crystal_gate.png",
    "cave_acid_drip_concept.png": "acid_drip.png",
    "cave_stalactite_concept.png": "stalactite.png",
    "cave_stalactite_impact_concept.png": "stalactite_impact.png",
    "cave_sky_concept.png": "cave_sky.png",
    "cave_floor_concept.png": "cave_floor_tile.png",
    "cave_dirt_concept.png": "cave_dirt_tile.png",
    "cave_plank_concept.png": "cave_plank.png",
    "cave_pit_concept.png": "cave_pit.png",
    "cave_camp_concept.png": "checkpoint_cave_active.png",
    "cave_arrow_concept.png": "skeleton_arrow.png",
}


def _fit(im, size: tuple[int, int]):
    from PIL import Image

    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    bbox = im.getbbox()
    if bbox is None:
        return canvas
    fig = im.crop(bbox)
    fw, fh = fig.size
    tw, th = size
    scale = min(tw / fw, th / fh)
    nw, nh = max(1, round(fw * scale)), max(1, round(fh * scale))
    fig = fig.resize((nw, nh), Image.LANCZOS)
    canvas.alpha_composite(fig, ((tw - nw) // 2, (th - nh) // 2))
    return canvas


def _feet(im, size: tuple[int, int], target_h: int | None = None, baseline: int | None = None):
    cw, ch = size
    th = target_h if target_h is not None else int(ch * 0.92)
    bl = baseline if baseline is not None else ch - 1
    return frame_sprite(im, canvas=size, target_h=th, baseline=bl)


def main() -> int:
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for src_name, out_name in MAP.items():
        src = CONCEPT_DIR / src_name
        if not src.is_file():
            print(f"MISSING {src}")
            continue
        dest_src = SOURCE_DIR / src_name
        shutil.copy2(src, dest_src)
        cut = cutout(dest_src)

        if out_name == "poison_fungus.png":
            out = _feet(cut, (64, 80), target_h=72, baseline=79)
        elif out_name.startswith("cave_lizard"):
            # Keep wide animal canvas similar to bull frames.
            out = _feet(cut, (320, 160), target_h=148, baseline=159)
        elif out_name.startswith("skeleton") and out_name != "skeleton_arrow.png":
            out = _feet(cut, (64, 80), target_h=67, baseline=76)
        elif out_name.startswith("scorpion"):
            out = _feet(cut, (220, 110), target_h=100, baseline=109)
        elif out_name == "goal_crystal_gate.png":
            out = _feet(cut, (96, 128), target_h=120, baseline=127)
        elif out_name == "acid_drip.png":
            out = _fit(cut, (28, 36))
        elif out_name == "stalactite.png":
            out = _feet(cut, (48, 96), target_h=90, baseline=95)
        elif out_name == "stalactite_impact.png":
            out = _fit(cut, (96, 64))
        elif out_name == "cave_sky.png":
            out = _fit(cut, (512, 384))
        elif out_name == "cave_floor_tile.png":
            out = _fit(cut, (200, 84))
        elif out_name == "cave_dirt_tile.png":
            out = _fit(cut, (200, 38))
        elif out_name == "cave_plank.png":
            out = _fit(cut, (180, 48))
        elif out_name == "cave_pit.png":
            out = _fit(cut, (128, 64))
        elif out_name == "checkpoint_cave_active.png":
            out = _feet(cut, (96, 96), target_h=88, baseline=95)
        elif out_name == "skeleton_arrow.png":
            out = _fit(cut, (40, 16))
        else:
            out = cut

        dest = OUT_DIR / out_name
        out.save(dest)
        print(f"wrote {dest.relative_to(ROOT)} {out.size}")

    # Walk strip → walk_0 / walk_1 (+ crystal bounty clones via tint later in code).
    walk_src = CONCEPT_DIR / "cave_skeleton_walk_strip_concept.png"
    if walk_src.is_file():
        shutil.copy2(walk_src, SOURCE_DIR / walk_src.name)
        figures = slice_strip(cutout(walk_src))
        for i, fig in enumerate(figures[:2]):
            framed = _feet(fig, (64, 80), target_h=67, baseline=76)
            path = OUT_DIR / f"skeleton_walk_{i}.png"
            framed.save(path)
            print(f"wrote {path.relative_to(ROOT)} {framed.size}")

    bat_src = CONCEPT_DIR / "cave_bat_strip_concept.png"
    if bat_src.is_file():
        shutil.copy2(bat_src, SOURCE_DIR / bat_src.name)
        figures = slice_strip(cutout(bat_src))
        for i, fig in enumerate(figures[:2]):
            framed = _fit(fig, (96, 64))
            path = OUT_DIR / f"cave_bat_{i}.png"
            framed.save(path)
            print(f"wrote {path.relative_to(ROOT)} {framed.size}")

    # Inactive camp: dim copy of active.
    active = OUT_DIR / "checkpoint_cave_active.png"
    if active.is_file():
        from PIL import Image, ImageEnhance

        im = Image.open(active).convert("RGBA")
        rgb = ImageEnhance.Brightness(im.convert("RGB")).enhance(0.72)
        out = Image.merge("RGBA", (*rgb.split(), im.split()[-1]))
        dest = OUT_DIR / "checkpoint_cave_inactive.png"
        out.save(dest)
        print(f"wrote {dest.relative_to(ROOT)}")

    # Crystal bounty skeleton: soft magenta tint of base frames.
    from PIL import Image

    for base in ["skeleton.png", "skeleton_walk_0.png", "skeleton_walk_1.png", "skeleton_tied.png"]:
        src = OUT_DIR / base
        if not src.is_file():
            continue
        im = Image.open(src).convert("RGBA")
        px = im.load()
        w, h = im.size
        for y in range(h):
            for x in range(w):
                r, g, b, a = px[x, y]
                if a < 8:
                    continue
                px[x, y] = (
                    min(255, int(r * 0.85 + 40)),
                    min(255, int(g * 0.7)),
                    min(255, int(b * 0.95 + 30)),
                    a,
                )
        dest = OUT_DIR / base.replace("skeleton", "skeleton_crystal")
        im.save(dest)
        print(f"wrote {dest.relative_to(ROOT)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
