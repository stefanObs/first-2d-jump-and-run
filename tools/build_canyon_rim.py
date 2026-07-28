#!/usr/bin/env python3
"""Build canyon_rim_left.png from the hand-drawn left-ridge concept.

Produces a tall left rim with:
- sealed sand crust at y=0 (flush with the desert floor)
- opaque packed-dirt bank (no sky/abyss peek-through)
- jagged canyon-facing lip on the right, with no near-black sky-edge fringe
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
# True rock: brightness above this, or warm orange/brown chroma.
ROCK_BRIGHTNESS = 55.0
OPAQUE_A = 40
# Outer near-black ink fringe against magenta — removable at the lip.
FRINGE_STRIP_PX = 4
JAGGED_MAX = 18
MIN_LIP_SPREAD = 8
WARM_EDGE = (92, 48, 22, 255)


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


def _brightness(r: int, g: int, b: int) -> float:
	return (r + g + b) / 3.0


def _is_magenta_residue(r: int, g: int, b: int) -> bool:
	"""Keyed magenta / purple bleed left by anti-aliased key-out."""
	if g >= 90:
		return False
	# Classic magenta key, or red–purple cast (blue well above green).
	if b > 55 and r > 60 and b >= g and abs(r - b) <= 55:
		return True
	if r > 80 and b > g + 20 and g < 50 and b >= 40:
		return True
	return False


def _is_rock_chroma(r: int, g: int, b: int) -> bool:
	"""Warm orange/brown rock (readable, not ink-black or magenta)."""
	if _is_magenta_residue(r, g, b):
		return False
	bri = _brightness(r, g, b)
	# Too dark reads as black fringe against sky even if slightly warm.
	if bri < 36:
		return False
	return r >= 70 and r > g + 8 and r > b + 18 and (r - min(g, b)) >= 22


def _is_true_rock(r: int, g: int, b: int, a: int) -> bool:
	if a < 180:
		return False
	if _is_magenta_residue(r, g, b):
		return False
	return _brightness(r, g, b) > ROCK_BRIGHTNESS or _is_rock_chroma(r, g, b)


def _is_near_black(r: int, g: int, b: int, a: int) -> bool:
	"""Dark fringe / ink — not readable rock color."""
	if a <= 0:
		return False
	if _is_magenta_residue(r, g, b):
		return True
	if _is_true_rock(r, g, b, max(a, 255)):
		return False
	return _brightness(r, g, b) <= ROCK_BRIGHTNESS


def _lips_opaque(im: Image.Image, alpha: int = OPAQUE_A) -> list[int]:
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


def _row_clean_lip(px, y: int, w: int) -> int:
	"""Rightmost opaque rock pixel; outer 1–4px near-black ink fringe is ignored."""
	right = -1
	for x in range(w - 1, -1, -1):
		if px[x, y][3] > OPAQUE_A:
			right = x
			break
	if right < 0:
		return -1
	# Prefer true rock; skip outermost near-black fringe strip.
	for x in range(right, max(-1, right - FRINGE_STRIP_PX) - 1, -1):
		r, g, b, a = px[x, y]
		if _is_true_rock(r, g, b, a):
			return x
	# Fallback: any true rock further inland.
	for x in range(right, -1, -1):
		r, g, b, a = px[x, y]
		if _is_true_rock(r, g, b, a):
			return x
	return max(0, right - FRINGE_STRIP_PX)


def _sample_row_earth(px, y: int, w: int, lip: int) -> tuple[int, int, int, int]:
	samples: list[tuple[int, int, int, int]] = []
	limit = max(0, min(w - 1, lip))
	for x in range(0, limit + 1):
		r, g, b, a = px[x, y]
		if a > 200 and _is_true_rock(r, g, b, a) and r > 40:
			samples.append((r, g, b, 255))
			if len(samples) >= 8:
				break
	if samples:
		return samples[min(3, len(samples) - 1)]
	return DEFAULT_EARTH


def _fill_bank_pre(im: Image.Image) -> None:
	"""Coarse bank fill before resize so LANCZOS has solid dirt to sample."""
	w, h = im.size
	px = im.load()
	lips = _lips_opaque(im)
	for y in range(h):
		lip = lips[y]
		if lip < 10:
			continue
		sample = DEFAULT_EARTH
		for x in range(0, max(1, lip // 2)):
			r, g, b, a = px[x, y]
			if a > 200 and _is_true_rock(r, g, b, a):
				sample = (r, g, b, 255)
				break
		for x in range(0, max(0, lip - 4)):
			r, g, b, a = px[x, y]
			if a < 160 or _is_near_black(r, g, b, a):
				px[x, y] = sample


def _seal_crust(im: Image.Image, envelope: int) -> None:
	w, h = im.size
	px = im.load()
	for y in range(min(CRUST_ROWS, h)):
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
		for x in range(envelope + 1, w):
			px[x, y] = (0, 0, 0, 0)


def _jagged_inset(y: int, h: int, rng: random.Random) -> int:
	t = (y - CRUST_ROWS) / max(1.0, float(h - CRUST_ROWS - 1))
	wave = (
		9.0 * (0.5 + 0.5 * math.sin(t * math.pi * 5.3 + 0.4))
		+ 5.5 * (0.5 + 0.5 * math.sin(t * math.pi * 11.7 + 1.7))
		+ 3.0 * (0.5 + 0.5 * math.sin(t * math.pi * 23.1 + 0.9))
	)
	chunk = abs(((y * 1103515245 + 12345) >> 16) % 47)
	bite = 6.0 if chunk < 5 else (3.0 if chunk < 12 else 0.0)
	noise = rng.uniform(-1.5, 1.5)
	return int(round(max(0.0, min(float(JAGGED_MAX), wave * 0.85 + bite + noise))))


def _ensure_lip_irregularity(clean_lip: list[int], h: int, envelope: int) -> list[int]:
	"""Keep >= MIN_LIP_SPREAD px of jagged variation on the face."""
	face = [clean_lip[y] for y in range(CRUST_ROWS, h) if clean_lip[y] >= 0]
	if not face:
		return clean_lip
	spread = max(face) - min(face)
	if spread >= MIN_LIP_SPREAD:
		return clean_lip
	rng = random.Random(42)
	out = list(clean_lip)
	for y in range(CRUST_ROWS, h):
		if out[y] < 0:
			continue
		inset = _jagged_inset(y, h, rng)
		out[y] = max(0, min(envelope, envelope - inset))
	for y in range(CRUST_ROWS):
		out[y] = envelope
	return out


def _postprocess_silhouette(im: Image.Image) -> dict:
	"""Clean RIGHT sky-edge: rock lip without near-black fringe."""
	w, h = im.size
	px = im.load()

	# 3) Fill bank opaque (inland holes / thin alpha after resize).
	opaque_lips = _lips_opaque(im)
	pre_envelope = max((lip for lip in opaque_lips if lip >= 0), default=w - 1)
	for y in range(CRUST_ROWS, h):
		lip = opaque_lips[y]
		if lip < 8:
			continue
		sample = _sample_row_earth(px, y, w, lip)
		# Fill well inland; leave outer fringe for clean-lip detection.
		for x in range(0, max(0, lip - FRINGE_STRIP_PX)):
			r, g, b, a = px[x, y]
			if a < OPAQUE_A or _is_near_black(r, g, b, a):
				jitter = ((x * 13 + y * 7) % 11) - 5
				px[x, y] = (
					max(0, min(255, sample[0] + jitter)),
					max(0, min(255, sample[1] + jitter // 2)),
					max(0, min(255, sample[2] + jitter // 3)),
					255,
				)

	# 5) Clean lip per face row (skip outer near-black ink).
	clean_lip = [-1] * h
	for y in range(h):
		if y < CRUST_ROWS:
			continue
		clean_lip[y] = _row_clean_lip(px, y, w)

	face_lips = [clean_lip[y] for y in range(CRUST_ROWS, h) if clean_lip[y] >= 0]
	envelope = max(face_lips) if face_lips else pre_envelope
	envelope = max(0, min(w - 1, envelope))

	# Crust seals to the same outer envelope.
	for y in range(CRUST_ROWS):
		clean_lip[y] = envelope

	clean_lip = _ensure_lip_irregularity(clean_lip, h, envelope)
	envelope = max(clean_lip) if clean_lip else envelope

	# 4) Seal crust after envelope known.
	_seal_crust(im, envelope)

	# 7) Fill transparent holes inland of each row's clean lip.
	for y in range(CRUST_ROWS, h):
		lip = clean_lip[y]
		if lip < 0:
			continue
		sample = _sample_row_earth(px, y, w, lip)
		for x in range(0, lip + 1):
			r, g, b, a = px[x, y]
			if a < OPAQUE_A or _is_near_black(r, g, b, a):
				jitter = ((x * 13 + y * 7) % 11) - 5
				px[x, y] = (
					max(0, min(255, sample[0] + jitter)),
					max(0, min(255, sample[1] + jitter // 2)),
					max(0, min(255, sample[2] + jitter // 3)),
					255,
				)

	# 8) Clear everything past clean lip; strip near-black / magenta at the seam.
	for y in range(h):
		lip = clean_lip[y]
		if lip < 0:
			for x in range(w):
				px[x, y] = (0, 0, 0, 0)
			continue
		sample = _sample_row_earth(px, y, w, max(0, lip))
		for x in range(lip + 1, w):
			px[x, y] = (0, 0, 0, 0)

		def _bad_seam(r: int, g: int, b: int, a: int) -> bool:
			return a < 200 or _is_near_black(r, g, b, a) or _is_magenta_residue(r, g, b) or (
				_brightness(r, g, b) <= ROCK_BRIGHTNESS
			)

		# lip-1: replace fringe with rock (do not punch a hole inland of the lip).
		if lip - 1 >= 0:
			r, g, b, a = px[lip - 1, y]
			if _bad_seam(r, g, b, a):
				jitter = ((lip * 13 + y * 7) % 11) - 5
				px[lip - 1, y] = (
					max(0, min(255, sample[0] + jitter)),
					max(0, min(255, sample[1] + jitter // 2)),
					max(0, min(255, sample[2] + jitter // 3)),
					255,
				)
		# lip column: clear bad fringe so we can snap to true rock inland.
		r, g, b, a = px[lip, y]
		if _bad_seam(r, g, b, a):
			px[lip, y] = (0, 0, 0, 0)
			new_lip = -1
			for x in range(lip, -1, -1):
				rr, gg, bb, aa = px[x, y]
				if _is_true_rock(rr, gg, bb, aa):
					new_lip = x
					break
			if new_lip >= 0:
				clean_lip[y] = new_lip
				for x in range(new_lip + 1, w):
					px[x, y] = (0, 0, 0, 0)
			lip = clean_lip[y]

		# 9) Thin warm-brown edge — keep existing rock outline if already brown (r>40);
		# never leave pure black or magenta at the sky seam.
		if lip >= 0 and y >= CRUST_ROWS:
			r, g, b, a = px[lip, y]
			if (
				a >= 200
				and r > 40
				and _brightness(r, g, b) > ROCK_BRIGHTNESS
				and not _is_magenta_residue(r, g, b)
			):
				px[lip, y] = (r, g, b, 255)
			else:
				sample = _sample_row_earth(px, y, w, max(0, lip))
				px[lip, y] = (
					max(55, min(255, int(sample[0] * 0.78))),
					max(28, min(255, int(sample[1] * 0.70))),
					max(12, min(255, int(sample[2] * 0.58))),
					255,
				)

	envelope = max((clean_lip[y] for y in range(h) if clean_lip[y] >= 0), default=envelope)
	# Crust must match final envelope.
	_seal_crust(im, envelope)
	for y in range(CRUST_ROWS):
		clean_lip[y] = envelope

	return {
		"envelope": envelope,
		"clean_lip": clean_lip,
		"lip_min": min(clean_lip[CRUST_ROWS:]) if h > CRUST_ROWS else envelope,
		"lip_max": max(clean_lip[CRUST_ROWS:]) if h > CRUST_ROWS else envelope,
	}


def _stats(im: Image.Image, envelope: int, clean_lip: list[int]) -> dict:
	w, h = im.size
	px = im.load()
	near_black_opaque = 0
	near_black_outer3 = 0
	opaque_past_max = 0
	lip_max = max(clean_lip) if clean_lip else envelope
	for y in range(h):
		lip = clean_lip[y] if y < len(clean_lip) else -1
		for x in range(w):
			r, g, b, a = px[x, y]
			if a > OPAQUE_A and _is_near_black(r, g, b, a):
				near_black_opaque += 1
				if lip >= 0 and x >= lip - 2:
					near_black_outer3 += 1
			if a > OPAQUE_A and x > lip_max:
				opaque_past_max += 1
	return {
		"size": (w, h),
		"lip_min": min(clean_lip[CRUST_ROWS:]) if h > CRUST_ROWS else envelope,
		"lip_max": lip_max,
		"near_black_opaque": near_black_opaque,
		"near_black_outer3_cols": near_black_outer3,
		"opaque_past_max_lip": opaque_past_max,
	}


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
	meta = _postprocess_silhouette(final)
	OUT.parent.mkdir(parents=True, exist_ok=True)
	final.save(OUT)
	stats = _stats(final, meta["envelope"], meta["clean_lip"])
	return {
		"path": str(OUT),
		"size": final.size,
		"rim_surface_tex_y": 0.0,
		"rim_lip_tex_x": float(meta["envelope"]),
		"rim_crust_rows": CRUST_ROWS,
		"stats": stats,
	}


if __name__ == "__main__":
	info = build()
	s = info["stats"]
	print(info)
	print(
		f"size={s['size']} lip_min={s['lip_min']} lip_max={s['lip_max']} "
		f"rim_lip_tex_x={info['rim_lip_tex_x']}"
	)
	print(
		f"near_black_opaque={s['near_black_opaque']} "
		f"near_black_outer3={s['near_black_outer3_cols']} "
		f"opaque_past_max_lip={s['opaque_past_max_lip']}"
	)
