#!/usr/bin/env python3
"""Reusable pipeline for turning hand-drawn concept art into game-ready sprites.

Generated concept art (see `.cursor/rules/art-style.mdc`) usually arrives on a
*painted* light checkerboard or flat white background rather than real alpha
transparency. This module keys that background out, then trims/scales/aligns the
figure onto the game's sprite canvas so animation frames stay registered.

Typical use::

    from tools.art_pipeline import cutout, frame_sprite, slice_strip

    idle = frame_sprite(cutout("concept_idle.png"))            # -> 64x64 RGBA
    runs = [frame_sprite(f) for f in slice_strip(cutout("run_strip.png"))]

The on-foot player frames are 64x64 with the figure ~60 px tall and feet resting
on y=63 (matches the cowboy frames in assets/player/). Override target_h /
baseline / canvas for other sprite sizes (e.g. mounted horse frames).
"""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image


def _is_bg(r: int, g: int, b: int, *, level: int = 208, sat: int = 22) -> bool:
    """A pixel is background if it is light *and* near-gray (checker or white)."""
    return min(r, g, b) >= level and (max(r, g, b) - min(r, g, b)) <= sat


def cutout(
    src: str | Path,
    *,
    feather: int = 3,
    level: int = 208,
    sat: int = 22,
    punch_holes: bool = True,
) -> Image.Image:
    """Remove a painted checkerboard / flat white background via border flood fill.

    Only background-connected light pixels are cleared, so the character's own
    interior whites (eye highlights, teeth) are preserved. A few feather passes
    grow transparency into the anti-aliased halo to avoid a bright fringe.

    Lower ``level`` (e.g. 185) keys stubborner painted mattes that sit below the
    default light-gray threshold; default 208 matches existing call sites.

    When ``punch_holes`` is true, remaining *flat* near-gray pockets (enclosed
    matte between legs/arms that flood-fill cannot reach from the border) are
    cleared too. Warm cream highlights are kept by requiring near-neutral chroma.
    """
    im = Image.open(src).convert("RGBA")
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
        if _is_bg(r, g, b, level=level, sat=sat) and not bg[idx(x, y)]:
            bg[idx(x, y)] = 1
            dq.append((x, y))

    while dq:
        x, y = dq.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not bg[idx(nx, ny)]:
                r, g, b, _ = px[nx, ny]
                if _is_bg(r, g, b, level=level, sat=sat):
                    bg[idx(nx, ny)] = 1
                    dq.append((nx, ny))

    if punch_holes:
        # Enclosed limb gaps keep painted matte that never touches the border.
        # Only punch near-neutral grays so warm cream face highlights survive.
        hole_level = min(level, 150)
        for y in range(h):
            for x in range(w):
                if bg[idx(x, y)]:
                    continue
                r, g, b, _ = px[x, y]
                if min(r, g, b) >= hole_level and (max(r, g, b) - min(r, g, b)) <= 12:
                    bg[idx(x, y)] = 1

    for _ in range(feather):
        add: list[tuple[int, int]] = []
        for y in range(h):
            for x in range(w):
                if bg[idx(x, y)]:
                    continue
                r, g, b, _ = px[x, y]
                if min(r, g, b) >= 196 and (max(r, g, b) - min(r, g, b)) <= 30:
                    for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                        if 0 <= nx < w and 0 <= ny < h and bg[idx(nx, ny)]:
                            add.append((x, y))
                            break
        for x, y in add:
            bg[idx(x, y)] = 1

    for y in range(h):
        for x in range(w):
            if bg[idx(x, y)]:
                r, g, b, _ = px[x, y]
                px[x, y] = (r, g, b, 0)
    return im


def slice_strip(im: Image.Image, *, min_gap_frac: float = 0.01) -> list[Image.Image]:
    """Split a horizontal sprite-sheet row into figures by empty (alpha) columns."""
    w, h = im.size
    alpha = im.split()[3]
    ap = alpha.load()
    col_has = [any(ap[x, y] > 8 for y in range(h)) for x in range(w)]

    segments: list[tuple[int, int]] = []
    start = None
    for x in range(w):
        if col_has[x] and start is None:
            start = x
        elif not col_has[x] and start is not None:
            segments.append((start, x))
            start = None
    if start is not None:
        segments.append((start, w))

    # Merge segments separated by tiny gaps (stray ink between limbs).
    min_gap = max(2, int(w * min_gap_frac))
    merged: list[list[int]] = []
    for s, e in segments:
        if merged and s - merged[-1][1] <= min_gap:
            merged[-1][1] = e
        else:
            merged.append([s, e])

    figures = [im.crop((s, 0, e, h)) for s, e in merged]
    figures = [f for f in figures if f.getbbox() is not None]
    return figures


def frame_sprite(
    im: Image.Image,
    *,
    canvas: tuple[int, int] = (64, 64),
    target_h: int = 60,
    baseline: int = 63,
) -> Image.Image:
    """Trim to content, scale so the figure is `target_h` tall, rest feet on
    `baseline`, and center horizontally on a transparent `canvas`."""
    cw, ch = canvas
    bbox = im.getbbox()
    if bbox is None:
        return Image.new("RGBA", canvas, (0, 0, 0, 0))
    fig = im.crop(bbox)
    fw, fh = fig.size
    scale = target_h / fh
    nw, nh = max(1, round(fw * scale)), target_h
    if nw > cw:
        scale = cw / fw
        nw, nh = cw, max(1, round(fh * scale))
    fig = fig.resize((nw, nh), Image.LANCZOS)
    out = Image.new("RGBA", canvas, (0, 0, 0, 0))
    out.alpha_composite(fig, ((cw - nw) // 2, baseline - nh))
    return out


if __name__ == "__main__":
    import sys

    for arg in sys.argv[1:]:
        result = frame_sprite(cutout(arg))
        dest = Path(arg).with_suffix(".framed.png")
        result.save(dest)
        print(f"wrote {dest}")
