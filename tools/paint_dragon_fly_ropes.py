#!/usr/bin/env python3
"""Make Cave Dragon fly-bound ropes match the floor tied stages.

Floor stage 1 = neck coils. Floor stage 2 = neck coils + mid-torso coils.
Existing fly_bound1 already matches stage 1. fly_bound2 wrongly used a muzzle;
rebuild it from fly_bound1 (keep the neck ropes) plus torso coils stamped in
the same painted rope style.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "world"


def _rope_layer(base: Image.Image, tied: Image.Image, region: tuple[int, int, int, int]) -> Image.Image:
	"""Pixels in `tied` that look like warm rope and differ from `base`, cropped to region."""
	x0, y0, x1, y1 = region
	pb, pt = base.load(), tied.load()
	layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
	pl = layer.load()
	for y in range(y0, y1):
		for x in range(x0, x1):
			r0, g0, b0, a0 = pb[x, y]
			r, g, b, a = pt[x, y]
			if a < 12:
				continue
			if a0 >= 12 and abs(r - r0) + abs(g - g0) + abs(b - b0) < 40:
				continue
			# Warm rope / lasso tan (matches hand-painted bound1 coils).
			if r < 90 or g < 55 or b > 140:
				continue
			if r < g - 8 or (r - b) < 28:
				continue
			pl[x, y] = (r, g, b, a)
	return layer


def _stamp_torso_from_neck(neck_layer: Image.Image) -> Image.Image:
	"""Duplicate the neck coil cluster onto the mid-torso, slightly larger."""
	bbox = neck_layer.getbbox()
	if bbox is None:
		return Image.new("RGBA", neck_layer.size, (0, 0, 0, 0))
	coil = neck_layer.crop(bbox)
	# Mid-body is a bit thicker than the neck on the fly pose.
	scaled = coil.resize(
		(max(1, int(coil.size[0] * 1.18)), max(1, int(coil.size[1] * 1.12))),
		Image.LANCZOS,
	)
	out = Image.new("RGBA", neck_layer.size, (0, 0, 0, 0))
	# Place under the wing root / mid ribs (right of the neck coils).
	tx = bbox[0] + 52
	ty = bbox[1] + 14
	out.paste(scaled, (tx, ty), scaled)
	return out


def _build_bound2(flap: int) -> Path:
	base = Image.open(OUT / f"boss_cave_dragon_fly_{flap}.png").convert("RGBA")
	bound1 = Image.open(OUT / f"boss_cave_dragon_fly_bound1_{flap}.png").convert("RGBA")
	# Neck coils live just behind the jaw on the fly pose.
	neck = _rope_layer(base, bound1, (70, 85, 145, 160))
	torso = _stamp_torso_from_neck(neck)
	out = base.copy()
	# Neck first (same as bound1), then torso — floor stage 2 order.
	out.alpha_composite(neck)
	out.alpha_composite(torso)
	dest = OUT / f"boss_cave_dragon_fly_bound2_{flap}.png"
	out.save(dest)
	return dest


def build() -> None:
	# bound1 already matches floor stage 1 — only repair bound2.
	for flap in (0, 1):
		path = _build_bound2(flap)
		print("wrote", path.relative_to(ROOT))


if __name__ == "__main__":
	build()
