#!/usr/bin/env python3
"""Build canyon_rim_left.png from the hand-drawn left-ridge concept.

Produces a tall left rim with:
- sealed sand crust at y=0 (flush with the desert floor)
- opaque packed-dirt bank (no sky/abyss peek-through)
- jagged canyon-facing lip on the right
"""

from __future__ import annotations

from collections import deque
from pathlib import Path
import random
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from PIL import Image  # noqa: E402

SRC = ROOT / "assets/source/canyon/ridge_left_concept.png"
OUT = ROOT / "assets/world/canyon_rim_left.png"
TARGET_H = 980
CRUST_ROWS = 14


def _is_key(r: int, g: int, b: int) -> bool:
	if r > 180 and b > 180 and g < 120:
		return True
	if min(r, g, b) >= 200 and (max(r, g, b) - min(r, g, b)) <= 30:
		return True
	if r > 200 and g < 80 and b > 200:
		return True
	return False


def _key_out(im: Image.Image) -> Image.Image:
	w, h = im.size
	px = im.load()
	bg = bytearray(w * h)
	dq: deque[tuple[int, int]] = deque()

	def idx(x: int, y: int) -> int:
		return y * w + x

	seeds = [(x, y) for x in range(w) for y in (0, h - 1)]
	seeds += [(x, y) for y in range(h) for x in (0, w - 1)]
	for x, y in seeds:
		r, g, b, _ = px[x, y]
		if _is_key(r, g, b):
			bg[idx(x, y)] = 1
			dq.append((x, y))
	while dq:
		x, y = dq.popleft()
		for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
			if 0 <= nx < w and 0 <= ny < h and not bg[idx(nx, ny)]:
				r, g, b, _ = px[nx, ny]
				if _is_key(r, g, b):
					bg[idx(nx, ny)] = 1
					dq.append((nx, ny))
	for _ in range(3):
		add: list[tuple[int, int]] = []
		for y in range(h):
			for x in range(w):
				if bg[idx(x, y)]:
					continue
				r, g, b, _ = px[x, y]
				near = (r > 160 and b > 160 and g < 140) or (
					min(r, g, b) >= 180 and max(r, g, b) - min(r, g, b) <= 40
				)
				if not near:
					continue
				for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
					if 0 <= nx < w and 0 <= ny < h and bg[idx(nx, ny)]:
						add.append((x, y))
						break
		for x, y in add:
			bg[idx(x, y)] = 1
	out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	opx = out.load()
	for y in range(h):
		for x in range(w):
			if not bg[idx(x, y)]:
				opx[x, y] = px[x, y]
	return out


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


def _fill_bank(im: Image.Image) -> None:
	w, h = im.size
	px = im.load()
	lips = _lips(im)
	for y in range(h):
		lip = lips[y]
		if lip < 10:
			continue
		sample = (140, 62, 28, 255)
		for x in range(0, max(1, lip // 2)):
			if px[x, y][3] > 200:
				sample = px[x, y]
				break
		for x in range(0, max(0, lip - 4)):
			if px[x, y][3] < 160:
				px[x, y] = sample


def _seal_crust(im: Image.Image, rows: int) -> int:
	w, h = im.size
	px = im.load()
	lips = _lips(im)
	env = max((lip for lip in lips if lip >= 0), default=w - 1)
	rng = random.Random(3)
	for y in range(rows):
		shade = 1.0 - 0.08 * y / max(1, rows - 1)
		for x in range(0, env + 1):
			n = rng.randint(-8, 8)
			r = max(0, min(255, int(236 * shade) + n))
			g = max(0, min(255, int(170 * shade) + n // 2))
			b = max(0, min(255, int(95 * shade) + n // 3))
			if env - x <= 2:
				r = int(r * 0.85)
				g = int(g * 0.8)
				b = int(b * 0.75)
			px[x, y] = (r, g, b, 255)
	return env


def build() -> dict:
	if not SRC.exists():
		raise SystemExit(f"missing concept art: {SRC}")
	im = _key_out(Image.open(SRC).convert("RGBA"))
	bbox = im.getbbox()
	if bbox is None:
		raise SystemExit("keyed image empty")
	im = im.crop(bbox)
	_fill_bank(im)
	ow, oh = im.size
	nw = max(40, int(round(ow * (TARGET_H / float(oh)))))
	final = im.resize((nw, TARGET_H), Image.Resampling.LANCZOS)
	_fill_bank(final)
	lip_x = _seal_crust(final, CRUST_ROWS)
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
	print(build())
