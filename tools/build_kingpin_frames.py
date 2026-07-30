"""Build Outlaw Kingpin walk frames from `assets/source/kingpin/walk_strip.png`.

Standing art stays `assets/world/boss_outlaw_kingpin.png`. All four frames share
one scale, one foot line, and one upper-body anchor, so the cycle keeps the
drawn head bob instead of being stretched to a uniform height, the boots stay on
the same ground row, and the torso does not slide sideways as the stride opens.
The tallest stride matches the standing canvas height so he does not pop when he
halts to shoot.

    python tools/build_kingpin_frames.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

from art_pipeline import cutout, slice_strip

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "source" / "kingpin" / "walk_strip.png"
OUT = ROOT / "assets" / "world"
STAND = ROOT / "assets" / "world" / "boss_outlaw_kingpin.png"

CANVAS = (130, 180)
## Fraction of the figure treated as "upper body" when picking the sway anchor.
UPPER_BODY_FRAC = 0.35


def _alpha_bbox(im: Image.Image) -> tuple[int, int, int, int] | None:
	"""Bounds of visible pixels only — `Image.getbbox` also counts cleared pixels
	that kept their painted RGB, which would pad the figure with dead margin."""
	return im.split()[3].getbbox()


def _upper_body_center(fig: Image.Image) -> float:
	"""Alpha-weighted horizontal centre of hat, head and shoulders."""
	width, height = fig.size
	alpha = fig.split()[3].load()
	total = 0
	weighted = 0
	for y in range(max(1, int(height * UPPER_BODY_FRAC))):
		for x in range(width):
			value = alpha[x, y]
			if value > 16:
				total += value
				weighted += value * x
	return weighted / total if total else width * 0.5


def build() -> None:
	if not SRC.exists():
		raise SystemExit(f"Missing {SRC}")
	keyed = cutout(str(SRC), level=200, sat=28)
	segs = slice_strip(keyed, min_gap_frac=0.01)
	if len(segs) < 4:
		raise SystemExit(f"Expected 4 walk figures, got {len(segs)}")
	if len(segs) > 4:
		ranked = sorted(
			range(len(segs)),
			key=lambda i: segs[i].size[0] * segs[i].size[1],
			reverse=True,
		)[:4]
		segs = [segs[i] for i in sorted(ranked)]

	figures: list[Image.Image] = []
	for seg in segs[:4]:
		bbox = _alpha_bbox(seg)
		if bbox is None:
			raise SystemExit("Empty walk figure in strip")
		figures.append(seg.crop(bbox))

	stand_box = _alpha_bbox(Image.open(STAND).convert("RGBA"))
	if stand_box is None:
		raise SystemExit(f"Empty standing art {STAND}")
	stand_h = stand_box[3] - stand_box[1]
	# Share the standing art's foot row so the pose can swap without a hitch.
	baseline = stand_box[3]
	scale = stand_h / max(fig.size[1] for fig in figures)
	canvas_w, _ = CANVAS
	for i, fig in enumerate(figures):
		width = max(1, round(fig.size[0] * scale))
		height = max(1, round(fig.size[1] * scale))
		if width > canvas_w:
			height = max(1, round(height * canvas_w / width))
			width = canvas_w
		scaled = fig.resize((width, height), Image.LANCZOS)
		anchor = _upper_body_center(scaled)
		left = int(round(canvas_w * 0.5 - anchor))
		left = max(min(left, canvas_w - width), min(0, canvas_w - width))
		frame = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
		frame.alpha_composite(scaled, (left, baseline - height))
		path = OUT / f"boss_outlaw_kingpin_walk_{i}.png"
		frame.save(path)
		print("wrote", path.relative_to(ROOT))


if __name__ == "__main__":
	build()
