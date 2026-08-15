#!/usr/bin/env python3
"""Export stone frame, wood leaf, and trail peek textures for save-door hover."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from build_door_hover_concept import _crop_peek, _split_door  # noqa: E402

UI = ROOT / "assets" / "ui"


def main() -> int:
    door = Image.open(UI / "menu_save_door.png").convert("RGBA")
    stone, leaf = _split_door(door)
    desert = Image.open(ROOT / "docs" / "showcase" / "desert_trail.png").convert("RGB")
    cave = Image.open(ROOT / "docs" / "showcase" / "cave_trail.png").convert("RGB")
    peek_size = (210, 320)
    desert_peek = _crop_peek(desert, "desert", peek_size)
    cave_peek = _crop_peek(cave, "cave", peek_size)

    stone.save(UI / "menu_save_door_frame.png")
    leaf.save(UI / "menu_save_door_leaf.png")
    desert_peek.save(UI / "menu_door_peek_desert.png")
    cave_peek.save(UI / "menu_door_peek_cave.png")
    print("wrote frame, leaf, and peek textures under assets/ui/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
