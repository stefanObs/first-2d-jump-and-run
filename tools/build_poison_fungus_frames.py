#!/usr/bin/env python3
"""Build poison fungus spore-puff frames from the painted strip.

Source: ``assets/source/cave/poison_fungus_spore_strip.png`` — four painterly
poses (idle → gather → puff → settle) matching the mushroom's cel-shaded look.
Do **not** overlay geometric vapor blobs; the strip already paints the toxic
wisps and spore motes in the same hand-drawn style as the idle toadstool.

Frames (64×80, feet on baseline 79):
  0 idle — soft resting vapor
  1 gather — cap breathes, wisps thicken
  2 puff — soft spore cloud under the cap
  3 settle — cloud thins, returns toward idle

    python tools/build_poison_fungus_frames.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

from art_pipeline import cutout, frame_sprite, slice_strip

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "source" / "cave" / "poison_fungus_spore_strip.png"
OUT = ROOT / "assets" / "world"

CANVAS = (64, 80)
BASELINE = 79
BODY_H = 72


def _valley_cuts(im: Image.Image, count: int = 4) -> list[int]:
	w, _ = im.size
	ap = im.split()[3].load()
	dens = [sum(1 for y in range(im.size[1]) if ap[x, y] > 8) for x in range(w)]
	win = 8
	smooth = [
		sum(dens[max(0, x - win) : min(w, x + win + 1)])
		/ (min(w, x + win + 1) - max(0, x - win))
		for x in range(w)
	]
	cuts = [0]
	for bi in range(1, count):
		center = int(w * bi / count)
		lo = max(0, center - 60)
		hi = min(w, center + 60)
		region = smooth[lo:hi]
		best = min(range(len(region)), key=lambda i: region[i])
		cuts.append(lo + best)
	cuts.append(w)
	return cuts


def build_frames() -> list[Path]:
	if not SRC.exists():
		raise SystemExit(f"missing {SRC}")
	keyed = cutout(str(SRC), level=200, sat=28)
	segs = slice_strip(keyed, min_gap_frac=0.008)
	if len(segs) < 4:
		cuts = _valley_cuts(keyed, 4)
		inset = 12
		segs = []
		for i in range(4):
			cell = keyed.crop((cuts[i] + inset, 0, cuts[i + 1] - inset, keyed.size[1]))
			bbox = cell.getbbox()
			if bbox:
				cell = cell.crop(bbox)
			segs.append(cell)
	elif len(segs) > 4:
		ranked = sorted(
			range(len(segs)),
			key=lambda i: segs[i].size[0] * segs[i].size[1],
			reverse=True,
		)[:4]
		segs = [segs[i] for i in sorted(ranked)]

	paths: list[Path] = []
	for i, seg in enumerate(segs[:4]):
		framed = frame_sprite(seg, canvas=CANVAS, target_h=BODY_H, baseline=BASELINE)
		path = OUT / f"poison_fungus_{i}.png"
		framed.save(path)
		paths.append(path)
		print(f"wrote {path.relative_to(ROOT)} {framed.size}")

	# Stamp / legacy idle matches the loop's resting pose.
	idle = OUT / "poison_fungus_0.png"
	Image.open(idle).convert("RGBA").save(OUT / "poison_fungus.png")
	print("wrote assets/world/poison_fungus.png (idle)")
	return paths


if __name__ == "__main__":
	build_frames()
