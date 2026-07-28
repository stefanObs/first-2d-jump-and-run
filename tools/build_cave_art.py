#!/usr/bin/env python3
"""Cut out and frame cave biome concept art into shipped world assets."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from tools.art_pipeline import cutout, frame_sprite, slice_strip
from tools.fix_cave_visuals import clear_skeleton_bow_gaps, _magenta_tint  # noqa: E402
from collections import deque

from PIL import Image

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


def _force_split_halves(im: Image.Image, *, gap: int = 8) -> list[Image.Image]:
    bbox = im.getbbox()
    if bbox is None:
        return []
    x0, y0, x1, y1 = bbox
    mid = (x0 + x1) // 2
    half = max(1, gap // 2)
    left = im.crop((x0, y0, max(x0 + 1, mid - half), y1))
    right = im.crop((min(x1 - 1, mid + half), y0, x1, y1))
    return [f for f in (left, right) if f.getbbox() is not None]


def _keep_largest_component(im: Image.Image, *, alpha_thresh: int = 8) -> Image.Image:
    out = im.copy()
    w, h = out.size
    px = out.load()
    visited = [[False] * w for _ in range(h)]
    comps: list[list[tuple[int, int]]] = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] <= alpha_thresh or visited[y][x]:
                continue
            q: deque[tuple[int, int]] = deque([(x, y)])
            visited[y][x] = True
            pixels: list[tuple[int, int]] = []
            while q:
                cx, cy = q.popleft()
                pixels.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if (
                        0 <= nx < w
                        and 0 <= ny < h
                        and not visited[ny][nx]
                        and px[nx, ny][3] > alpha_thresh
                    ):
                        visited[ny][nx] = True
                        q.append((nx, ny))
            comps.append(pixels)
    if len(comps) <= 1:
        return out
    comps.sort(key=len, reverse=True)
    for pixels in comps[1:]:
        for x, y in pixels:
            r, g, b, _ = px[x, y]
            px[x, y] = (r, g, b, 0)
    return out


def _clean_bat_figure(fig: Image.Image, *, index: int) -> Image.Image:
    return _keep_largest_component(fig)


def _slice_bat_figures(cut: Image.Image) -> list[Image.Image]:
    figs = slice_strip(cut)
    if len(figs) < 2:
        figs = _force_split_halves(cut)
    return [_clean_bat_figure(f, index=i) for i, f in enumerate(figs[:2])]


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
        # Skeleton concept plates use a stubborn mid-gray matte below the default key.
        if out_name.startswith("skeleton") and out_name != "skeleton_arrow.png":
            cut = cutout(dest_src, level=185, sat=40)
        else:
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
        figures = slice_strip(cutout(walk_src, level=185, sat=40))
        for i, fig in enumerate(figures[:2]):
            framed = _feet(fig, (64, 80), target_h=67, baseline=76)
            path = OUT_DIR / f"skeleton_walk_{i}.png"
            framed.save(path)
            print(f"wrote {path.relative_to(ROOT)} {framed.size}")
    bat_src = CONCEPT_DIR / "cave_bat_strip_concept.png"
    if bat_src.is_file():
        shutil.copy2(bat_src, SOURCE_DIR / bat_src.name)
        figures = _slice_bat_figures(cutout(bat_src, level=185))
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

    # Clear opaque bow-triangle fill, then crystal bounty = magenta tint of bases.
    from PIL import Image

    for base in ["skeleton.png", "skeleton_walk_0.png", "skeleton_walk_1.png", "skeleton_tied.png"]:
        src = OUT_DIR / base
        if not src.is_file():
            continue
        im = Image.open(src).convert("RGBA")
        im, cleared = clear_skeleton_bow_gaps(im)
        im.save(src)
        if cleared:
            print(f"cleared {cleared} bow-gap pixels in {src.relative_to(ROOT)}")
        tinted = _magenta_tint(im)
        dest = OUT_DIR / base.replace("skeleton", "skeleton_crystal", 1)
        tinted.save(dest)
        print(f"wrote {dest.relative_to(ROOT)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
