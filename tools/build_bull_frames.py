"""Build trail/boss bull standing + run frames from `assets/source/bull/`.

Trail bull standing has no painted lasso ring. Boss standing stays
`assets/world/boss_stampede_bull.png` (ring kept for the stampede fight).
Run cycles are 4-frame strips keyed and framed to 320×160.

    python tools/build_bull_frames.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

from art_pipeline import cutout, frame_sprite

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "source" / "bull"
OUT = ROOT / "assets" / "world"

CANVAS = (320, 160)
BASELINE = 150
BODY_H = 118


def _frame(img: Image.Image) -> Image.Image:
	return frame_sprite(img, canvas=CANVAS, target_h=BODY_H, baseline=BASELINE)


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


def _save_strip(src_name: str, out_prefix: str) -> None:
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
		_frame(cell).save(path)
		print("wrote", path.relative_to(ROOT))


def build() -> None:
	stand_src = SRC / "standing_no_ring.png"
	if not stand_src.exists():
		raise SystemExit(f"Missing {stand_src}")
	stand = cutout(str(stand_src), level=200, sat=25)
	bbox = stand.getbbox()
	if bbox:
		stand = stand.crop(bbox)
	stand_path = OUT / "trail_bull.png"
	_frame(stand).save(stand_path)
	print("wrote", stand_path.relative_to(ROOT))

	_save_strip("run_strip_no_ring.png", "trail_bull")
	_save_strip("run_strip_boss.png", "boss_stampede_bull")


if __name__ == "__main__":
	build()
