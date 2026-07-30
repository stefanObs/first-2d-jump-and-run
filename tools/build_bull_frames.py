"""Build trail/boss bull standing + run frames from `assets/source/bull/`.

Trail bull standing has no painted lasso ring. Boss standing is reframed from
`assets/world/boss_stampede_bull.png` onto a roomier canvas so horns, hooves and
the ring glow are not jammed against the edge. Boss run frames are separated from
the packed strip with a peak flood that respects neighbouring cores (valley cuts
alone slice through overlapping tails and horns), then scaled to the same body
height as the standing pose.

    python tools/build_bull_frames.py
"""
from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image

from art_pipeline import cutout, frame_sprite

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "source" / "bull"
OUT = ROOT / "assets" / "world"

# Trail bulls (and cave lizards) share this smaller chibi footprint.
TRAIL_CANVAS = (320, 160)
TRAIL_BASELINE = 150
TRAIL_BODY_H = 118
# Stampede Bull: roomy canvas so the full stride (tail → horns) and ring glow
# keep a clear margin. Body height matches across stun idle and run frames.
BOSS_CANVAS = (440, 230)
BOSS_BASELINE = 222
BOSS_BODY_H = 164
# Columns within this of another peak are that bull's exclusive core — flood
# fill may spill past the valley midline for a tail tip, but not into a neighbour's body.
BOSS_CORE_RADIUS = 90


def _frame(
	img: Image.Image,
	*,
	canvas: tuple[int, int],
	target_h: int,
	baseline: int,
) -> Image.Image:
	return frame_sprite(img, canvas=canvas, target_h=target_h, baseline=baseline)


def _opaque_area(im: Image.Image) -> int:
	return sum(1 for value in im.split()[3].get_flattened_data() if value > 16)


def _frame_to_opaque_area(img: Image.Image, target_area: int) -> Image.Image:
	"""Scale a pose until its painted mass matches standing.

	Matching canvas or bounding-box height is insufficient for the boss strip:
	tucked-leg poses contain much less painted bull and visibly shrink. Opaque
	area tracks apparent character size while preserving each pose's aspect.
	"""
	target_h = BOSS_BODY_H
	framed = _frame(
		img,
		canvas=BOSS_CANVAS,
		target_h=target_h,
		baseline=BOSS_BASELINE,
	)
	for _iteration in range(3):
		current_area = _opaque_area(framed)
		if current_area <= 0:
			break
		target_h = max(1, round(target_h * (target_area / current_area) ** 0.5))
		framed = _frame(
			img,
			canvas=BOSS_CANVAS,
			target_h=target_h,
			baseline=BOSS_BASELINE,
		)
	return framed


def _column_density(im: Image.Image, *, win: int = 8) -> list[float]:
	w, h = im.size
	ap = im.split()[3].load()
	dens = [sum(1 for y in range(h) if ap[x, y] > 8) for x in range(w)]
	smooth: list[float] = []
	for x in range(w):
		lo = max(0, x - win)
		hi = min(w, x + win + 1)
		smooth.append(sum(dens[lo:hi]) / (hi - lo))
	return smooth


def _valley_cuts(im: Image.Image, count: int = 4) -> list[int]:
	"""Split a packed horizontal strip at density valleys between figures."""
	w, _ = im.size
	sm = _column_density(im)
	cuts = [0]
	for bi in range(1, count):
		center = int(w * bi / count)
		lo = max(0, center - 50)
		hi = min(w, center + 50)
		region = sm[lo:hi]
		best = min(range(len(region)), key=lambda i: region[i])
		cuts.append(lo + best)
	cuts.append(w)
	return cuts


def _peaks_from_cuts(im: Image.Image, cuts: list[int]) -> list[int]:
	sm = _column_density(im)
	peaks: list[int] = []
	for i in range(len(cuts) - 1):
		lo, hi = cuts[i], cuts[i + 1]
		region = sm[lo:hi]
		peaks.append(lo + max(range(len(region)), key=lambda j: region[j]))
	return peaks


def _extract_boss_figures(keyed: Image.Image) -> list[Image.Image]:
	"""Pull four full bulls from a packed strip without slicing through extremities."""
	w, h = keyed.size
	ap = keyed.split()[3].load()
	src = keyed.load()
	cuts = _valley_cuts(keyed, 4)
	peaks = _peaks_from_cuts(keyed, cuts)
	figures: list[Image.Image] = []
	for i, peak in enumerate(peaks):
		forbidden: set[int] = set()
		for j, other in enumerate(peaks):
			if j == i:
				continue
			for x in range(max(0, other - BOSS_CORE_RADIUS), min(w, other + BOSS_CORE_RADIUS + 1)):
				forbidden.add(x)
		queue: deque[tuple[int, int]] = deque()
		seen: set[tuple[int, int]] = set()
		for y in range(h):
			if ap[peak, y] > 8:
				queue.append((peak, y))
				seen.add((peak, y))
		while queue:
			x, y = queue.popleft()
			for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
				if not (0 <= nx < w and 0 <= ny < h):
					continue
				if (nx, ny) in seen or nx in forbidden or ap[nx, ny] <= 8:
					continue
				seen.add((nx, ny))
				queue.append((nx, ny))
		if not seen:
			raise SystemExit(f"Boss run figure {i} extracted empty")
		xs = [p[0] for p in seen]
		ys = [p[1] for p in seen]
		x0, x1 = min(xs), max(xs) + 1
		y0, y1 = min(ys), max(ys) + 1
		fig = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
		fp = fig.load()
		for x, y in seen:
			fp[x - x0, y - y0] = src[x, y]
		figures.append(fig)
	return figures


def _save_trail_strip(src_name: str, out_prefix: str) -> None:
	keyed = cutout(str(SRC / src_name), level=200, sat=25)
	cuts = _valley_cuts(keyed, 4)
	inset = 10
	for i in range(4):
		x0 = cuts[i] + inset
		x1 = cuts[i + 1] - inset
		cell = keyed.crop((x0, 0, x1, keyed.size[1]))
		bbox = cell.getbbox()
		if bbox:
			cell = cell.crop(bbox)
		path = OUT / f"{out_prefix}_run_{i}.png"
		_frame(
			cell,
			canvas=TRAIL_CANVAS,
			target_h=TRAIL_BODY_H,
			baseline=TRAIL_BASELINE,
		).save(path)
		print("wrote", path.relative_to(ROOT))


def _save_boss_run_frames(target_area: int) -> None:
	keyed = cutout(str(SRC / "run_strip_boss.png"), level=200, sat=25)
	figures = _extract_boss_figures(keyed)
	for i, fig in enumerate(figures):
		path = OUT / f"boss_stampede_bull_run_{i}.png"
		_frame_to_opaque_area(fig, target_area).save(path)
		print("wrote", path.relative_to(ROOT))


def _reframe_boss_standing() -> int:
	"""Pad the existing stun/idle art onto the roomy canvas at the run body height."""
	stand_path = OUT / "boss_stampede_bull.png"
	if not stand_path.exists():
		raise SystemExit(f"Missing {stand_path}")
	stand = Image.open(stand_path).convert("RGBA")
	# Alpha trim — ignore RGB leftovers from earlier cutouts.
	bbox = stand.split()[3].getbbox()
	if bbox:
		stand = stand.crop(bbox)
	framed = _frame(
		stand,
		canvas=BOSS_CANVAS,
		target_h=BOSS_BODY_H,
		baseline=BOSS_BASELINE,
	)
	framed.save(stand_path)
	print("wrote", stand_path.relative_to(ROOT), "(reframed)")
	return _opaque_area(framed)


def build() -> None:
	stand_src = SRC / "standing_no_ring.png"
	if not stand_src.exists():
		raise SystemExit(f"Missing {stand_src}")
	stand = cutout(str(stand_src), level=200, sat=25)
	bbox = stand.getbbox()
	if bbox:
		stand = stand.crop(bbox)
	stand_path = OUT / "trail_bull.png"
	_frame(
		stand,
		canvas=TRAIL_CANVAS,
		target_h=TRAIL_BODY_H,
		baseline=TRAIL_BASELINE,
	).save(stand_path)
	print("wrote", stand_path.relative_to(ROOT))

	_save_trail_strip("run_strip_no_ring.png", "trail_bull")
	boss_target_area = _reframe_boss_standing()
	_save_boss_run_frames(boss_target_area)


if __name__ == "__main__":
	build()
