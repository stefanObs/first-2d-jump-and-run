#!/usr/bin/env python3
"""Fix cave biome cutouts, strip slicing, ladder matte, bow gaps, and procedural fillers."""

from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from tools.art_pipeline import cutout, frame_sprite, slice_strip  # noqa: E402

SOURCE = ROOT / "assets" / "source" / "cave"
OUT = ROOT / "assets" / "world"
WRITTEN: list[Path] = []


def _save(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    WRITTEN.append(path)


def _fit(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    bbox = im.getbbox()
    if bbox is None:
        return canvas
    fig = im.crop(bbox)
    fw, fh = fig.size
    tw, th = size
    scale = min(tw / fw, th / fh)
    nw, nh = max(1, round(fw * scale)), max(1, round(fh * scale))
    fig = fig.resize((nw, nh), Image.LANCZOS)
    canvas.alpha_composite(fig, ((tw - nw) // 2, (th - nh) // 2))
    return canvas


def _feet(
    im: Image.Image,
    size: tuple[int, int],
    target_h: int,
    baseline: int,
) -> Image.Image:
    return frame_sprite(im, canvas=size, target_h=target_h, baseline=baseline)


def _clear_pct(im: Image.Image) -> float:
    px = im.load()
    w, h = im.size
    clear = sum(1 for y in range(h) for x in range(w) if px[x, y][3] < 8)
    return 100.0 * clear / (w * h)


def _content_height(im: Image.Image) -> int:
    bbox = im.getbbox()
    if bbox is None:
        return 0
    return bbox[3] - bbox[1]


def _force_split_halves(im: Image.Image, *, gap: int = 8) -> list[Image.Image]:
    """Split a strip into left/right halves by content bbox mid-x.

    Leaves a few transparent columns at the cut so each figure does not keep
    a sliver of the neighboring sprite when wings nearly touch.
    """
    bbox = im.getbbox()
    if bbox is None:
        return []
    x0, y0, x1, y1 = bbox
    mid = (x0 + x1) // 2
    half = max(1, gap // 2)
    left = im.crop((x0, y0, max(x0 + 1, mid - half), y1))
    right = im.crop((min(x1 - 1, mid + half), y0, x1, y1))
    return [f for f in (left, right) if f.getbbox() is not None]


def _opaque_coords(px, w: int, h: int, *, alpha_thresh: int = 8) -> list[tuple[int, int]]:
    return [(x, y) for y in range(h) for x in range(w) if px[x, y][3] > alpha_thresh]


def _content_bbox_alpha(px, w: int, h: int, *, alpha_thresh: int = 8):
    xs: list[int] = []
    ys: list[int] = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > alpha_thresh:
                xs.append(x)
                ys.append(y)
    if not xs:
        return None
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def _column_opaque_ys(px, x: int, h: int, *, alpha_thresh: int = 8) -> list[int]:
    return [y for y in range(h) if px[x, y][3] > alpha_thresh]


def _has_vertical_gap(ys: list[int]) -> bool:
    if len(ys) < 2:
        return False
    ys = sorted(ys)
    return any(ys[i] - ys[i - 1] > 1 for i in range(1, len(ys)))


def _leftward_span(px, x: int, y: int, *, alpha_thresh: int = 8) -> int:
    lx = x
    while lx > 0 and px[lx - 1, y][3] > alpha_thresh:
        lx -= 1
    return x - lx + 1


def _rightward_span(px, x: int, y: int, w: int, *, alpha_thresh: int = 8) -> int:
    rx = x
    while rx + 1 < w and px[rx + 1, y][3] > alpha_thresh:
        rx += 1
    return rx - x + 1


def _clear_xy(px, x: int, y: int) -> None:
    r, g, b, _ = px[x, y]
    px[x, y] = (r, g, b, 0)


def _keep_main_component(im: Image.Image, *, alpha_thresh: int = 8) -> Image.Image:
    """Keep the 4-connected component seeded from the opaque-pixel centroid."""
    out = im.copy()
    w, h = out.size
    px = out.load()
    coords = _opaque_coords(px, w, h, alpha_thresh=alpha_thresh)
    if not coords:
        return out
    cx = sum(x for x, _ in coords) // len(coords)
    cy = sum(y for _, y in coords) // len(coords)
    start = None
    for r in range(max(w, h)):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                x, y = cx + dx, cy + dy
                if 0 <= x < w and 0 <= y < h and px[x, y][3] > alpha_thresh:
                    start = (x, y)
                    break
            if start is not None:
                break
        if start is not None:
            break
    if start is None:
        return out
    main: set[tuple[int, int]] = {start}
    q: deque[tuple[int, int]] = deque([start])
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if (
                0 <= nx < w
                and 0 <= ny < h
                and (nx, ny) not in main
                and px[nx, ny][3] > alpha_thresh
            ):
                main.add((nx, ny))
                q.append((nx, ny))
    for x, y in coords:
        if (x, y) not in main:
            _clear_xy(px, x, y)
    return out


# Back-compat alias used elsewhere / older call sites.
_keep_largest_component = _keep_main_component


def _trim_far_edge_strip(im: Image.Image, *, side: str, max_cols: int = 4) -> Image.Image:
    """Clear thin far-edge wing-bleed that stays 4-connected via a 1px bridge.

    Neighbor-bat slivers often remain attached after half-slice + largest-component
    keep. Clear them when they are sparse, vertically gapped, or tip columns that
    are not a wide wing surface spanning into the body.
    """
    out = im.copy()
    w, h = out.size
    if w < 8:
        return out
    px = out.load()
    alpha = 8
    bbox = _content_bbox_alpha(px, w, h, alpha_thresh=alpha)
    if bbox is None:
        return out
    x0, _y0, x1, _y1 = bbox

    # Pass A: rightmost/leftmost 2 columns — drop pixels without a wide tip span.
    edge_cols = [x1 - 1, x1 - 2] if side == "right" else [x0, x0 + 1]
    for x in edge_cols:
        if not (0 <= x < w):
            continue
        for y in range(h):
            if px[x, y][3] <= alpha:
                continue
            span = (
                _leftward_span(px, x, y, alpha_thresh=alpha)
                if side == "right"
                else _rightward_span(px, x, y, w, alpha_thresh=alpha)
            )
            if span < 4:
                _clear_xy(px, x, y)

    # Pass B: rightmost/leftmost 1–3 columns — thin / discontinuous strips.
    if side == "right":
        probe = list(range(x1 - 1, max(x0, x1 - 3) - 1, -1))
    else:
        probe = list(range(x0, min(x1, x0 + 3)))
    for x in probe:
        ys = _column_opaque_ys(px, x, h, alpha_thresh=alpha)
        if not ys:
            continue
        n = len(ys)
        if side == "right":
            scan = range(x - 1, max(x0 - 1, x - 8), -1)
        else:
            scan = range(x + 1, min(x1, x + 8))
        gap_before_body = False
        found_body = False
        for sx in scan:
            sn = len(_column_opaque_ys(px, sx, h, alpha_thresh=alpha))
            if sn == 0:
                gap_before_body = True
            if sn >= 18:
                found_body = True
                break
        yspan = max(ys) - min(ys) + 1
        fill = n / max(1, yspan)
        # Solid wing tips often have 18–24 opaque cols — only treat as bleed when
        # sparse (gaps / low fill) or separated from dense body by a clear gap.
        discontinuous = gap_before_body or _has_vertical_gap(ys) or (not found_body)
        sparse_strip = yspan >= 8 and fill < 0.55 and n < 25
        if n < 25 and (discontinuous or sparse_strip):
            if _has_vertical_gap(ys) and n >= 6:
                runs: list[list[int]] = []
                run = [ys[0]]
                for yy in ys[1:]:
                    if yy == run[-1] + 1:
                        run.append(yy)
                    else:
                        runs.append(run)
                        run = [yy]
                runs.append(run)
                runs.sort(key=len, reverse=True)
                for run in runs[1:]:
                    for yy in run:
                        _clear_xy(px, x, yy)
                edge_dist = (x1 - 1 - x) if side == "right" else (x - x0)
                if len(runs[0]) < 8 and edge_dist <= 2:
                    for yy in runs[0]:
                        _clear_xy(px, x, yy)
            else:
                for y in ys:
                    _clear_xy(px, x, y)

    # Pass C: shave far-edge columns separated by a transparent gap from body mass,
    # or tiny tip columns (<=6 opaque) at the content bbox edge.
    changed = True
    while changed:
        changed = False
        bbox = _content_bbox_alpha(px, w, h, alpha_thresh=alpha)
        if bbox is None:
            break
        x0, _y0, x1, _y1 = bbox
        x = x1 - 1 if side == "right" else x0
        ys = _column_opaque_ys(px, x, h, alpha_thresh=alpha)
        if not ys:
            break
        if side == "right":
            scan = range(x - 1, max(-1, x - 12), -1)
        else:
            scan = range(x + 1, min(w, x + 12))
        saw_gap = False
        body_after_gap = False
        for sx in scan:
            sn = len(_column_opaque_ys(px, sx, h, alpha_thresh=alpha))
            if sn == 0:
                saw_gap = True
            elif saw_gap and sn >= 12:
                body_after_gap = True
                break
            elif not saw_gap and sn >= 25:
                break
        thin = len(ys) < 25
        if (saw_gap and body_after_gap and thin) or (thin and _has_vertical_gap(ys)):
            for y in ys:
                _clear_xy(px, x, y)
            changed = True
            continue
        if thin and len(ys) <= 6:
            nx = x - 1 if side == "right" else x + 1
            nys = _column_opaque_ys(px, nx, h, alpha_thresh=alpha) if 0 <= nx < w else []
            if len(ys) <= 4 or (len(nys) < 15 and len(ys) <= 6):
                for y in ys:
                    _clear_xy(px, x, y)
                changed = True

    return out


def _clean_bat_figure(fig: Image.Image, *, index: int) -> Image.Image:
    """Drop neighboring-bat bleed after a half-slice (and after framing)."""
    cleaned = _keep_main_component(fig)
    side = "right" if index == 0 else "left"
    # Trim can expose a new far-edge fringe pixel; converge so the helper is
    # idempotent when re-run on an already-cleaned frame.
    for _ in range(6):
        nxt = _trim_far_edge_strip(cleaned, side=side, max_cols=4)
        if list(nxt.get_flattened_data()) == list(cleaned.get_flattened_data()):
            return nxt
        cleaned = nxt
    return cleaned


def _slice_or_halves(im: Image.Image) -> list[Image.Image]:
    figs = slice_strip(im)
    if len(figs) >= 2:
        return figs[:2]
    return _force_split_halves(im)[:2]


def _magenta_tint(im: Image.Image) -> Image.Image:
    out = im.copy()
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            px[x, y] = (
                min(255, int(r * 0.85 + 40)),
                min(255, int(g * 0.7)),
                min(255, int(b * 0.95 + 30)),
                a,
            )
    return out


def _is_near_wood(r: int, g: int, b: int) -> bool:
    """Warm brown ladder wood / nail metal-ish tones to preserve."""
    # Wood: warm brown (r > g >= b-ish, decent chroma).
    if r >= 70 and r > g + 15 and g > b - 10 and (r - b) >= 25:
        return True
    # Dark outline / nail iron (low sat, mid-dark).
    if 40 <= min(r, g, b) <= 120 and (max(r, g, b) - min(r, g, b)) <= 35:
        return True
    # Bright nail highlights on wood (warm, not pure gray).
    if r >= 140 and g >= 90 and b <= g and (r - b) >= 20 and (max(r, g, b) - min(r, g, b)) >= 18:
        return True
    return False


def fix_ladder() -> None:
    path = OUT / "ladder.png"
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    cleared = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            sat = max(r, g, b) - min(r, g, b)
            if min(r, g, b) >= 200 and sat <= 28 and not _is_near_wood(r, g, b):
                px[x, y] = (r, g, b, 0)
                cleared += 1
            # Slightly darker matte leftovers between rungs.
            elif min(r, g, b) >= 185 and sat <= 18 and not _is_near_wood(r, g, b):
                # Only clear if not on the outer rails (keep edge wood).
                if 4 <= x <= w - 5:
                    px[x, y] = (r, g, b, 0)
                    cleared += 1
    _save(im, path)
    print(f"ladder: cleared {cleared} inter-rung gray pixels")


def densify_tile(path: Path, size: tuple[int, int]) -> None:
    """Fill canvas by covering with content; flood-fill interior transparent holes."""
    im = Image.open(path).convert("RGBA")
    bbox = im.getbbox()
    if bbox is None:
        return
    fig = im.crop(bbox)
    tw, th = size
    # Cover-scale so the rock spans the full tile (no sky gaps when tiled).
    fw, fh = fig.size
    scale = max(tw / fw, th / fh)
    nw, nh = max(1, round(fw * scale)), max(1, round(fh * scale))
    fig = fig.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    ox = (tw - nw) // 2
    oy = (th - nh) // 2
    canvas.alpha_composite(fig, (ox, oy))

    # Flood-fill fully transparent holes that are enclosed by rock.
    px = canvas.load()
    w, h = canvas.size
    exterior = bytearray(w * h)

    def idx(x: int, y: int) -> int:
        return y * w + x

    dq: deque[tuple[int, int]] = deque()
    for x in range(w):
        for y in (0, h - 1):
            if px[x, y][3] < 8:
                exterior[idx(x, y)] = 1
                dq.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if px[x, y][3] < 8 and not exterior[idx(x, y)]:
                exterior[idx(x, y)] = 1
                dq.append((x, y))
    while dq:
        x, y = dq.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not exterior[idx(nx, ny)]:
                if px[nx, ny][3] < 8:
                    exterior[idx(nx, ny)] = 1
                    dq.append((nx, ny))

    filled = 0
    for y in range(h):
        for x in range(w):
            if px[x, y][3] >= 8 or exterior[idx(x, y)]:
                continue
            # Sample neighboring rock color.
            samples: list[tuple[int, int, int]] = []
            for r in range(1, 6):
                for dx in range(-r, r + 1):
                    for dy in (-r, r) if abs(dx) < r else range(-r, r + 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h:
                            rr, gg, bb, aa = px[nx, ny]
                            if aa >= 128:
                                samples.append((rr, gg, bb))
                if samples:
                    break
            if not samples:
                continue
            sr = sum(c[0] for c in samples) // len(samples)
            sg = sum(c[1] for c in samples) // len(samples)
            sb = sum(c[2] for c in samples) // len(samples)
            px[x, y] = (sr, sg, sb, 255)
            filled += 1

    # Soft densify: any near-transparent fringe inside the upper crust band
    # with mostly opaque neighbors becomes opaque rock.
    band_h = max(8, th // 3)
    for y in range(band_h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a >= 200:
                continue
            neigh: list[tuple[int, int, int, int]] = []
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, 1), (1, -1), (-1, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] >= 180:
                    neigh.append(px[nx, ny])
            if len(neigh) >= 5:
                sr = sum(c[0] for c in neigh) // len(neigh)
                sg = sum(c[1] for c in neigh) // len(neigh)
                sb = sum(c[2] for c in neigh) // len(neigh)
                px[x, y] = (sr, sg, sb, 255)
                filled += 1

    _save(canvas, path)
    print(f"{path.name}: densified, filled≈{filled}, clear%={_clear_pct(canvas):.1f}")


def solidify_cave_floor_tile(path: Path, size: tuple[int, int]) -> None:
    """Force a fully opaque cave floor/dirt tile (no side margins / sky holes when tiled)."""
    import math
    import random

    im = Image.open(path).convert("RGBA")
    bbox = im.getbbox()
    if bbox is None:
        return
    fig = im.crop(bbox)
    tw, th = size
    fw, fh = fig.size
    # Cover-scale so rock spans the full tile, then crop center.
    scale = max(tw / fw, th / fh) * 1.02
    nw, nh = max(1, round(fw * scale)), max(1, round(fh * scale))
    fig = fig.resize((nw, nh), Image.LANCZOS)
    ox = (nw - tw) // 2
    oy = (nh - th) // 2
    canvas = fig.crop((ox, oy, ox + tw, oy + th)).convert("RGBA")
    px = canvas.load()
    w, h = canvas.size

    samples: list[tuple[int, int, int]] = []
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            r, g, b, a = px[x, y]
            if a >= 180:
                samples.append((r, g, b))
    if samples:
        base = (
            sum(c[0] for c in samples) // len(samples),
            sum(c[1] for c in samples) // len(samples),
            sum(c[2] for c in samples) // len(samples),
        )
    else:
        base = (58, 48, 68)

    rng = random.Random(91 + tw + th)

    def rock_at(x: int, y: int) -> tuple[int, int, int, int]:
        for radius in range(1, 12):
            found: list[tuple[int, int, int]] = []
            for dx in range(-radius, radius + 1):
                for dy in range(-radius, radius + 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        rr, gg, bb, aa = px[nx, ny]
                        if aa >= 180:
                            found.append((rr, gg, bb))
            if found:
                sr = sum(c[0] for c in found) // len(found)
                sg = sum(c[1] for c in found) // len(found)
                sb = sum(c[2] for c in found) // len(found)
                return (sr, sg, sb, 255)
        n = int(math.sin(x * 0.11) * 6 + math.cos(y * 0.17) * 5)
        return (
            max(20, min(120, base[0] + n + rng.randint(-4, 4))),
            max(16, min(100, base[1] + n + rng.randint(-4, 4))),
            max(28, min(130, base[2] + n + rng.randint(-4, 4))),
            255,
        )

    filled = 0
    for y in range(h):
        for x in range(w):
            if px[x, y][3] >= 250:
                continue
            px[x, y] = rock_at(x, y)
            filled += 1

    for _ in range(max(12, (w * h) // 700)):
        x = rng.randint(1, w - 2)
        y = rng.randint(1, h - 2)
        pr = 170 + rng.randint(-20, 30)
        pg = 95 + rng.randint(-15, 25)
        pb = 135 + rng.randint(-20, 25)
        px[x, y] = (pr, pg, pb, 255)

    _save(canvas, path)
    clear = _clear_pct(canvas)
    print(f"{path.name}: solidified, filled≈{filled}, clear%={clear:.1f}")
    if clear > 0.05:
        raise RuntimeError(f"{path.name} still has transparent pixels after solidify ({clear:.1f}%)")
    if path.name == "cave_dirt_tile.png":
        lift_cave_dirt_brightness(path)


def lift_cave_dirt_brightness(path: Path) -> None:
    """Cave underfill dirt must read as slate earth, not near-black voids under slopes."""
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            bri = (r + g + b) / 3.0
            # Lift toward readable mauve slate matching cave floor midtones.
            target = (78, 64, 86)
            if bri < 58:
                t = 0.55 if bri < 40 else 0.35
                px[x, y] = (
                    int(r * (1 - t) + target[0] * t),
                    int(g * (1 - t) + target[1] * t),
                    int(b * (1 - t) + target[2] * t),
                    255,
                )
            else:
                # Mild cool lift so deep stacks stay earthy.
                px[x, y] = (
                    min(140, r + 8),
                    min(120, g + 6),
                    min(150, b + 10),
                    255,
                )
    _save(im, path)
    print(f"{path.name}: lifted underfill brightness")


def fix_bats() -> None:
    src = SOURCE / "cave_bat_strip_concept.png"
    cut = cutout(src, level=185)
    figs = _slice_or_halves(cut)
    if len(figs) < 2:
        # Try slightly different levels.
        for lvl in (180, 190, 200):
            cut = cutout(src, level=lvl)
            figs = _slice_or_halves(cut)
            if len(figs) >= 2:
                print(f"bats: used cutout level={lvl}")
                break
    if len(figs) < 2:
        raise RuntimeError(f"bat strip: expected 2 figures, got {len(figs)}")
    for i, fig in enumerate(figs[:2]):
        fig = _clean_bat_figure(fig, index=i)
        framed = _fit(fig, (96, 64))
        # Re-clean after framing: LANCZOS resize can reintroduce soft edge bridges.
        framed = _clean_bat_figure(framed, index=i)
        _save(framed, OUT / f"cave_bat_{i}.png")
        print(f"cave_bat_{i}: clear%={_clear_pct(framed):.1f}")



def _is_bow_fill_candidate(r: int, g: int, b: int, a: int) -> bool:
    """Light gray/white or crystal-lavender opaque fill between bow and string."""
    if a < 180:
        return False
    lo, hi = min(r, g, b), max(r, g, b)
    # Gray / near-white plate left by cutout inside the bow triangle.
    if lo >= 165 and (hi - lo) <= 45:
        return True
    # Magenta-tinted crystal fill (g dropped by tint; not warm ivory bone).
    if (
        r >= 150
        and b >= 150
        and 100 <= g <= 180
        and (r - g) >= 25
        and (b - g) >= 25
        and (hi - lo) <= 95
    ):
        return True
    return False


def _is_bow_wood_pixel(r: int, g: int, b: int, a: int) -> bool:
    if a < 100:
        return False
    return r > g and r > b and 80 <= r <= 180 and 40 <= g <= 120


def _is_bowstring_pixel(r: int, g: int, b: int, a: int) -> bool:
    if a < 100:
        return False
    return min(r, g, b) >= 200 and (max(r, g, b) - min(r, g, b)) <= 35


def _region_near_bow(px, w: int, h: int, cells: list[tuple[int, int]], *, radius: int = 3) -> bool:
    for x, y in cells:
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h):
                    continue
                r, g, b, a = px[nx, ny]
                if _is_bow_wood_pixel(r, g, b, a) or _is_bowstring_pixel(r, g, b, a):
                    return True
    return False


def count_skeleton_bow_fill_candidates(
    im: Image.Image,
    *,
    right_half_only: bool = True,
    bow_band_only: bool = False,
) -> int:
    """Count opaque light fill candidates (optionally right half / mid-body bow band)."""
    rgba = im.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    x0 = w // 2 if right_half_only else 0
    y0, y1 = (int(h * 0.30), int(h * 0.72)) if bow_band_only else (0, h)
    n = 0
    for y in range(y0, y1):
        for x in range(x0, w):
            if _is_bow_fill_candidate(*px[x, y]):
                n += 1
    return n


def clear_skeleton_bow_gaps(im: Image.Image) -> tuple[Image.Image, int]:
    """Clear small enclosed light fill between wooden bow limbs and bowstring.

    Cutout leaves gray/white (or crystal-lavender) plates that are not
    border-connected. Only clears compact regions next to bow wood/string,
    never skull/eye interiors or foot bone blobs.
    Returns (image, cleared_pixel_count).
    """
    out = im.convert("RGBA").copy()
    px = out.load()
    w, h = out.size
    visited: set[tuple[int, int]] = set()
    to_clear: list[tuple[int, int]] = []
    cleared_bbox: list[int] | None = None  # x0,y0,x1,y1

    for y in range(h):
        for x in range(w):
            if (x, y) in visited:
                continue
            if not _is_bow_fill_candidate(*px[x, y]):
                continue
            q = deque([(x, y)])
            visited.add((x, y))
            cells: list[tuple[int, int]] = []
            while q:
                cx, cy = q.popleft()
                cells.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if not (0 <= nx < w and 0 <= ny < h) or (nx, ny) in visited:
                        continue
                    if _is_bow_fill_candidate(*px[nx, ny]):
                        visited.add((nx, ny))
                        q.append((nx, ny))
            area = len(cells)
            if area < 2 or area > 200:
                continue
            cx = sum(p[0] for p in cells) / area
            cy = sum(p[1] for p in cells) / area
            # Head / eye sockets (upper-left).
            if cx < w * 0.55 and cy < h * 0.28:
                continue
            # Foot / ground bone blobs.
            if cy > h * 0.72:
                continue
            # Bow sits on the facing-right side; require that or wood contact.
            rightish = cx >= w * 0.45
            near_bow = _region_near_bow(px, w, h, cells)
            if not near_bow:
                continue
            if not rightish:
                continue
            # Tiny speckles (2..7): only in the mid-body bow band.
            if area < 8 and not (h * 0.35 <= cy <= h * 0.70):
                continue
            # Reject cream bone patches that only graze wood: average should be
            # low-chroma gray/lavender, not warm ivory (high r+g, lower b chroma).
            ar = sum(px[p][0] for p in cells) / area
            ag = sum(px[p][1] for p in cells) / area
            ab = sum(px[p][2] for p in cells) / area
            # Warm ivory highlight (bone glint) — skip unless near-neutral gray.
            if ab + 25 < ar and ab + 25 < ag and (max(ar, ag, ab) - min(ar, ag, ab)) > 35:
                continue
            to_clear.extend(cells)
            xs = [p[0] for p in cells]
            ys = [p[1] for p in cells]
            box = [min(xs), min(ys), max(xs) + 1, max(ys) + 1]
            if cleared_bbox is None:
                cleared_bbox = box
            else:
                cleared_bbox[0] = min(cleared_bbox[0], box[0])
                cleared_bbox[1] = min(cleared_bbox[1], box[1])
                cleared_bbox[2] = max(cleared_bbox[2], box[2])
                cleared_bbox[3] = max(cleared_bbox[3], box[3])

    for x, y in to_clear:
        r, g, b, _a = px[x, y]
        px[x, y] = (r, g, b, 0)

    # Near-white / gray fringe speckles inside/near cleared bbox (touch a hole).
    fringe = 0
    if cleared_bbox is not None:
        x0, y0, x1, y1 = cleared_bbox
        x0, y0 = max(0, x0 - 2), max(0, y0 - 2)
        x1, y1 = min(w, x1 + 2), min(h, y1 + 2)
        for _pass in range(2):
            for y in range(y0, y1):
                for x in range(x0, x1):
                    r, g, b, a = px[x, y]
                    if a < 40:
                        continue
                    if not _is_bow_fill_candidate(r, g, b, a) and not (
                        min(r, g, b) >= 190 and (max(r, g, b) - min(r, g, b)) <= 40
                    ):
                        continue
                    touch_clear = False
                    for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                        if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] < 8:
                            touch_clear = True
                            break
                    if touch_clear:
                        px[x, y] = (r, g, b, 0)
                        fringe += 1

    return out, len(to_clear) + fringe


def fix_skeleton_bow_gaps() -> None:
    """Clear bow-triangle fill on base skeletons, then re-tint crystal set."""
    bases = [
        "skeleton.png",
        "skeleton_walk_0.png",
        "skeleton_walk_1.png",
        "skeleton_tied.png",
    ]
    print("\n=== skeleton bow gap clear ===")
    for name in bases:
        path = OUT / name
        if not path.is_file():
            print(f"{name}: missing, skip")
            continue
        im = Image.open(path).convert("RGBA")
        before = count_skeleton_bow_fill_candidates(im, right_half_only=True, bow_band_only=True)
        fixed, cleared = clear_skeleton_bow_gaps(im)
        after = count_skeleton_bow_fill_candidates(fixed, right_half_only=True, bow_band_only=True)
        _save(fixed, path)
        print(f"{name}: right_half_fill before={before} cleared={cleared} after={after}")

        crystal_name = name.replace("skeleton", "skeleton_crystal", 1)
        tinted = _magenta_tint(fixed)
        cpath = OUT / crystal_name
        _save(tinted, cpath)
        print(f"{crystal_name}: re-tint from fixed base (cleared={cleared})")


def fix_skeleton_walk() -> None:
    src = SOURCE / "cave_skeleton_walk_strip_concept.png"
    cut = cutout(src, level=185)
    figs = _slice_or_halves(cut)
    if len(figs) < 2:
        for lvl in (180, 190, 200):
            cut = cutout(src, level=lvl)
            figs = _slice_or_halves(cut)
            if len(figs) >= 2:
                print(f"skeleton walk: used cutout level={lvl}")
                break
    if len(figs) < 2:
        raise RuntimeError(f"skeleton walk: expected 2 figures, got {len(figs)}")
    for i, fig in enumerate(figs[:2]):
        framed = _feet(fig, (64, 80), target_h=67, baseline=76)
        framed, bow_cleared = clear_skeleton_bow_gaps(framed)
        path = OUT / f"skeleton_walk_{i}.png"
        _save(framed, path)
        print(
            f"skeleton_walk_{i}: clear%={_clear_pct(framed):.1f} "
            f"content_h={_content_height(framed)} bow_gap_cleared={bow_cleared}"
        )
        tinted = _magenta_tint(framed)
        cpath = OUT / f"skeleton_crystal_walk_{i}.png"
        _save(tinted, cpath)
        print(f"skeleton_crystal_walk_{i}: clear%={_clear_pct(tinted):.1f}")


def fix_camp_and_impact() -> None:
    camp_src = SOURCE / "cave_camp_concept.png"
    if camp_src.is_file():
        # Concept plate is mid-gray (~184); default cutout level 208 leaves it.
        cut = cutout(camp_src, level=170, sat=35, feather=4)
        active = _feet(cut, (96, 96), target_h=88, baseline=95)
        active = _strip_residual_gray_plate(active)
        _save(active, OUT / "checkpoint_cave_active.png")
        print(f"checkpoint_cave_active: clear%={_clear_pct(active):.1f}")
        rgb = ImageEnhance.Brightness(active.convert("RGB")).enhance(0.72)
        inactive = Image.merge("RGBA", (*rgb.split(), active.split()[-1]))
        _save(inactive, OUT / "checkpoint_cave_inactive.png")
        print(f"checkpoint_cave_inactive: clear%={_clear_pct(inactive):.1f}")
        for name in ("checkpoint_cave_active.png", "checkpoint_cave_inactive.png"):
            im = Image.open(OUT / name).convert("RGBA")
            if _gray_plate_pct(im) > 3.0:
                raise RuntimeError(f"{name} still has a gray background plate")

    impact_src = SOURCE / "cave_stalactite_impact_concept.png"
    if impact_src.is_file():
        cut = cutout(impact_src, level=185)
        framed = _fit(cut, (96, 64))
        _save(framed, OUT / "stalactite_impact.png")
        print(f"stalactite_impact: clear%={_clear_pct(framed):.1f}")


def _is_camp_gray_plate(r: int, g: int, b: int, a: int) -> bool:
    if a < 8:
        return False
    return (
        abs(r - g) <= 18
        and abs(g - b) <= 18
        and abs(r - b) <= 18
        and 140 <= min(r, g, b) <= 210
    )


def _gray_plate_pct(im: Image.Image) -> float:
    px = im.load()
    w, h = im.size
    gray = opaque = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            opaque += 1
            if _is_camp_gray_plate(r, g, b, a):
                gray += 1
    return 0.0 if opaque == 0 else 100.0 * gray / opaque


def _strip_residual_gray_plate(im: Image.Image) -> Image.Image:
    """Clear any leftover mid-gray matte still connected to the canvas border."""
    out = im.convert("RGBA").copy()
    px = out.load()
    w, h = out.size
    bg = bytearray(w * h)

    def idx(x: int, y: int) -> int:
        return y * w + x

    dq: deque[tuple[int, int]] = deque()
    seeds = [(x, y) for x in range(w) for y in (0, h - 1)]
    seeds += [(x, y) for y in range(h) for x in (0, w - 1)]
    for x, y in seeds:
        if _is_camp_gray_plate(*px[x, y]) and not bg[idx(x, y)]:
            bg[idx(x, y)] = 1
            dq.append((x, y))
    while dq:
        x, y = dq.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not bg[idx(nx, ny)]:
                if _is_camp_gray_plate(*px[nx, ny]):
                    bg[idx(nx, ny)] = 1
                    dq.append((nx, ny))
    # Feather into soft gray fringe.
    for _ in range(2):
        add: list[tuple[int, int]] = []
        for y in range(h):
            for x in range(w):
                if bg[idx(x, y)]:
                    continue
                if not _is_camp_gray_plate(*px[x, y]):
                    continue
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and bg[idx(nx, ny)]:
                        add.append((x, y))
                        break
        for x, y in add:
            bg[idx(x, y)] = 1
    for y in range(h):
        for x in range(w):
            if bg[idx(x, y)]:
                r, g, b, _a = px[x, y]
                px[x, y] = (r, g, b, 0)
    return out


def make_acid_drip_splash() -> None:
    """64x48 pink droplet splash puddle with thick brown outline."""
    im = Image.new("RGBA", (64, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    outline = (92, 48, 28, 255)
    fill = (220, 90, 160, 255)
    fill_hi = (245, 150, 190, 255)
    # Main puddle
    d.ellipse((6, 22, 58, 44), fill=outline)
    d.ellipse((10, 25, 54, 41), fill=fill)
    d.ellipse((18, 27, 36, 35), fill=fill_hi)
    # Splash droplets
    for cx, cy, r in ((12, 16, 5), (32, 10, 7), (48, 15, 5), (40, 20, 4), (20, 20, 4)):
        d.ellipse((cx - r - 2, cy - r - 2, cx + r + 2, cy + r + 2), fill=outline)
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill)
    d.ellipse((30, 6, 36, 14), fill=outline)
    d.ellipse((31, 7, 35, 13), fill=fill_hi)
    _save(im, OUT / "acid_drip_splash.png")
    print(f"acid_drip_splash: clear%={_clear_pct(im):.1f}")


def make_stalactite_hang() -> None:
    """48x96 dropping tooth — flat rocky crown for ceiling join, taper to tip."""
    import math
    import random

    rng = random.Random(17)
    w, h = 48, 96
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()

    def rock(x: int, y: int, shade: float = 1.0) -> tuple[int, int, int, int]:
        n = math.sin(x * 0.21) * 6 + math.cos(y * 0.17) * 5
        base = 72 + int(n)
        r = int(max(28, min(130, (base + 8) * shade)))
        g = int(max(24, min(110, (base - 6) * shade)))
        b = int(max(40, min(140, (base + 18) * shade)))
        return (r, g, b, 255)

    # Width envelope: wide flat crown, then taper.
    for y in range(h):
        t = y / float(h - 1)
        if y < 10:
            half = 21.0 - y * 0.15
        else:
            half = 20.0 * (1.0 - ((t - 0.08) / 0.92) ** 1.35) + 1.2
        # Mild irregular silhouette.
        half += 1.4 * math.sin(y * 0.33 + 0.4) + 0.8 * math.sin(y * 0.11)
        cx = (w - 1) * 0.5
        x0 = int(round(cx - half))
        x1 = int(round(cx + half))
        for x in range(max(0, x0), min(w, x1 + 1)):
            edge = min(x - x0, x1 - x)
            shade = 0.78 + 0.22 * (edge / max(1.0, half))
            if y < 8:
                shade *= 0.92  # slightly darker join into ceiling rock
            col = rock(x, y, shade)
            # Warm outline
            if edge <= 1 or y >= h - 2:
                col = (max(18, col[0] - 28), max(14, col[1] - 28), max(24, col[2] - 22), 255)
            px[x, y] = col

    # Segment ridges for cowboy-style rock layers.
    d = ImageDraw.Draw(im)
    for y in (14, 28, 44, 60, 74):
        span = 10 + int((1.0 - y / h) * 10)
        d.arc((24 - span, y - 3, 24 + span, y + 5), 200, 340, fill=(48, 36, 54, 200), width=1)

    # Pink crystal flecks
    for x, y in ((18, 16), (28, 24), (22, 38), (26, 52), (23, 68)):
        if px[x, y][3] < 200:
            continue
        d.ellipse((x, y, x + 3, y + 4), fill=(210, 120, 165, 230))

    # Ensure top row is fully opaque across the crown for ceiling attach.
    for x in range(6, 42):
        if px[x, 0][3] < 8:
            px[x, 0] = rock(x, 0, 0.85)
        if px[x, 1][3] < 8:
            px[x, 1] = rock(x, 1, 0.88)

    _save(im, OUT / "stalactite.png")
    print(f"stalactite: clear%={_clear_pct(im):.1f}")


def make_stalactite_static() -> None:
    """40x80 decorative hanging spike — shorter cousin of the droppable tooth."""
    import math
    import random

    rng = random.Random(23)
    w, h = 40, 80
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()

    def rock(x: int, y: int, shade: float = 1.0) -> tuple[int, int, int, int]:
        n = math.sin(x * 0.25) * 5 + math.cos(y * 0.19) * 4
        base = 68 + int(n)
        r = int(max(26, min(120, (base + 6) * shade)))
        g = int(max(22, min(100, (base - 8) * shade)))
        b = int(max(36, min(130, (base + 16) * shade)))
        return (r, g, b, 255)

    for y in range(h):
        t = y / float(h - 1)
        half = 16.5 * (1.0 - t ** 1.25) + 1.0
        half += 1.1 * math.sin(y * 0.4)
        cx = (w - 1) * 0.5
        x0 = int(round(cx - half))
        x1 = int(round(cx + half))
        for x in range(max(0, x0), min(w, x1 + 1)):
            edge = min(x - x0, x1 - x)
            shade = 0.8 + 0.2 * (edge / max(1.0, half))
            col = rock(x, y, shade)
            if edge <= 1 or y >= h - 2:
                col = (max(16, col[0] - 26), max(12, col[1] - 26), max(22, col[2] - 20), 255)
            px[x, y] = col

    d = ImageDraw.Draw(im)
    for y in (12, 26, 42, 56):
        span = 7 + int((1.0 - y / h) * 8)
        d.arc((20 - span, y - 2, 20 + span, y + 4), 200, 340, fill=(44, 32, 50, 190), width=1)
    for x, y in ((14, 14), (24, 22), (18, 36), (22, 50)):
        if px[x, y][3] > 200:
            d.ellipse((x, y, x + 2, y + 3), fill=(200, 115, 160, 220))
    for x in range(5, 35):
        if px[x, 0][3] < 8:
            px[x, 0] = rock(x, 0, 0.85)

    _save(im, OUT / "stalactite_static.png")
    print(f"stalactite_static: clear%={_clear_pct(im):.1f}")


def make_cave_ceiling_fill() -> None:
    """Seamless dense slate fill used above the hanging lip (closes sky gaps)."""
    import math
    import random

    rng = random.Random(61)
    w, h = 256, 128
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    for y in range(h):
        for x in range(w):
            n = (
                math.sin(x * 0.09) * 7
                + math.cos(y * 0.13) * 6
                + math.sin((x + y) * 0.05) * 5
                + rng.randint(-4, 4)
            )
            base = 52 + int(n)
            # Slightly darker toward the very top so the band reads as deep rock.
            top_shade = 0.82 + 0.18 * (y / max(1, h - 1))
            r = int(max(18, min(105, (base + 4) * top_shade)))
            g = int(max(16, min(92, (base - 8) * top_shade)))
            b = int(max(28, min(118, (base + 14) * top_shade)))
            px[x, y] = (r, g, b, 255)
    # Soft mineral flecks (keep dim so the fill reads as rock, not stars).
    for _ in range(40):
        x = rng.randint(2, w - 3)
        y = rng.randint(2, h - 3)
        pr = 140 + rng.randint(-15, 25)
        pg = 70 + rng.randint(-10, 20)
        pb = 110 + rng.randint(-15, 20)
        px[x, y] = (pr, pg, pb, 255)
    # Larger packed-rock blotches for seam-hiding when tiled.
    for _ in range(28):
        cx = rng.randint(8, w - 9)
        cy = rng.randint(8, h - 9)
        rad = rng.randint(4, 10)
        shade = 0.88 + rng.random() * 0.18
        for dy in range(-rad, rad + 1):
            for dx in range(-rad, rad + 1):
                if dx * dx + dy * dy > rad * rad:
                    continue
                nx, ny = (cx + dx) % w, (cy + dy) % h
                r, g, b, _a = px[nx, ny]
                px[nx, ny] = (
                    int(max(16, min(110, r * shade))),
                    int(max(14, min(95, g * shade))),
                    int(max(24, min(120, b * shade))),
                    255,
                )
    _save(im, OUT / "cave_ceiling_fill.png")
    print(f"cave_ceiling_fill: clear%={_clear_pct(im):.1f}")


def make_cave_ceiling_tile() -> None:
    """512x140 wavy hanging lip — solid rock above, transparent below the curve."""
    w, h = 512, 140
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    import math
    import random

    rng = random.Random(42)

    def rock_color(x: int, y: int) -> tuple[int, int, int, int]:
        n = (math.sin(x * 0.07) + math.cos(y * 0.11) + math.sin((x + y) * 0.05)) * 8
        base = 58 + int(n)
        r = max(20, min(110, base + rng.randint(-6, 6)))
        g = max(18, min(95, base - 8 + rng.randint(-6, 6)))
        b = max(30, min(120, base + 12 + rng.randint(-6, 6)))
        return (r, g, b, 255)

    # Bottom rock edge: wavy curve; short fused nubs only (game teeth are separate sprites).
    for x in range(w):
        wave = (
            78
            + 16 * math.sin(x * 0.022)
            + 9 * math.sin(x * 0.06 + 1.2)
            + 5 * math.cos(x * 0.013)
        )
        tooth = 0
        local = x % 56
        if 10 <= local <= 18:
            t = (local - 10) / 8.0
            tooth = int(10 * (1.0 - abs(t - 0.5) * 2) ** 0.7)
        elif 34 <= local <= 40:
            t = (local - 34) / 6.0
            tooth = int(7 * (1.0 - abs(t - 0.5) * 2) ** 0.7)
        edge = int(wave + tooth)
        for y in range(0, min(h, edge + 1)):
            col = rock_color(x, y)
            if y >= edge - 1:
                px[x, y] = (
                    max(10, col[0] - 22),
                    max(8, col[1] - 22),
                    max(15, col[2] - 18),
                    255,
                )
            else:
                px[x, y] = col

    for _ in range(110):
        x = rng.randint(4, w - 5)
        y = rng.randint(4, 64)
        if px[x, y][3] < 200:
            continue
        pr = 200 + rng.randint(-20, 30)
        pg = 100 + rng.randint(-20, 40)
        pb = 140 + rng.randint(-20, 30)
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] >= 200:
                    if abs(dx) + abs(dy) <= 1 or rng.random() < 0.4:
                        px[nx, ny] = (pr, pg, pb, 255)

    _save(im, OUT / "cave_ceiling_tile.png")
    print(f"cave_ceiling_tile: clear%={_clear_pct(im):.1f}")


def fix_floors() -> None:
    floor = OUT / "cave_floor_tile.png"
    dirt = OUT / "cave_dirt_tile.png"
    # Prefer re-cut from source then solidify edge-to-edge (no sky holes when tiled).
    floor_src = SOURCE / "cave_floor_concept.png"
    if floor_src.is_file():
        cut = cutout(floor_src, level=185)
        framed = _fit(cut, (200, 84))
        _save(framed, floor)
    solidify_cave_floor_tile(floor, (200, 84))

    dirt_src = SOURCE / "cave_dirt_concept.png"
    if dirt_src.is_file():
        cut = cutout(dirt_src, level=185)
        framed = _fit(cut, (200, 38))
        _save(framed, dirt)
    solidify_cave_floor_tile(dirt, (200, 38))


def solidify_cave_sky_edges() -> None:
    """Fill transparent top/bottom margins so the wash can meet the trail floor."""
    import math
    import random

    path = OUT / "cave_sky.png"
    if not path.is_file():
        return
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    rng = random.Random(44)

    def sample_row(y: int) -> tuple[int, int, int]:
        samples: list[tuple[int, int, int]] = []
        for x in range(0, w, 4):
            r, g, b, a = px[x, y]
            if a >= 200:
                samples.append((r, g, b))
        if not samples:
            return (48, 44, 72)
        return (
            sum(c[0] for c in samples) // len(samples),
            sum(c[1] for c in samples) // len(samples),
            sum(c[2] for c in samples) // len(samples),
        )

    # Nearest opaque rows for top/bottom extension.
    top_opaque = 0
    for y in range(h):
        if sum(1 for x in range(w) if px[x, y][3] >= 200) > w * 0.4:
            top_opaque = y
            break
    bottom_opaque = h - 1
    for y in range(h - 1, -1, -1):
        if sum(1 for x in range(w) if px[x, y][3] >= 200) > w * 0.4:
            bottom_opaque = y
            break

    top_col = sample_row(top_opaque)
    bot_col = sample_row(bottom_opaque)
    filled = 0
    for y in range(0, top_opaque):
        for x in range(w):
            if px[x, y][3] >= 250:
                continue
            n = int(math.sin(x * 0.05 + y * 0.02) * 4)
            px[x, y] = (
                max(20, min(100, top_col[0] + n + rng.randint(-3, 3))),
                max(18, min(90, top_col[1] + n + rng.randint(-3, 3))),
                max(30, min(120, top_col[2] + n + rng.randint(-3, 3))),
                255,
            )
            filled += 1
    for y in range(bottom_opaque + 1, h):
        for x in range(w):
            if px[x, y][3] >= 250:
                continue
            n = int(math.sin(x * 0.07 + y * 0.03) * 3)
            px[x, y] = (
                max(18, min(90, bot_col[0] + n + rng.randint(-3, 3))),
                max(16, min(80, bot_col[1] + n + rng.randint(-3, 3))),
                max(28, min(110, bot_col[2] + n + rng.randint(-3, 3))),
                255,
            )
            filled += 1

    # Also close any soft fringe near the bottom so stretch doesn't open a seam.
    for y in range(max(0, bottom_opaque - 4), h):
        for x in range(w):
            if px[x, y][3] >= 250:
                continue
            n = int(math.sin(x * 0.07) * 3)
            px[x, y] = (
                max(18, min(90, bot_col[0] + n)),
                max(16, min(80, bot_col[1] + n)),
                max(28, min(110, bot_col[2] + n)),
                255,
            )
            filled += 1

    _save(im, path)
    print(f"cave_sky: solidified edges, filled≈{filled}, clear%={_clear_pct(im):.1f}")


def _rightmost_opaque_x(im: Image.Image, *, alpha_thresh: int = 8) -> int | None:
    w, h = im.size
    px = im.load()
    for x in range(w - 1, -1, -1):
        if any(px[x, y][3] > alpha_thresh for y in range(h)):
            return x
    return None


def _orphan_edge_columns(im: Image.Image, *, side: str, alpha_thresh: int = 8) -> list[int]:
    """Columns at the far edge that are thin (<25) with a vertical gap (bleed)."""
    w, h = im.size
    px = im.load()
    bbox = _content_bbox_alpha(px, w, h, alpha_thresh=alpha_thresh)
    if bbox is None:
        return []
    x0, _y0, x1, _y1 = bbox
    bad: list[int] = []
    cols = range(max(x0, x1 - 3), x1) if side == "right" else range(x0, min(x1, x0 + 3))
    for x in cols:
        ys = _column_opaque_ys(px, x, h, alpha_thresh=alpha_thresh)
        if ys and len(ys) < 25 and _has_vertical_gap(ys):
            bad.append(x)
    return bad


def verify() -> None:
    print("\n=== verification ===")
    b0 = Image.open(OUT / "cave_bat_0.png").convert("RGBA")
    b1 = Image.open(OUT / "cave_bat_1.png").convert("RGBA")
    bat_diff = list(b0.get_flattened_data()) != list(b1.get_flattened_data())
    rm0 = _rightmost_opaque_x(b0)
    orphans0 = _orphan_edge_columns(b0, side="right")
    print(f"cave_bat_0 clear%={_clear_pct(b0):.1f} size={b0.size} rightmost_opaque_x={rm0}")
    print(f"cave_bat_0 orphan_edge_cols={orphans0}")
    print(f"cave_bat_1 clear%={_clear_pct(b1):.1f} size={b1.size}")
    print(f"bat0!=bat1: {bat_diff}")
    if orphans0:
        raise RuntimeError(f"cave_bat_0 still has orphan edge columns: {orphans0}")

    idle = Image.open(OUT / "skeleton.png").convert("RGBA")
    print(f"skeleton idle size={idle.size} content_h={_content_height(idle)}")
    for i in (0, 1):
        im = Image.open(OUT / f"skeleton_walk_{i}.png").convert("RGBA")
        print(
            f"skeleton_walk_{i} size={im.size} clear%={_clear_pct(im):.1f} "
            f"content_h={_content_height(im)}"
        )

    for name in (
        "ladder.png",
        "checkpoint_cave_active.png",
        "checkpoint_cave_inactive.png",
        "stalactite_impact.png",
        "cave_floor_tile.png",
        "cave_dirt_tile.png",
        "acid_drip_splash.png",
        "stalactite_static.png",
        "stalactite.png",
        "cave_ceiling_tile.png",
        "cave_ceiling_fill.png",
        "cave_ceiling_ll_0.png",
        "cave_ceiling_lh_0.png",
        "cave_ceiling_hl_0.png",
        "cave_ceiling_hh_0.png",
        "cave_sky.png",
    ):
        p = OUT / name
        if p.is_file():
            im = Image.open(p).convert("RGBA")
            print(f"{name}: size={im.size} clear%={_clear_pct(im):.1f}")
            if name in ("cave_floor_tile.png", "cave_dirt_tile.png") and _clear_pct(im) > 0.05:
                raise RuntimeError(f"{name} must be fully opaque (got clear%={_clear_pct(im):.1f})")
            if name == "cave_sky.png" and _clear_pct(im) > 0.05:
                raise RuntimeError(f"cave_sky must be opaque edge-to-edge (clear%={_clear_pct(im):.1f})")


def main() -> int:
    fix_bats()
    fix_skeleton_walk()
    fix_skeleton_bow_gaps()
    fix_ladder()
    fix_camp_and_impact()
    fix_floors()
    make_acid_drip_splash()
    make_stalactite_hang()
    make_stalactite_static()
    # Multi-height cowboy ceiling segments (also refreshes fill + legacy tile).
    import subprocess

    subprocess.check_call([sys.executable, str(ROOT / "tools" / "build_cave_ceiling_segments.py")])
    solidify_cave_sky_edges()
    verify()
    print("\n=== files written ===")
    # Unique preserve order
    seen: set[Path] = set()
    for p in WRITTEN:
        if p in seen:
            continue
        seen.add(p)
        print(p.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
