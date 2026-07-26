#!/usr/bin/env python3
"""Build mounted cowgirl horse sprites from cowboy horse art + cowgirl rider frames."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
WORLD = ROOT / "assets" / "world"
PLAYER = ROOT / "assets" / "player" / "cowgirl"

PAIRS = [
    ("cowboy_horse_ride_0.png", "cowgirl_horse_ride_0.png", "idle_0.png"),
    ("cowboy_horse_ride_1.png", "cowgirl_horse_ride_1.png", "run_1.png"),
    ("cowboy_horse_jump.png", "cowgirl_horse_jump.png", "jump.png"),
]

# Screen-space rider anchor tuned against the handmade cowboy mount sprites.
RIDER_ANCHOR = {
    "cowboy_horse_ride_0.png": (118, 88, 1.55),
    "cowboy_horse_ride_1.png": (118, 88, 1.55),
    "cowboy_horse_jump.png": (108, 72, 1.45),
}


def _rider_mask(size: tuple[int, int]) -> Image.Image:
    """Mask out the cowboy rider so we can paste the cowgirl on the same saddle."""
    w, h = size
    mask = Image.new("L", size, 0)
    px = mask.load()
    # Upper-body oval covering hat/vest region on the handmade mount sprites.
    cx, cy, rx, ry = int(w * 0.34), int(h * 0.22), int(w * 0.16), int(h * 0.18)
    for y in range(h):
        for x in range(w):
            dx = (x - cx) / max(rx, 1)
            dy = (y - cy) / max(ry, 1)
            if dx * dx + dy * dy <= 1.0:
                px[x, y] = 255
    return mask


def _erase_rider(base: Image.Image) -> Image.Image:
    """Sample nearby horse/saddle colors where the cowboy rider used to sit."""
    out = base.copy()
    mask = _rider_mask(base.size)
    mpx = mask.load()
    opx = out.load()
    w, h = base.size
    for y in range(h):
        for x in range(w):
            if mpx[x, y] < 128:
                continue
            # Prefer saddle red / horse brown samples from just outside the mask.
            sample = None
            for ox, oy in ((18, 26), (24, 30), (12, 34), (20, 38)):
                sx = min(w - 1, x + ox)
                sy = min(h - 1, y + oy)
                if mpx[sx, sy] < 64:
                    sample = opx[sx, sy]
                    break
            if sample is None:
                sample = (168, 96, 58, 255)
            opx[x, y] = sample
    return out


def _compose(cowboy_name: str, out_name: str, rider_file: str) -> None:
    cowboy_path = WORLD / cowboy_name
    rider_path = PLAYER / rider_file
    out_path = WORLD / out_name
    base = Image.open(cowboy_path).convert("RGBA")
    cleaned = _erase_rider(base)
    rider = Image.open(rider_path).convert("RGBA")
    ax, ay, scale = RIDER_ANCHOR[cowboy_name]
    rw, rh = rider.size
    tw = max(1, int(rw * scale))
    th = max(1, int(rh * scale))
    rider_scaled = rider.resize((tw, th), Image.Resampling.NEAREST)
    cleaned.alpha_composite(rider_scaled, (ax - tw // 2, ay - th // 2))
    cleaned.save(out_path)
    print(f"wrote {out_path}")


def main() -> None:
    for cowboy_name, out_name, rider_file in PAIRS:
        _compose(cowboy_name, out_name, rider_file)


if __name__ == "__main__":
    main()
