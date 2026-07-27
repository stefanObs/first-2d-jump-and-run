#!/usr/bin/env python3
"""Generate handcrafted cowgirl player sprites from scratch (no cowboy source frames)."""

from __future__ import annotations

from pathlib import Path

from handcrafted_cowgirl import FRAME_POSES, draw_cowgirl_frame

ROOT = Path(__file__).resolve().parents[1] / "assets" / "player" / "cowgirl"

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


def generate_all() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    for name in PLAYER_FRAMES:
        stem = name.replace(".png", "")
        pose = FRAME_POSES[stem]
        out = ROOT / name
        draw_cowgirl_frame(pose, magic_boots=False).save(out)
        print(f"wrote {out}")
        boots_out = ROOT / f"{stem}_boots.png"
        draw_cowgirl_frame(pose, magic_boots=True).save(boots_out)
        print(f"wrote {boots_out}")


if __name__ == "__main__":
    generate_all()
    print(f"Wrote handcrafted cowgirl frames to {ROOT}")
