#!/usr/bin/env python3
"""Export stone frame, solid wood leaf, and arch-clipped trail peeks for save doors."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
UI = ROOT / "assets" / "ui"
WOOD_FILL = (141, 86, 42, 255)


def _doorway_mask(size: tuple[int, int], *, inset: int = 0) -> Image.Image:
    """Opaque silhouette of the arched opening the wood leaf should fill."""
    w, h = size
    pad = 38 + inset
    top = 48 + inset
    bot = h - 58 - inset
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    inner_w = w - pad * 2
    arch_box = (pad, top, w - pad, top + inner_w)
    draw.pieslice(arch_box, 180, 360, fill=255)
    spring = top + inner_w // 2
    draw.rectangle((pad, spring, w - pad, bot), fill=255)
    return mask


def _split_solid_door(door: Image.Image) -> tuple[Image.Image, Image.Image, Image.Image]:
    """Return (stone_frame, solid_leaf, opening_mask). Leaf has no interior holes."""
    w, h = door.size
    opening = _doorway_mask((w, h), inset=0)
    # Tuck leaf rim under the stone so seams cannot leak the peek.
    opening_under_stone = opening.filter(ImageFilter.MaxFilter(3))

    wood_plate = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(wood_plate).bitmap((0, 0), opening_under_stone, fill=WOOD_FILL)
    clipped = door.copy()
    clipped.putalpha(ImageChops.multiply(door.split()[-1], opening_under_stone))
    leaf = Image.alpha_composite(wood_plate, clipped)

    frame = door.copy()
    fp = frame.load()
    om = opening_under_stone.load()
    for y in range(h):
        for x in range(w):
            if om[x, y] > 0:
                fp[x, y] = (0, 0, 0, 0)
    return frame, leaf, opening


def _crop_peek(src: Image.Image, kind: str, size: tuple[int, int]) -> Image.Image:
    h = min(720, src.height)
    base = src.crop((0, 0, src.width, h))
    if kind == "desert":
        box = (420, 180, 900, 560)
    else:
        box = (380, 140, 900, 560)
    return base.crop(box).resize(size, Image.Resampling.LANCZOS)


def _arch_peek(src: Image.Image, kind: str, opening: Image.Image) -> Image.Image:
    """Trail crop clipped to the doorway so sky cannot leak around the stone."""
    filled = _crop_peek(src, kind, opening.size).convert("RGBA")
    # Showcase shots have translucent pixels; flatten so the peek itself has no holes.
    backdrop = (148, 203, 222, 255) if kind == "desert" else (42, 28, 58, 255)
    opaque = Image.new("RGBA", opening.size, backdrop)
    opaque = Image.alpha_composite(opaque, filled)
    opaque.putalpha(opening)
    return opaque


def main() -> int:
    door = Image.open(UI / "menu_save_door.png").convert("RGBA")
    frame, leaf, opening = _split_solid_door(door)
    desert = Image.open(ROOT / "docs" / "showcase" / "desert_trail.png").convert("RGB")
    cave = Image.open(ROOT / "docs" / "showcase" / "cave_trail.png").convert("RGB")

    frame.save(UI / "menu_save_door_frame.png")
    leaf.save(UI / "menu_save_door_leaf.png")
    _arch_peek(desert, "desert", opening).save(UI / "menu_door_peek_desert.png")
    _arch_peek(cave, "cave", opening).save(UI / "menu_door_peek_cave.png")
    print("wrote solid frame, leaf, and arch-clipped peeks under assets/ui/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
