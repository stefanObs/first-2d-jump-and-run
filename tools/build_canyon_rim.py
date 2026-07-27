#!/usr/bin/env python3
"""Build the thin hand-drawn canyon ridge used by ScalableCanyonArt.

Source: handcrafted concept art (checkerboard background). Output is a tall
left-rim strip with a sealed sand crust at y=0, a transparent bank/inland
fade, and a jagged canyon-facing lip on the right.
"""

from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from PIL import Image  # noqa: E402
from tools.art_pipeline import cutout  # noqa: E402

SRC = ROOT / "assets/source/canyon/ridge_handcrafted_gen.png"
OUT = ROOT / "assets/world/canyon_rim_left.png"
SRC_KEEP = ROOT / "assets/source/canyon/ridge_handcrafted_cutout.png"
TARGET_H = 980
FACE_KEEP = 100
## Sealed sand rows after the final resize — desert floor meets this top.
CRUST_ROWS = 14
FADE = 34


def _lips(im: Image.Image) -> list[int]:
	w, h = im.size
	px = im.load()
	out: list[int] = []
	for y in range(h):
		right = -1
		for x in range(w - 1, -1, -1):
			if px[x, y][3] > 40:
				right = x
				break
		out.append(right)
	return out


def _sample_sand(im: Image.Image) -> tuple[int, int, int]:
	w, h = im.size
	px = im.load()
	for y in range(min(120, h)):
		for x in range(w - 1, -1, -1):
			r, g, b, a = px[x, y]
			if a > 200 and r > 200 and g > 120 and b < 150:
				return (r, g, b)
	return (232, 160, 72)


def _seal_crust(im: Image.Image, sand: tuple[int, int, int], rows: int) -> int:
	"""Paint a horizontal sealed sand cap; returns the outer lip X."""
	import random

	w, h = im.size
	px = im.load()
	lips = _lips(im)
	env = max((lip for lip in lips if lip >= 0), default=w - 1)
	inland = w
	for y in range(rows, min(rows + 80, h)):
		for x in range(w):
			if px[x, y][3] > 80:
				inland = min(inland, x)
				break
	if inland >= w:
		inland = max(0, env - FACE_KEEP)
	rng = random.Random(7)
	for y in range(rows):
		shade = 1.0 - 0.08 * (y / max(1, rows - 1))
		for x in range(inland, env + 1):
			n = rng.randint(-8, 8)
			r = max(0, min(255, int(sand[0] * shade) + n))
			g = max(0, min(255, int(sand[1] * shade) + n // 2))
			b = max(0, min(255, int(sand[2] * shade) + n // 3))
			if env - x <= 2:
				r = int(r * 0.82)
				g = int(g * 0.75)
				b = int(b * 0.7)
			px[x, y] = (r, g, b, 255)
	return env


def build() -> dict:
	im = cutout(SRC, feather=4)
	bbox = im.getbbox()
	if bbox is None:
		raise SystemExit("cutout produced an empty image")
	im = im.crop(bbox)
	w, h = im.size
	px = im.load()
	lips = _lips(im)
	sand = _sample_sand(im)

	# Keep only a thin canyon-facing strip; fade the bank so TrailFloor shows.
	face = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	fpx = face.load()
	for y in range(h):
		lip = lips[y]
		if lip < 0:
			continue
		keep_from = max(0, lip - FACE_KEEP)
		for x in range(keep_from, lip + 1):
			r, g, b, a = px[x, y]
			if a <= 0:
				continue
			dist = x - keep_from
			if dist < FADE:
				a = int(a * (dist / float(FADE)))
			if a > 0:
				fpx[x, y] = (r, g, b, a)

	cb = face.getbbox()
	if cb is None:
		raise SystemExit("face strip empty")
	face = face.crop(cb)

	# Drop wispy tip rows before normalizing height.
	fpx = face.load()
	fw, fh = face.size
	top = 0
	while top < min(40, fh - 1):
		xs = [x for x in range(fw) if fpx[x, top][3] > 180]
		if xs and (xs[-1] - xs[0]) >= 40:
			break
		top += 1
	if top > 0:
		face = face.crop((0, top, fw, fh))

	SRC_KEEP.parent.mkdir(parents=True, exist_ok=True)
	face.save(SRC_KEEP)

	ow, oh = face.size
	nw = max(24, int(round(ow * (TARGET_H / float(oh)))))
	final = face.resize((nw, TARGET_H), Image.Resampling.LANCZOS)
	# Seal the sand crust AFTER resize so it stays a full-height desert lip.
	lip_x = _seal_crust(final, sand, CRUST_ROWS)
	OUT.parent.mkdir(parents=True, exist_ok=True)
	final.save(OUT)

	return {
		"path": str(OUT),
		"size": final.size,
		"rim_surface_tex_y": 0.0,
		"rim_lip_tex_x": float(lip_x),
		"rim_crust_rows": CRUST_ROWS,
	}


if __name__ == "__main__":
	info = build()
	print(info)
