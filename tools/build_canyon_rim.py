#!/usr/bin/env python3
"""Build canyon_rim_left.png from the hand-drawn left-ridge concept.

Produces a tall left rim with:
- sealed sand crust at y=0 (flush with the desert floor)
- opaque packed-dirt bank (no sky/abyss peek-through)
- jagged canyon-facing lip on the right, flush to the outer envelope
"""

from __future__ import annotations

from collections import deque
from pathlib import Path
import math
import random
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from PIL import Image  # noqa: E402

SRC = ROOT / "assets/source/canyon/ridge_left_concept.png"
OUT = ROOT / "assets/world/canyon_rim_left.png"
TARGET_H = 980
CRUST_ROWS = 14
DEFAULT_EARTH = (140, 62, 28, 255)
NEAR_BLACK = 50
OPAQUE_A = 40
JAGGED_MAX = 18


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


def _lips(im: Image.Image, alpha: int = OPAQUE_A) -> list[int]:
	w, h = im.size
	px = im.load()
	out: list[int] = []
	for y in range(h):
		right = -1
		for x in range(w - 1, -1, -1):
			if px[x, y][3] > alpha:
				right = x
				break
		out.append(right)
	return out


def _is_near_black(r: int, g: int, b: int, a: int) -> bool:
	return a > 0 and (r + g + b) < NEAR_BLACK


def _needs_fill(r: int, g: int, b: int, a: int) -> bool:
	return a < OPAQUE_A or _is_near_black(r, g, b, a)


def _sample_row_earth(px, y: int, w: int, envelope: int) -> tuple[int, int, int, int]:
	"""Warm rock/dirt from opaque bank pixels on this row."""
	samples: list[tuple[int, int, int, int]] = []
	limit = max(0, min(w - 1, envelope))
	for x in range(0, limit + 1):
		r, g, b, a = px[x, y]
		if a > 200 and (r + g + b) >= NEAR_BLACK and r > 40:
			samples.append((r, g, b, 255))
			if len(samples) >= 8:
				break
	if samples:
		# Prefer mid-bank sample (skip possible edge noise).
		return samples[min(3, len(samples) - 1)]
	return DEFAULT_EARTH


def _seal_to_envelope(im: Image.Image) -> int:
	"""Fill transparent/near-black notches out to the outer face envelope.

	Returns rim_lip_tex_x (= envelope).
	"""
	w, h = im.size
	px = im.load()
	lips = _lips(im)
	face_lips = [lip for lip in lips[CRUST_ROWS:] if lip >= 0]
	if not face_lips:
		face_lips = [lip for lip in lips if lip >= 0]
	envelope = max(face_lips) if face_lips else w - 1
	# Ensure crust reaches the same outer lip as the face envelope.
	envelope = max(envelope, max((lip for lip in lips[:CRUST_ROWS] if lip >= 0), default=0))

	# Widen canvas if envelope sits on the last column (need room only if carving
	# would need more — envelope is the sealed outer lip).
	if envelope >= w:
		envelope = w - 1

	for y in range(h):
		sample = _sample_row_earth(px, y, w, envelope)
		# Paint sealed sand crust on top rows for a flush desert cap.
		if y < CRUST_ROWS:
			rng = random.Random(3 + y * 17)
			shade = 1.0 - 0.08 * y / max(1, CRUST_ROWS - 1)
			for x in range(0, envelope + 1):
				n = rng.randint(-8, 8)
				r = max(0, min(255, int(236 * shade) + n))
				g = max(0, min(255, int(170 * shade) + n // 2))
				b = max(0, min(255, int(95 * shade) + n // 3))
				if envelope - x <= 2:
					r = int(r * 0.85)
					g = int(g * 0.8)
					b = int(b * 0.75)
				px[x, y] = (r, g, b, 255)
			continue
		for x in range(0, envelope + 1):
			r, g, b, a = px[x, y]
			if _needs_fill(r, g, b, a):
				# Slight vertical tint variation from the row sample.
				jitter = ((x * 13 + y * 7) % 11) - 5
				nr = max(0, min(255, sample[0] + jitter))
				ng = max(0, min(255, sample[1] + jitter // 2))
				nb = max(0, min(255, sample[2] + jitter // 3))
				px[x, y] = (nr, ng, nb, 255)
	return envelope


def _jagged_inset(y: int, h: int, rng: random.Random) -> int:
	"""Seeded irregular inset ~0..JAGGED_MAX so rim_sky_edge_is_irregular passes."""
	t = (y - CRUST_ROWS) / max(1.0, float(h - CRUST_ROWS - 1))
	# Layered sines + sparse noise for cliff-like notches (not a straight cut).
	wave = (
		9.0 * (0.5 + 0.5 * math.sin(t * math.pi * 5.3 + 0.4))
		+ 5.5 * (0.5 + 0.5 * math.sin(t * math.pi * 11.7 + 1.7))
		+ 3.0 * (0.5 + 0.5 * math.sin(t * math.pi * 23.1 + 0.9))
	)
	# Occasional deeper bites every ~40–70 rows.
	chunk = abs(((y * 1103515245 + 12345) >> 16) % 47)
	bite = 6.0 if chunk < 5 else (3.0 if chunk < 12 else 0.0)
	noise = rng.uniform(-1.5, 1.5)
	inset = int(round(max(0.0, min(float(JAGGED_MAX), wave * 0.85 + bite + noise))))
	return inset


def _carve_jagged_silhouette(im: Image.Image, envelope: int) -> None:
	"""Carve canyon-facing jagged lip on the RIGHT; crust stays solid to envelope."""
	w, h = im.size
	px = im.load()
	rng = random.Random(42)
	for y in range(h):
		if y < CRUST_ROWS:
			lip_x = envelope
		else:
			lip_x = envelope - _jagged_inset(y, h, rng)
			lip_x = max(0, min(envelope, lip_x))
		for x in range(lip_x + 1, w):
			px[x, y] = (0, 0, 0, 0)


def _strip_near_black_fringe(im: Image.Image, envelope: int) -> None:
	"""Make near-black fringe outside the silhouette transparent."""
	w, h = im.size
	px = im.load()
	lips = _lips(im)
	for y in range(h):
		lip = lips[y]
		if lip < 0:
			continue
		# Outside silhouette (past this row's lip) — clear near-black leftovers.
		for x in range(lip + 1, w):
			r, g, b, a = px[x, y]
			if a > 0 and (r + g + b) < NEAR_BLACK + 30:
				px[x, y] = (0, 0, 0, 0)
		# Also clear near-black sitting on the outer 2px of the lip edge.
		for x in range(max(0, lip - 1), min(w, lip + 1)):
			r, g, b, a = px[x, y]
			if _is_near_black(r, g, b, a):
				px[x, y] = (0, 0, 0, 0)
	# Any remaining near-black anywhere past the sealed bank mid — kill fringe.
	for y in range(h):
		for x in range(max(0, envelope - JAGGED_MAX - 2), w):
			r, g, b, a = px[x, y]
			if _is_near_black(r, g, b, a):
				px[x, y] = (0, 0, 0, 0)


def _fill_bank_pre(im: Image.Image) -> None:
	"""Coarse bank fill before resize so LANCZOS has solid dirt to sample."""
	w, h = im.size
	px = im.load()
	lips = _lips(im)
	for y in range(h):
		lip = lips[y]
		if lip < 10:
			continue
		sample = DEFAULT_EARTH
		for x in range(0, max(1, lip // 2)):
			if px[x, y][3] > 200 and px[x, y][0] + px[x, y][1] + px[x, y][2] >= NEAR_BLACK:
				sample = (px[x, y][0], px[x, y][1], px[x, y][2], 255)
				break
		for x in range(0, max(0, lip - 4)):
			r, g, b, a = px[x, y]
			if a < 160 or (r + g + b) < NEAR_BLACK:
				px[x, y] = sample


def build() -> dict:
	if not SRC.exists():
		raise SystemExit(f"missing concept art: {SRC}")
	im = _key_out(Image.open(SRC).convert("RGBA"))
	bbox = im.getbbox()
	if bbox is None:
		raise SystemExit("keyed image empty")
	im = im.crop(bbox)
	_fill_bank_pre(im)
	ow, oh = im.size
	nw = max(40, int(round(ow * (TARGET_H / float(oh)))))
	final = im.resize((nw, TARGET_H), Image.Resampling.LANCZOS)
	# After key-out + crop + resize: seal notches, carve jagged lip, strip fringe.
	envelope = _seal_to_envelope(final)
	_carve_jagged_silhouette(final, envelope)
	_strip_near_black_fringe(final, envelope)
	OUT.parent.mkdir(parents=True, exist_ok=True)
	final.save(OUT)
	return {
		"path": str(OUT),
		"size": final.size,
		"rim_surface_tex_y": 0.0,
		"rim_lip_tex_x": float(envelope),
		"rim_crust_rows": CRUST_ROWS,
	}


if __name__ == "__main__":
	info = build()
	print(info)
	print(f"size={info['size']} rim_lip_tex_x={info['rim_lip_tex_x']}")
