"""Cowgirl body and face edits inspired by the iStock reference, in cowboy pixel style."""

from __future__ import annotations

from PIL import Image

from cowgirl_hair import is_hair_pixel, is_skin_pixel, shade

# Reference cue: rolled pink jacket cuffs — mapped to game's red family at gameplay scale.
CUFF = (214, 92, 108, 255)
CUFF_DARK = (178, 62, 82, 255)
CUFF_LIGHT = (236, 128, 142, 255)


def _is_jeans(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and b > 70 and b > r + 8 and b > g + 5 and g > 45


def _is_shirt(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and b > 70 and abs(r - b) < 35 and g > 55 and r < 150


def _avg(colors: list[tuple[int, int, int, int]]) -> tuple[int, int, int, int]:
    if not colors:
        return (98, 58, 28, 255)
    rs = [c[0] for c in colors]
    gs = [c[1] for c in colors]
    bs = [c[2] for c in colors]
    return (sum(rs) // len(rs), sum(gs) // len(gs), sum(bs) // len(bs), 255)


def _cluster(values: list[int], gap: int = 4) -> list[list[int]]:
    if not values:
        return []
    values = sorted(set(values))
    groups: list[list[int]] = [[values[0]]]
    for value in values[1:]:
        if value - groups[-1][-1] <= gap:
            groups[-1].append(value)
        else:
            groups.append([value])
    return groups


def jeans_to_skirt(img: Image.Image, flare_strength: int = 8) -> None:
    """Denim skirt with a wider feminine flare (reference silhouette)."""
    px = img.load()
    w, h = img.size
    rows: dict[int, list[int]] = {}
    jeans_colors: list[tuple[int, int, int, int]] = []
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if _is_jeans(r, g, b, a):
                rows.setdefault(y, []).append(x)
                jeans_colors.append((r, g, b, a))
    if not rows:
        return

    denim = _avg(jeans_colors)
    denim_dark = shade(denim, 0.76)
    denim_light = shade(denim, 1.1)

    y_min = min(rows)
    y_max = max(rows)
    for y in range(y_min, y_max + 1):
        xs = rows.get(y, [])
        if len(xs) < 2:
            continue
        clusters = _cluster(xs)
        left = clusters[0][0]
        right = clusters[-1][-1]
        progress = (y - y_min) / max(1, y_max - y_min)
        flare = int(progress * flare_strength)
        skirt_left = max(0, left - 3 - flare // 2)
        skirt_right = min(w - 1, right + 3 + flare // 2)
        for x in range(skirt_left, skirt_right + 1):
            r, g, b, a = px[x, y]
            if a < 20 or _is_jeans(r, g, b, a):
                t = (x - skirt_left) / max(1, skirt_right - skirt_left)
                if t < 0.18 or t > 0.82:
                    fill = denim_dark
                elif 0.42 < t < 0.58:
                    fill = denim_light
                else:
                    fill = denim
                px[x, y] = fill


def add_pink_cuffs(img: Image.Image) -> None:
    """Reference rolled-cuff cue on blue shirt sleeve ends."""
    px = img.load()
    w, h = img.size
    for y in range(h):
        row: list[int] = []
        for x in range(w):
            if _is_shirt(*px[x, y][:4]):
                row.append(x)
        if len(row) < 3:
            continue
        clusters = _cluster(row, gap=8)
        for cluster in clusters:
            if len(cluster) < 2:
                continue
            cx = sum(cluster) // len(cluster)
            if cx < w // 2 - 4 or cx > w // 2 + 4:
                for x in cluster:
                    below_shirt = any(
                        0 <= x + dx < w and 0 <= y + dy < h and not _is_shirt(*px[x + dx, y + dy][:4])
                        for dx, dy in [(0, 1), (1, 1), (-1, 1)]
                    )
                    if below_shirt or y >= h - 18:
                        px[x, y] = CUFF_DARK if x == min(cluster) or x == max(cluster) else CUFF


def add_eyelashes(img: Image.Image) -> None:
    """Tiny feminine lash pixels (reference large-eye cue at gameplay scale)."""
    px = img.load()
    w, h = img.size
    ink = (24, 16, 12, 255)
    for y in range(18, 24):
        for x in range(w):
            if not is_skin_pixel(*px[x, y][:4]):
                continue
            for dx, dy in [(-2, -1), (-1, -1), (1, -1), (2, -1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] < 40:
                    px[nx, ny] = ink


def trim_boyish_sideburns(img: Image.Image) -> None:
    """Remove short cowboy side hair so cowgirl pigtails replace it cleanly."""
    px = img.load()
    w, h = img.size
    cx = w // 2
    for y in range(17, 23):
        for x in range(w):
            if not is_hair_pixel(*px[x, y][:4]):
                continue
            if x <= cx - 11 or x >= cx + 9:
                if not is_skin_pixel(*px[x, y][:4]):
                    px[x, y] = (0, 0, 0, 0)


def sample_skirt_denim(img: Image.Image) -> tuple[tuple[int, int, int, int], tuple[int, int, int, int]]:
    px = img.load()
    colors: list[tuple[int, int, int, int]] = []
    for y in range(img.height):
        for x in range(img.width):
            if _is_jeans(*px[x, y][:4]):
                colors.append(px[x, y][:4])
    denim = _avg(colors) if colors else (78, 118, 168, 255)
    return denim, shade(denim, 0.76)


def is_rider_pants(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and b > 85 and b > r and g > 65


def mounted_skirt(img: Image.Image, denim: tuple[int, int, int, int], denim_dark: tuple[int, int, int, int]) -> None:
    px = img.load()
    w, h = img.size
    for y in range(78, 88):
        progress = (y - 78) / 10.0
        panels = (
            range(int(132 - progress * 8), int(152 - progress * 2)),
            range(int(194 + progress * 2), int(214 + progress * 8)),
        )
        for x_range in panels:
            for x in x_range:
                if not (0 <= x < w and 0 <= y < h):
                    continue
                r, g, b, a = px[x, y]
                if a < 40 or not is_skin_pixel(r, g, b, a):
                    continue
                px[x, y] = denim_dark if x < 150 else denim

    for y in range(84, 102):
        row: list[int] = []
        for x in range(124, 214):
            r, g, b, a = px[x, y]
            if is_rider_pants(r, g, b, a):
                row.append(x)
        if len(row) < 3:
            continue
        left = min(row)
        right = max(row)
        flare = int((y - 84) / 18 * 24)
        skirt_left = max(118, left - 10 - flare // 2)
        skirt_right = min(w - 1, right + 10 + flare // 2)
        for x in range(skirt_left, skirt_right + 1):
            r, g, b, a = px[x, y]
            if a < 40:
                continue
            if is_rider_pants(r, g, b, a):
                t = (x - skirt_left) / max(1, skirt_right - skirt_left)
                px[x, y] = denim_dark if t < 0.16 or t > 0.84 else denim


def mounted_pink_cuffs(img: Image.Image) -> None:
    px = img.load()
    for y in range(68, 82):
        for x in range(130, 215):
            if _is_shirt(*px[x, y][:4]) and (x < 148 or x > 196):
                px[x, y] = CUFF if y % 2 == 0 else CUFF_DARK


def trim_mounted_sideburns(px, w: int, h: int) -> None:
    for y in range(24, 40):
        for x in range(142, 218):
            r, g, b, a = px[x, y]
            if a < 40 or not is_hair_pixel(r, g, b, a):
                continue
            if x < 158 or x > 188:
                px[x, y] = (0, 0, 0, 0)
