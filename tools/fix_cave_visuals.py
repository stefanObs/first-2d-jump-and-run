#!/usr/bin/env python3
"""Fix cave biome cutouts, strip slicing, ladder matte, and procedural fillers."""

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


def _keep_largest_component(im: Image.Image, *, alpha_thresh: int = 8) -> Image.Image:
    """Clear opaque pixels not 4-connected to the largest blob (edge bleed)."""
    out = im.copy()
    w, h = out.size
    px = out.load()
    visited = [[False] * w for _ in range(h)]
    comps: list[list[tuple[int, int]]] = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] <= alpha_thresh or visited[y][x]:
                continue
            q: deque[tuple[int, int]] = deque([(x, y)])
            visited[y][x] = True
            pixels: list[tuple[int, int]] = []
            while q:
                cx, cy = q.popleft()
                pixels.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if (
                        0 <= nx < w
                        and 0 <= ny < h
                        and not visited[ny][nx]
                        and px[nx, ny][3] > alpha_thresh
                    ):
                        visited[ny][nx] = True
                        q.append((nx, ny))
            comps.append(pixels)
    if len(comps) <= 1:
        return out
    comps.sort(key=len, reverse=True)
    for pixels in comps[1:]:
        for x, y in pixels:
            r, g, b, _ = px[x, y]
            px[x, y] = (r, g, b, 0)
    return out


def _trim_far_edge_strip(im: Image.Image, *, side: str, max_cols: int = 4) -> Image.Image:
    """Clear a thin right/left strip that is disconnected from the main body."""
    out = im.copy()
    w, h = out.size
    if w < 8:
        return out
    px = out.load()
    # Largest-component mask via flood from CoM of opaque pixels.
    sx = sy = n = 0
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 8:
                sx += x
                sy += y
                n += 1
    if n == 0:
        return out
    cx, cy = sx // n, sy // n
    start = None
    for r in range(max(w, h)):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                x, y = cx + dx, cy + dy
                if 0 <= x < w and 0 <= y < h and px[x, y][3] > 8:
                    start = (x, y)
                    break
            if start is not None:
                break
        if start is not None:
            break
    if start is None:
        return out
    connected: set[tuple[int, int]] = {start}
    q: deque[tuple[int, int]] = deque([start])
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if (
                0 <= nx < w
                and 0 <= ny < h
                and (nx, ny) not in connected
                and px[nx, ny][3] > 8
            ):
                connected.add((nx, ny))
                q.append((nx, ny))
    xs = range(w - max_cols, w) if side == "right" else range(0, max_cols)
    for x in xs:
        for y in range(h):
            if px[x, y][3] > 8 and (x, y) not in connected:
                r, g, b, _ = px[x, y]
                px[x, y] = (r, g, b, 0)
    return out


def _clean_bat_figure(fig: Image.Image, *, index: int) -> Image.Image:
    """Drop neighboring-bat bleed after a half-slice."""
    cleaned = _keep_largest_component(fig)
    side = "right" if index == 0 else "left"
    return _trim_far_edge_strip(cleaned, side=side, max_cols=4)


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
        _save(framed, OUT / f"cave_bat_{i}.png")
        print(f"cave_bat_{i}: clear%={_clear_pct(framed):.1f}")


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
        path = OUT / f"skeleton_walk_{i}.png"
        _save(framed, path)
        print(
            f"skeleton_walk_{i}: clear%={_clear_pct(framed):.1f} "
            f"content_h={_content_height(framed)}"
        )
        tinted = _magenta_tint(framed)
        cpath = OUT / f"skeleton_crystal_walk_{i}.png"
        _save(tinted, cpath)
        print(f"skeleton_crystal_walk_{i}: clear%={_clear_pct(tinted):.1f}")


def fix_camp_and_impact() -> None:
    camp_src = SOURCE / "cave_camp_concept.png"
    if camp_src.is_file():
        # Camp matte sits ~180–185; default 208 / 185 leave a gray plate.
        cut = cutout(camp_src, level=180)
        active = _feet(cut, (96, 96), target_h=88, baseline=95)
        _save(active, OUT / "checkpoint_cave_active.png")
        print(f"checkpoint_cave_active: clear%={_clear_pct(active):.1f}")
        rgb = ImageEnhance.Brightness(active.convert("RGB")).enhance(0.72)
        inactive = Image.merge("RGBA", (*rgb.split(), active.split()[-1]))
        _save(inactive, OUT / "checkpoint_cave_inactive.png")
        print(f"checkpoint_cave_inactive: clear%={_clear_pct(inactive):.1f}")

    impact_src = SOURCE / "cave_stalactite_impact_concept.png"
    if impact_src.is_file():
        cut = cutout(impact_src, level=185)
        framed = _fit(cut, (96, 64))
        _save(framed, OUT / "stalactite_impact.png")
        print(f"stalactite_impact: clear%={_clear_pct(framed):.1f}")


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


def make_stalactite_static() -> None:
    """48x96 decorative hanging spike matching stalactite.png palette."""
    # Sample palette from shipped falling stalactite if present.
    palette = [(72, 60, 82), (84, 70, 94), (103, 84, 112), (139, 132, 151), (55, 42, 58)]
    pinks = [(180, 110, 150), (200, 130, 165)]
    src = OUT / "stalactite.png"
    if src.is_file():
        st = Image.open(src).convert("RGBA")
        colors: list[tuple[int, int, int]] = []
        px = st.load()
        for y in range(st.size[1]):
            for x in range(st.size[0]):
                r, g, b, a = px[x, y]
                if a > 200:
                    colors.append((r, g, b))
        if colors:
            # Prefer darker slate tones.
            colors.sort(key=lambda c: sum(c))
            palette = colors[:: max(1, len(colors) // 5)][:5]

    im = Image.new("RGBA", (48, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # Tapered spike from top.
    outline = (40, 28, 38, 255)
    body = (*palette[0], 255)
    mid = (*palette[min(1, len(palette) - 1)], 255)
    tip = (*palette[min(2, len(palette) - 1)], 255)
    points_outer = [(10, 2), (38, 2), (28, 88), (20, 88)]
    d.polygon(points_outer, fill=outline)
    points_inner = [(13, 5), (35, 5), (26, 84), (22, 84)]
    d.polygon(points_inner, fill=body)
    d.polygon([(16, 8), (30, 8), (25, 50), (20, 50)], fill=mid)
    d.polygon([(20, 55), (26, 55), (24, 82), (22, 82)], fill=tip)
    # Pink crystal flecks
    for x, y in ((18, 18), (28, 28), (22, 40), (26, 60)):
        d.ellipse((x, y, x + 3, y + 4), fill=(*pinks[0], 220))
    # Tip point
    d.polygon([(22, 84), (26, 84), (24, 94)], fill=outline)
    d.polygon([(23, 84), (25, 84), (24, 92)], fill=tip)
    _save(im, OUT / "stalactite_static.png")
    print(f"stalactite_static: clear%={_clear_pct(im):.1f}")


def make_cave_ceiling_tile() -> None:
    """400x160 curved dark slate ceiling band with pink flecks + teeth."""
    w, h = 400, 160
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

    # Bottom rock edge: wavy curve near mid-lower area, transparent below.
    for x in range(w):
        wave = (
            88
            + 18 * math.sin(x * 0.028)
            + 10 * math.sin(x * 0.07 + 1.2)
            + 6 * math.cos(x * 0.015)
        )
        # Short stalactite teeth along bottom.
        tooth = 0
        local = x % 48
        if 8 <= local <= 18:
            t = (local - 8) / 10.0
            tooth = int(22 * (1.0 - abs(t - 0.5) * 2) ** 0.7)
        elif 28 <= local <= 36:
            t = (local - 28) / 8.0
            tooth = int(14 * (1.0 - abs(t - 0.5) * 2) ** 0.7)
        edge = int(wave + tooth)
        for y in range(0, min(h, edge + 1)):
            # Soft crust near edge
            if y > edge - 3:
                col = rock_color(x, y)
                fade = 255 if y <= edge else 0
                if y == edge:
                    # Darker outline
                    px[x, y] = (max(10, col[0] - 25), max(8, col[1] - 25), max(15, col[2] - 20), 255)
                else:
                    px[x, y] = col
            else:
                px[x, y] = rock_color(x, y)

    # Pink flecks in rock mass
    for _ in range(90):
        x = rng.randint(4, w - 5)
        y = rng.randint(4, 70)
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

    # Darker top band (attached to ceiling)
    for y in range(0, 12):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            fac = 0.75 + y * 0.02
            px[x, y] = (int(r * fac), int(g * fac), int(b * fac), a)

    _save(im, OUT / "cave_ceiling_tile.png")
    print(f"cave_ceiling_tile: clear%={_clear_pct(im):.1f}")


def fix_floors() -> None:
    floor = OUT / "cave_floor_tile.png"
    dirt = OUT / "cave_dirt_tile.png"
    # Prefer re-cut from source then densify to full tile size.
    floor_src = SOURCE / "cave_floor_concept.png"
    if floor_src.is_file():
        cut = cutout(floor_src, level=185)
        framed = _fit(cut, (200, 84))
        _save(framed, floor)
    densify_tile(floor, (200, 84))

    dirt_src = SOURCE / "cave_dirt_concept.png"
    if dirt_src.is_file():
        cut = cutout(dirt_src, level=185)
        framed = _fit(cut, (200, 38))
        _save(framed, dirt)
    densify_tile(dirt, (200, 38))


def verify() -> None:
    print("\n=== verification ===")
    b0 = Image.open(OUT / "cave_bat_0.png").convert("RGBA")
    b1 = Image.open(OUT / "cave_bat_1.png").convert("RGBA")
    bat_diff = list(b0.get_flattened_data()) != list(b1.get_flattened_data())
    print(f"cave_bat_0 clear%={_clear_pct(b0):.1f} size={b0.size}")
    print(f"cave_bat_1 clear%={_clear_pct(b1):.1f} size={b1.size}")
    print(f"bat0!=bat1: {bat_diff}")

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
        "cave_ceiling_tile.png",
    ):
        p = OUT / name
        if p.is_file():
            im = Image.open(p).convert("RGBA")
            print(f"{name}: size={im.size} clear%={_clear_pct(im):.1f}")


def main() -> int:
    fix_bats()
    fix_skeleton_walk()
    fix_ladder()
    fix_camp_and_impact()
    fix_floors()
    make_acid_drip_splash()
    make_stalactite_static()
    make_cave_ceiling_tile()
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
