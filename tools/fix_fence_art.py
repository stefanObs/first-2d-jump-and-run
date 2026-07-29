#!/usr/bin/env python3
"""Punch painted checkerboard / white fill from between ranch fence posts.

``assets/world/fence.png`` shipped with enclosed light-gray/white squares in the
rail gaps (fake transparency). Flood-fill cutout cannot reach those pockets
from the border; this scrub clears flat near-white matte so cave/desert
backdrops show through.

    python tools/fix_fence_art.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
FENCE = ROOT / "assets" / "world" / "fence.png"


def scrub_fence(path: Path = FENCE) -> int:
	im = Image.open(path).convert("RGBA")
	px = im.load()
	w, h = im.size
	cleared = 0
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a < 8:
				continue
			chroma = max(r, g, b) - min(r, g, b)
			# Flat light checker / white only — keep warm wood browns.
			if min(r, g, b) >= 160 and chroma <= 25:
				px[x, y] = (r, g, b, 0)
				cleared += 1
			elif min(r, g, b) >= 140 and chroma <= 15:
				px[x, y] = (r, g, b, 0)
				cleared += 1
	im.save(path)
	return cleared


if __name__ == "__main__":
	n = scrub_fence()
	print(f"scrubbed {n} matte pixels from {FENCE.relative_to(ROOT)}")
