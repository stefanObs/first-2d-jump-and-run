"""Build the treasure chest sprite set from hand-drawn concept art.

The chest is a 3-part rig (see ``scripts/world/treasure_chest_art.gd``): a lid cap
that rotates on a hinge, a box front (carrying the lock plate), and a gold
interior revealed when open, plus a combined 64x64 workshop stamp. Source
concepts live in ``assets/source/chest/`` (``closed.png`` / ``open.png``).

    python tools/build_chest_frames.py

The chest uses DARK espresso wood + bright gold so it keeps strong contrast
against the warm orange-red mesa backdrops. See ``.cursor/rules/art-style.mdc``.
Output sizes are drop-in for the existing rig: lid 60x27, body/interior 60x39,
stamp 64x64.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

from art_pipeline import cutout

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "source" / "chest"
OUT = ROOT / "assets" / "world"

# Seam fractions of the closed-chest height: the lid cap is the top slice; the
# box front (with lock plate) begins a bit higher so it reads as a full front.
LID_FRAC = 0.46
BODY_TOP = 0.30


def _load(name: str) -> Image.Image:
    im = cutout(str(SRC / name))
    return im.crop(im.getbbox())


def _fit_width(im: Image.Image, w: int) -> Image.Image:
    return im.resize((w, max(1, round(im.height * w / im.width))), Image.LANCZOS)


def build() -> None:
    closed = _load("closed.png")
    openc = _load("open.png")
    wc, hc = closed.size
    wo, ho = openc.size

    lid = closed.crop((0, 0, wc, round(hc * LID_FRAC))).resize((60, 27), Image.LANCZOS)

    face = _fit_width(closed.crop((0, round(hc * BODY_TOP), wc, hc)), 60)
    if face.height > 39:
        face = face.resize((max(1, round(face.width * 39 / face.height)), 39), Image.LANCZOS)
    body = Image.new("RGBA", (60, 39), (0, 0, 0, 0))
    body.alpha_composite(face, ((60 - face.width) // 2, 39 - face.height))

    gold = openc.crop((round(wo * 0.14), round(ho * 0.36), round(wo * 0.86), round(ho * 0.60)))
    gb = gold.getbbox()
    if gb:
        gold = gold.crop(gb)
    gold = gold.resize((46, 22), Image.LANCZOS)
    interior = Image.new("RGBA", (60, 39), (0, 0, 0, 0))
    interior.alpha_composite(gold, ((60 - 46) // 2, (39 - 22) // 2 + 2))

    scw, sch = 50, round(closed.height * 50 / closed.width)
    if sch > 40:
        scw, sch = round(closed.width * 40 / closed.height), 40
    sc = closed.resize((scw, sch), Image.LANCZOS)
    stamp = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    stamp.alpha_composite(sc, ((64 - scw) // 2, 52 - sch))

    for name, img in [
        ("treasure_chest_lid", lid),
        ("treasure_chest_body", body),
        ("treasure_chest_interior", interior),
        ("treasure_chest_stamp", stamp),
    ]:
        img.save(OUT / f"{name}.png")
        print(f"wrote assets/world/{name}.png {img.size}")


if __name__ == "__main__":
    build()
