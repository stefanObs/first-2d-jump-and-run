"""Cowgirl body and face edits — jeans kept, no skirt."""

from __future__ import annotations

from PIL import Image

from cowgirl_hair import is_hair_pixel, is_skin_pixel

# Reference cue: rolled pink jacket cuffs — mapped to game's red family at gameplay scale.
CUFF = (214, 92, 108, 255)
CUFF_DARK = (178, 62, 82, 255)


def _is_shirt(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and b > 70 and abs(r - b) < 35 and g > 55 and r < 150


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
