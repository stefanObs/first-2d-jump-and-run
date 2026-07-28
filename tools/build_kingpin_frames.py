"""Build Outlaw Kingpin walk frames from `assets/source/kingpin/walk_strip.png`.

Standing art stays `assets/world/boss_outlaw_kingpin.png`. Walk frames match
that 130×180 canvas so feet stay registered.

    python tools/build_kingpin_frames.py
"""
from __future__ import annotations

from pathlib import Path

from art_pipeline import cutout, frame_sprite, slice_strip

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "source" / "kingpin" / "walk_strip.png"
OUT = ROOT / "assets" / "world"

CANVAS = (130, 180)
BASELINE = 178
BODY_H = 168


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
	for i, seg in enumerate(segs[:4]):
		path = OUT / f"boss_outlaw_kingpin_walk_{i}.png"
		frame_sprite(seg, canvas=CANVAS, target_h=BODY_H, baseline=BASELINE).save(path)
		print("wrote", path.relative_to(ROOT))


if __name__ == "__main__":
	build()
