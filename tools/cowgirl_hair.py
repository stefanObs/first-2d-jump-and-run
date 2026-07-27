"""Mounted cowgirl rider hair — pigtails painted onto horse sprites."""

from __future__ import annotations

import math

from PIL import Image

Palette = tuple[
    tuple[int, int, int, int],
    tuple[int, int, int, int],
    tuple[int, int, int, int],
    tuple[int, int, int, int],
]

HAIR_BASE = (168, 112, 36, 255)
HAIR_DARK = (118, 68, 18, 255)
HAIR_LIGHT = (214, 158, 62, 255)
HAIR_INK = (42, 24, 8, 255)
DEFAULT_BANDANA = (208, 48, 38, 255)


def is_hair_pixel(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and 45 < r < 220 and g < 130 and b < 110 and r > g and r > b


def is_skin_pixel(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and r > 175 and g > 120 and b > 90


def _is_residual_cowboy_hair(r: int, g: int, b: int, a: int) -> bool:
    if a < 40:
        return False
    if is_hair_pixel(r, g, b, a):
        return True
    if 25 <= r <= 120 and g <= 85 and b <= 75 and r >= g and r >= b:
        return True
    if 50 <= r <= 180 and 50 <= g <= 120 and b <= 120 and r + g + b < 380:
        return abs(r - g) < 25 and b < min(r, g) + 30
    return False


def _row_hair_span(px, y: int, w: int) -> int:
    xs = [x for x in range(w) if is_hair_pixel(*px[x, y][:4])]
    return 0 if len(xs) < 2 else max(xs) - min(xs)


def is_hat_brim_pixel(px, x: int, y: int, w: int, h: int) -> bool:
    return (
        is_hair_pixel(*px[x, y][:4])
        and y < 18
        and _row_hair_span(px, y, w) > 20
    )


def is_head_hair_pixel(px, x: int, y: int, w: int, h: int) -> bool:
    if not is_hair_pixel(*px[x, y][:4]) or is_hat_brim_pixel(px, x, y, w, h):
        return False
    if y >= 17:
        return True
    for dx, dy in [(-1, 0), (1, 0), (0, 1), (0, -1)]:
        nx, ny = x + dx, y + dy
        if 0 <= nx < w and 0 <= ny < h and is_skin_pixel(*px[nx, ny][:4]):
            return True
    return False


def cowgirl_hair_palette() -> Palette:
    return HAIR_BASE, HAIR_DARK, HAIR_LIGHT, HAIR_INK


def _shade(color: tuple[int, int, int, int], amount: float) -> tuple[int, int, int, int]:
    return (
        max(0, min(255, int(color[0] * amount))),
        max(0, min(255, int(color[1] * amount))),
        max(0, min(255, int(color[2] * amount))),
        color[3],
    )


def _avg(colors: list[tuple[int, int, int, int]]) -> tuple[int, int, int, int]:
    if not colors:
        return HAIR_BASE
    return (
        sum(color[0] for color in colors) // len(colors),
        sum(color[1] for color in colors) // len(colors),
        sum(color[2] for color in colors) // len(colors),
        255,
    )


def sample_bandana(img: Image.Image) -> tuple[int, int, int, int]:
    px = img.load()
    w, h = img.size
    reds = [
        tuple(px[x, y][:4])
        for y in range(12, min(h, 28))
        for x in range(w)
        if px[x, y][3] > 40 and px[x, y][0] > 150 and px[x, y][1] < 90 and px[x, y][2] < 90
    ]
    return _avg(reds) if reds else DEFAULT_BANDANA


def clear_mounted_cowboy_head_hair(
    img: Image.Image,
    *,
    x0: int = 142,
    x1: int = 206,
    y0: int = 19,
    y1: int = 36,
) -> None:
    px = img.load()
    w, h = img.size
    for y in range(y0, min(y1, h)):
        for x in range(max(0, x0), min(x1, w)):
            r, g, b, a = px[x, y][:4]
            if a >= 40 and not is_skin_pixel(r, g, b, a) and _is_residual_cowboy_hair(r, g, b, a):
                px[x, y] = (0, 0, 0, 0)


def _is_cowgirl_hair_color(r: int, g: int, b: int) -> bool:
    base, dark, light, ink = cowgirl_hair_palette()
    if (r, g, b) in {base[:3], dark[:3], light[:3], ink[:3]}:
        return True
    return r > 130 and g > 75 and b < 85


def touch_up_mounted_head_hair(
    img: Image.Image,
    *,
    x0: int = 142,
    x1: int = 206,
    y0: int = 19,
    y1: int = 36,
) -> None:
    px = img.load()
    w, h = img.size
    base, dark, _light, _ink = cowgirl_hair_palette()
    mid_x = (x0 + x1) // 2
    for y in range(y0, min(y1, h)):
        for x in range(max(0, x0), min(x1, w)):
            r, g, b, a = px[x, y][:4]
            if a < 40 or is_skin_pixel(r, g, b, a):
                continue
            if not _is_residual_cowboy_hair(r, g, b, a) or _is_cowgirl_hair_color(r, g, b):
                continue
            px[x, y] = dark if x < mid_x - 4 or x > mid_x + 4 else base


def find_mounted_braid_anchors(
    img: Image.Image,
    *,
    x0: int = 145,
    x1: int = 210,
    y0: int = 27,
    y1: int = 33,
) -> tuple[tuple[int, int], tuple[int, int], tuple[int, int], tuple[int, int], tuple[int, int], tuple[int, int]]:
    px = img.load()
    center_x = (x0 + x1) // 2
    left_pts: list[tuple[int, int]] = []
    right_pts: list[tuple[int, int]] = []
    for y in range(y0, y1):
        for x in range(x0, x1):
            if not is_hair_pixel(*px[x, y][:4]):
                continue
            if x <= center_x - 14:
                left_pts.append((x, y))
            elif x >= center_x + 10:
                right_pts.append((x, y))
    if not left_pts or not right_pts:
        y = 30
        return (
            (154, y),
            (144, y + 22),
            (132, y + 58),
            (192, y),
            (202, y + 22),
            (214, y + 58),
        )
    left = max(left_pts, key=lambda point: (-abs(point[1] - 30), point[0]))
    right = min(right_pts, key=lambda point: (-abs(point[1] - 30), point[0]))
    lx, ly = left
    rx, ry = right
    return (
        left,
        (lx - 10, ly + 22),
        (lx - 16, ly + 58),
        right,
        (rx + 10, ry + 22),
        (rx + 16, ry + 58),
    )


def _bezier2(
    start: tuple[int, int],
    control: tuple[int, int],
    end: tuple[int, int],
    steps: int,
) -> list[tuple[int, int]]:
    points: list[tuple[int, int]] = []
    for i in range(steps + 1):
        t = i / steps
        u = 1.0 - t
        points.append(
            (
                int(u * u * start[0] + 2 * u * t * control[0] + t * t * end[0]),
                int(u * u * start[1] + 2 * u * t * control[1] + t * t * end[1]),
            )
        )
    return points


def _blob_radius(t: float, scale: float) -> int:
    if t < 0.15:
        return max(2, int(round(2.6 * scale)))
    if t < 0.55:
        return max(2, int(round(2.1 * scale)))
    if t < 0.82:
        return max(1, int(round(1.6 * scale)))
    return max(1, int(round(1.1 * scale)))


def _strand_color(
    side: str,
    dx: int,
    dy: int,
    radius: int,
    base: tuple[int, int, int, int],
    dark: tuple[int, int, int, int],
    light: tuple[int, int, int, int],
    ink: tuple[int, int, int, int],
) -> tuple[int, int, int, int]:
    if side == "left":
        if dx <= -radius:
            return ink
        if dy <= -radius + 1 or (dx >= radius - 1 and dy <= 0):
            return light
        if dx == 0 and dy >= 0:
            return base
        return dark
    if dx >= radius:
        return ink
    if dy <= -radius + 1 or (dx <= -radius + 1 and dy <= 0):
        return light
    if dx == 0 and dy >= 0:
        return base
    return dark


def _paint_head_hair(px, x: int, y: int, w: int, h: int, color: tuple[int, int, int, int]) -> None:
    if not (0 <= x < w and 0 <= y < h):
        return
    r, g, b, a = px[x, y][:4]
    if a < 40 or is_head_hair_pixel(px, x, y, w, h):
        px[x, y] = color


def draw_wavy_pigtail(
    img: Image.Image,
    start: tuple[int, int],
    control: tuple[int, int],
    end: tuple[int, int],
    side: str,
    palette: Palette,
    *,
    scale: float = 1.0,
    wave: float = 1.4,
    phase: float = 0.0,
) -> None:
    px = img.load()
    w, h = img.size
    base, dark, light, ink = palette
    points = _bezier2(start, control, end, max(16, int(18 * scale)))
    total = max(1, len(points) - 1)
    for strand_shift in (0, 1 if side == "left" else -1):
        for i, (cx, cy) in enumerate(points):
            t = i / total
            radius = _blob_radius(t, scale * (0.92 if strand_shift else 1.0))
            wave_dx = int(
                round(math.sin(t * math.pi * 3.2 + phase + (0.6 if side == "right" else 0.0)) * wave * scale)
            )
            wave_dy = int(round(math.cos(t * math.pi * 2.0 + phase * 0.5) * 0.55 * wave * scale))
            sx = cx + (wave_dx if side == "left" else -wave_dx) + strand_shift
            sy = cy + wave_dy
            for dy in range(-radius, radius + 1):
                for dx in range(-radius, radius + 1):
                    if abs(dx) + abs(dy) > radius + 1:
                        continue
                    color = _strand_color(side, dx, dy, radius, base, dark, light, ink)
                    if strand_shift and abs(dx) + abs(dy) > radius and color == base:
                        color = light
                    _paint_head_hair(px, sx + dx, sy + dy, w, h, color)


def draw_mounted_head_fill(
    img: Image.Image,
    left: tuple[int, int],
    right: tuple[int, int],
    palette: Palette,
) -> None:
    px = img.load()
    w, h = img.size
    base, dark, light, ink = palette
    lx, ly = left
    rx, ry = right
    y0 = min(ly, ry) - 3
    y1 = max(ly, ry) + 2
    x0 = min(lx, rx) - 6
    x1 = max(lx, rx) + 6
    cx = (lx + rx) // 2
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            r, g, b, a = px[x, y][:4]
            if a > 40 and is_skin_pixel(r, g, b, a):
                continue
            if a > 40 and not _is_residual_cowboy_hair(r, g, b, a) and not is_hair_pixel(r, g, b, a):
                continue
            t = abs(x - cx) / max(1, (x1 - x0) // 2)
            px[x, y] = ink if t > 0.9 else light if y <= y0 + 1 else base if t < 0.4 else dark


def draw_ribbon_knot(
    img: Image.Image,
    anchor: tuple[int, int],
    ribbon: tuple[int, int, int, int],
    side: str,
    *,
    scale: float = 1.0,
) -> None:
    px = img.load()
    w, h = img.size
    x, y = anchor
    dark = _shade(ribbon, 0.82)
    light = _shade(ribbon, 1.08)
    if side == "left":
        offsets = [(0, 0, ribbon), (-1, 0, dark), (0, 1, dark), (-1, 1, light), (-2, 0, dark)]
    else:
        offsets = [(0, 0, ribbon), (1, 0, dark), (0, 1, dark), (1, 1, light), (2, 0, dark)]
    reach = max(1, int(round(scale)))
    for ox, oy, color in offsets:
        for sx in range(reach):
            for sy in range(reach):
                px_x = x + ox * reach + sx
                px_y = y + oy * reach + sy
                if 0 <= px_x < w and 0 <= px_y < h:
                    r, g, b, a = px[px_x, px_y][:4]
                    if a < 40 or is_hair_pixel(r, g, b, a):
                        px[px_x, px_y] = color


def _mounted_swing(frame_name: str) -> float:
    if "jump" in frame_name:
        return -2.5
    if "ride_1" in frame_name:
        return 1.2
    return 0.0


def draw_mounted_cowgirl_hair(img: Image.Image, frame_name: str = "") -> None:
    palette = cowgirl_hair_palette()
    ribbon = sample_bandana(img)
    swing = _mounted_swing(frame_name)
    wave = max(min(3.0, 1.6 + abs(swing) * 0.35), 2.4)
    phase = swing * 0.45
    left_start, left_ctrl, left_end, right_start, right_ctrl, right_end = find_mounted_braid_anchors(img)
    clear_mounted_cowboy_head_hair(img)
    draw_mounted_head_fill(img, left_start, right_start, palette)
    sway = int(round(swing))
    left_ctrl = (left_ctrl[0] + sway, left_ctrl[1])
    left_end = (left_end[0] + sway * 2, left_end[1])
    right_ctrl = (right_ctrl[0] + sway, right_ctrl[1])
    right_end = (right_end[0] + sway * 2, right_end[1])
    draw_wavy_pigtail(
        img, left_start, left_ctrl, left_end, "left", palette,
        scale=1.85, wave=wave, phase=phase,
    )
    draw_wavy_pigtail(
        img, right_start, right_ctrl, right_end, "right", palette,
        scale=1.85, wave=wave, phase=-phase,
    )
    draw_ribbon_knot(img, left_start, ribbon, "left", scale=1.55)
    draw_ribbon_knot(img, right_start, ribbon, "right", scale=1.55)
    touch_up_mounted_head_hair(img)
