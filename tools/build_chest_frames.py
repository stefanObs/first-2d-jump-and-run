"""Build full-frame treasure chest sprites from hand-drawn concept art.

Source concepts live in ``assets/source/chest/`` (``closed.png`` / ``open.png``).
Exports drop-in game sprites (no lid/body/interior rig slices):

  - treasure_chest_closed.png — height ≈ 48 px (player 44 × HEIGHT_RATIO 1.0925)
  - treasure_chest_open.png   — same width as closed (taller with lid up)
  - treasure_chest_stamp.png  — 64×64 workshop stamp, closed chest near bottom

    python3 tools/build_chest_frames.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

from art_pipeline import cutout

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "source" / "chest"
OUT = ROOT / "assets" / "world"

# Match TreasureChest.HEIGHT_RATIO / TARGET_HEIGHT (player height 44).
CLOSED_HEIGHT = 48
STAMP_SIZE = 64
# Feet sit just above the stamp bottom edge (same idea as the old stamp).
STAMP_BASELINE = 52


def _load(name: str) -> Image.Image:
    im = cutout(str(SRC / name))
    bbox = im.getbbox()
    if bbox is None:
        raise RuntimeError(f"cutout produced empty image: {name}")
    return im.crop(bbox)


def _scale_h(im: Image.Image, height: int) -> Image.Image:
    w = max(1, round(im.width * height / im.height))
    return im.resize((w, height), Image.LANCZOS)


def _scale_w(im: Image.Image, width: int) -> Image.Image:
    h = max(1, round(im.height * width / im.width))
    return im.resize((width, h), Image.LANCZOS)


def _make_stamp(closed: Image.Image) -> Image.Image:
    # Fit closed chest into stamp, preferring ~50px wide / max ~40px tall.
    scw, sch = 50, round(closed.height * 50 / closed.width)
    if sch > 40:
        scw, sch = round(closed.width * 40 / closed.height), 40
    sc = closed.resize((scw, sch), Image.LANCZOS)
    stamp = Image.new("RGBA", (STAMP_SIZE, STAMP_SIZE), (0, 0, 0, 0))
    stamp.alpha_composite(sc, ((STAMP_SIZE - scw) // 2, STAMP_BASELINE - sch))
    return stamp


def _bottom_row_opaque(im: Image.Image) -> tuple[bool, int, int]:
    """Return (has_opaque_on_bbox_bottom, opaque_count, width) for feet check."""
    bbox = im.getbbox()
    if bbox is None:
        return False, 0, 0
    _l, _t, r, b = bbox
    y = b - 1
    px = im.load()
    opaque = 0
    for x in range(_l, r):
        if px[x, y][3] >= 200:
            opaque += 1
    return opaque > 0, opaque, r - _l


def build() -> None:
    closed_src = _load("closed.png")
    open_src = _load("open.png")

    closed = _scale_h(closed_src, CLOSED_HEIGHT)
    open_im = _scale_w(open_src, closed.width)

    stamp = _make_stamp(closed)

    outputs = [
        ("treasure_chest_closed", closed),
        ("treasure_chest_open", open_im),
        ("treasure_chest_stamp", stamp),
    ]
    OUT.mkdir(parents=True, exist_ok=True)
    for name, img in outputs:
        path = OUT / f"{name}.png"
        img.save(path)
        print(f"wrote assets/world/{name}.png size={img.size} bbox={img.getbbox()}")

    for label, img in (("closed", closed), ("open", open_im)):
        ok, count, width = _bottom_row_opaque(img)
        status = "OK opaque feet" if ok else "MISSING opaque bottom"
        print(f"{label} bottom row: {status} ({count}/{width} opaque px on bbox bottom)")


if __name__ == "__main__":
    build()
