#!/usr/bin/env python3
"""Assemble README showcase media from real in-game screenshots.

1. Capture screenshots via Godot (needs a display — not --headless):
     godot --path . res://tools/capture_readme_screenshots.tscn
2. This script turns boss stills into a strip and frame sequences into GIFs.
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "showcase"


def font(size: int) -> ImageFont.ImageFont:
    for candidate in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    ):
        if Path(candidate).is_file():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def find_godot() -> str:
    env = os.environ.get("GODOT_BIN") or os.environ.get("GODOT")
    if env and Path(env).exists():
        return env
    for name in ("godot", "godot4", str(Path.home() / ".local/bin/godot")):
        try:
            subprocess.run([name, "--version"], check=True, capture_output=True)
            return name
        except (FileNotFoundError, subprocess.CalledProcessError):
            continue
    raise SystemExit("Godot not found (set GODOT_BIN)")


def capture_screenshots() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    godot = find_godot()
    cmd = [
        godot,
        "--path",
        str(ROOT),
        "res://tools/capture_readme_screenshots.tscn",
    ]
    print("running:", " ".join(cmd))
    # Real display required so the viewport is not a black dummy buffer.
    env = os.environ.copy()
    if not env.get("DISPLAY"):
        raise SystemExit("DISPLAY is unset — run on a desktop session (not --headless).")
    proc = subprocess.run(cmd, cwd=ROOT, env=env)
    if proc.returncode != 0:
        raise SystemExit(f"Godot capture failed with exit {proc.returncode}")


def caption(path: Path, title: str, subtitle: str) -> None:
    img = Image.open(path).convert("RGB")
    # Skip if a previous build already appended the caption bar (720 + 54).
    if img.height >= 774 and img.width == 1280:
        print(f"already captioned {path.relative_to(ROOT)}")
        return
    bar_h = 54
    out = Image.new("RGB", (img.width, img.height + bar_h), (42, 24, 12))
    out.paste(img, (0, 0))
    draw = ImageDraw.Draw(out)
    draw.rectangle((0, img.height, img.width, img.height + bar_h), fill=(72, 42, 22))
    draw.text((18, img.height + 8), title, fill=(255, 236, 196), font=font(22))
    draw.text((18, img.height + 32), subtitle, fill=(230, 190, 140), font=font(14))
    out.save(path, optimize=True)
    print(f"captioned {path.relative_to(ROOT)}")


def build_bosses_strip() -> None:
    parts = [
        ("boss_bull.png", "Stampede Bull"),
        ("boss_coach.png", "Midnight Coach"),
        ("boss_kingpin.png", "Outlaw Kingpin"),
        ("boss_dragon.png", "Cave Dragon"),
    ]
    cells: list[tuple[Image.Image, str]] = []
    for name, label in parts:
        path = OUT / name
        if not path.is_file():
            print(f"skip missing {name}")
            continue
        im = Image.open(path).convert("RGB")
        # Crop center square-ish gameplay frame.
        side = min(im.width, im.height)
        left = (im.width - side) // 2
        top = max(0, (im.height - side) // 2 - 40)
        crop = im.crop((left, top, left + side, top + side)).resize((280, 280), Image.Resampling.LANCZOS)
        cells.append((crop, label))
    if not cells:
        return
    pad = 16
    cell_w = 280
    w = pad + len(cells) * (cell_w + pad)
    h = cell_w + 70
    canvas = Image.new("RGB", (w, h), (48, 28, 14))
    draw = ImageDraw.Draw(canvas)
    draw.text((pad, 12), "Bosses — screenshots from the fights", fill=(255, 236, 196), font=font(22))
    for i, (crop, label) in enumerate(cells):
        x = pad + i * (cell_w + pad)
        canvas.paste(crop, (x, 44))
        draw.rectangle((x, 44, x + cell_w - 1, 44 + cell_w - 1), outline=(160, 90, 40), width=3)
        draw.text((x + 8, 44 + cell_w + 6), label, fill=(255, 220, 170), font=font(15))
    out = OUT / "bosses.png"
    canvas.save(out, optimize=True)
    print(f"wrote {out.relative_to(ROOT)}")


def _is_blank_frame(path: Path) -> bool:
    """Reject dummy/cleared viewport dumps (tiny PNG or near-uniform color)."""
    if path.stat().st_size < 20_000:
        return True
    im = Image.open(path).convert("RGB")
    flat = im.get_flattened_data()
    step = max(1, len(flat) // (3 * 4000)) * 3
    sample = [flat[i : i + 3] for i in range(0, len(flat) - 2, step)]
    if not sample:
        return True
    mean = sum(sum(px) for px in sample) / (3 * len(sample))
    # Cleared viewports land near black or near mid-gray flat fills.
    spread = max(sum(px) for px in sample) - min(sum(px) for px in sample)
    return mean < 8 or spread < 12


def gif_from_prefix(prefix: str, out_name: str, *, duration_ms: int = 90, max_frames: int = 24) -> None:
    frames = [p for p in sorted(OUT.glob(f"{prefix}_frame_*.png")) if not _is_blank_frame(p)][
        :max_frames
    ]
    if len(frames) < 2:
        print(f"skip gif {out_name}: need frames for {prefix}")
        return
    images: list[Image.Image] = []
    for path in frames:
        im = Image.open(path).convert("RGB")
        # Compact README weight: half-HD + 64-color palette.
        im = im.resize((480, 270), Image.Resampling.LANCZOS)
        im = im.quantize(colors=64, method=Image.Quantize.MEDIANCUT).convert("P")
        images.append(im)
    out = OUT / out_name
    images[0].save(
        out,
        save_all=True,
        append_images=images[1:],
        duration=duration_ms,
        loop=0,
        optimize=True,
    )
    print(f"wrote {out.relative_to(ROOT)} ({out.stat().st_size // 1024} KiB, {len(images)} frames)")
    for path in OUT.glob(f"{prefix}_frame_*.png"):
        path.unlink(missing_ok=True)


def main() -> int:
    do_capture = "--skip-capture" not in sys.argv
    if do_capture:
        capture_screenshots()
    else:
        print("skipping Godot capture (--skip-capture)")

    required = [
        "title_card.png",
        "desert_trail.png",
        "cave_trail.png",
    ]
    missing = [n for n in required if not (OUT / n).is_file()]
    if missing:
        raise SystemExit(f"Missing screenshots: {', '.join(missing)}")

    # Reject near-black captures (headless/dummy renderer).
    for name in required:
        im = Image.open(OUT / name).convert("RGB")
        pixels = list(im.get_flattened_data())
        n = max(1, len(pixels) // 3)
        dark = sum(1 for i in range(n) if pixels[i * 3] + pixels[i * 3 + 1] + pixels[i * 3 + 2] < 40)
        if dark / n > 0.92:
            raise SystemExit(
                f"{name} looks blank/black — re-run capture on a real display (not --headless)."
            )

    caption(OUT / "title_card.png", "Title screen", "In-game screenshot — save slots & cowboy/cowgirl settings.")
    caption(OUT / "desert_trail.png", "Desert trail", "In-game screenshot — Dusty Trail gameplay.")
    if (OUT / "desert_canyon.png").is_file():
        caption(OUT / "desert_canyon.png", "Canyon ferry", "In-game screenshot — clouds and canyon hops.")
    caption(OUT / "cave_trail.png", "Cave arc", "In-game screenshot — Crystal Mouth.")
    if (OUT / "cave_bats.png").is_file():
        caption(OUT / "cave_bats.png", "Bat Gallery", "In-game screenshot — cave bats and ceiling.")

    build_bosses_strip()
    gif_from_prefix("run", "gameplay_run.gif", duration_ms=100)
    gif_from_prefix("dragon", "dragon_fly.gif", duration_ms=110)

    # Remove old collage-only motion assets if still present and unused.
    for stale in (
        "cowboy_run.gif",
        "cowgirl_run.gif",
        "horse_ride.gif",
        "cave_bat.gif",
        "boss_bull.png",
        "boss_coach.png",
        "boss_kingpin.png",
        "boss_dragon.png",
    ):
        # Keep individual boss shots optional; strip is the README face.
        if stale.startswith("boss_"):
            continue
        p = OUT / stale
        if p.is_file() and stale not in ("dragon_fly.gif",):
            # Keep only the new gameplay loops.
            if stale in ("cowboy_run.gif", "cowgirl_run.gif", "horse_ride.gif", "cave_bat.gif"):
                p.unlink()
                print(f"removed stale collage gif {stale}")

    print("showcase ready in", OUT.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
