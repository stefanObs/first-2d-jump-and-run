"""Shared cowgirl hair drawing — wavy pigtails from head under hat."""

from __future__ import annotations

import math
from typing import Callable

from PIL import Image

HairPredicate = Callable[[int, int, int, int], bool]
Palette = tuple[tuple[int, int, int, int], tuple[int, int, int, int], tuple[int, int, int, int], tuple[int, int, int, int]]

# Golden-brown family inspired by reference blonde, mapped to cowboy ink/shade technique.
HAIR_BASE = (168, 112, 36, 255)
HAIR_DARK = (118, 68, 18, 255)
HAIR_LIGHT = (214, 158, 62, 255)
HAIR_INK = (42, 24, 8, 255)


def is_hair_pixel(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and 45 < r < 220 and g < 130 and b < 110 and r > g and r > b


def is_skin_pixel(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and r > 175 and g > 120 and b > 90


def _is_residual_cowboy_hair(r: int, g: int, b: int, a: int) -> bool:
    """Dark or muddy browns the main hair detector misses (sideburn ink, desat clumps)."""
    if a < 40:
        return False
    if is_hair_pixel(r, g, b, a):
        return True
    if 25 <= r <= 120 and g <= 85 and b <= 75 and r >= g and r >= b:
        return True
    if 50 <= r <= 180 and 50 <= g <= 120 and b <= 120 and r + g + b < 380:
        if abs(r - g) < 25 and b < min(r, g) + 30:
            return True
    return False


def _should_clear_player_cowboy_hair(px, x: int, y: int, w: int, h: int) -> bool:
    r, g, b, a = px[x, y][:4]
    if a < 40:
        return False
    if is_hat_brim_pixel(px, x, y, w, h):
        return False
    if is_skin_pixel(r, g, b, a):
        return False
    if y >= 17 and _is_residual_cowboy_hair(r, g, b, a):
        return True
    if is_head_hair_pixel(px, x, y, w, h):
        return True
    return False


def clear_cowboy_head_hair(img: Image.Image) -> None:
    """Erase every original cowboy head-hair pixel under the hat (keep hat brim)."""
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            if _should_clear_player_cowboy_hair(px, x, y, w, h):
                px[x, y] = (0, 0, 0, 0)


def clear_mounted_cowboy_head_hair(
    img: Image.Image,
    *,
    x0: int = 142,
    x1: int = 206,
    y0: int = 19,
    y1: int = 36,
) -> None:
    """Erase rider head hair on mounted frames (temples, sideburns, under-brim clumps)."""
    px = img.load()
    w, h = img.size
    for y in range(y0, min(y1, h)):
        for x in range(max(0, x0), min(x1, w)):
            r, g, b, a = px[x, y][:4]
            if a < 40 or is_skin_pixel(r, g, b, a):
                continue
            if _is_residual_cowboy_hair(r, g, b, a):
                px[x, y] = (0, 0, 0, 0)


def touch_up_player_head_hair(img: Image.Image) -> None:
    """Replace any leftover non-golden hair under the player hat."""
    px = img.load()
    w, h = img.size
    base, dark, _light, _ink = cowgirl_hair_palette()
    for y in range(17, min(h, 26)):
        for x in range(w):
            if is_hat_brim_pixel(px, x, y, w, h):
                continue
            r, g, b, a = px[x, y][:4]
            if a < 40 or is_skin_pixel(r, g, b, a):
                continue
            if not _is_residual_cowboy_hair(r, g, b, a):
                continue
            if is_cowgirl_hair_color(r, g, b):
                continue
            px[x, y] = dark if x < w // 2 - 5 or x > w // 2 + 4 else base


def is_cowgirl_hair_color(r: int, g: int, b: int) -> bool:
    base, dark, light, ink = cowgirl_hair_palette()
    rgb = (r, g, b)
    if rgb in {base[:3], dark[:3], light[:3], ink[:3]}:
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
    """Replace any leftover non-golden hair tones under the mounted hat."""
    px = img.load()
    w, h = img.size
    base, dark, light, ink = cowgirl_hair_palette()
    for y in range(y0, min(y1, h)):
        for x in range(max(0, x0), min(x1, w)):
            r, g, b, a = px[x, y][:4]
            if a < 40 or is_skin_pixel(r, g, b, a):
                continue
            if not _is_residual_cowboy_hair(r, g, b, a):
                continue
            if is_cowgirl_hair_color(r, g, b):
                continue
            px[x, y] = dark if x < (x0 + x1) // 2 - 4 or x > (x0 + x1) // 2 + 4 else base


def _row_hair_span(px, y: int, w: int) -> int:
    xs = [x for x in range(w) if is_hair_pixel(*px[x, y][:4])]
    if len(xs) < 2:
        return 0
    return max(xs) - min(xs)


def is_hat_brim_pixel(px, x: int, y: int, w: int, h: int) -> bool:
    if not is_hair_pixel(*px[x, y][:4]):
        return False
    if y >= 18:
        return False
    return _row_hair_span(px, y, w) > 20


def is_head_hair_pixel(px, x: int, y: int, w: int, h: int) -> bool:
    if not is_hair_pixel(*px[x, y][:4]):
        return False
    if is_hat_brim_pixel(px, x, y, w, h):
        return False
    if y >= 17:
        return True
    for dx, dy in [(-1, 0), (1, 0), (0, 1), (0, -1)]:
        nx, ny = x + dx, y + dy
        if 0 <= nx < w and 0 <= ny < h and is_skin_pixel(*px[nx, ny][:4]):
            return True
    return False


def _can_paint_head_hair(px, x: int, y: int, w: int, h: int) -> bool:
    if not (0 <= x < w and 0 <= y < h):
        return False
    r, g, b, a = px[x, y][:4]
    if a < 40:
        return True
    return is_head_hair_pixel(px, x, y, w, h)


def _avg(colors: list[tuple[int, int, int, int]]) -> tuple[int, int, int, int]:
    if not colors:
        return HAIR_BASE
    rs = [c[0] for c in colors]
    gs = [c[1] for c in colors]
    bs = [c[2] for c in colors]
    return (sum(rs) // len(rs), sum(gs) // len(gs), sum(bs) // len(bs), 255)


def shade(color: tuple[int, int, int, int], amount: float) -> tuple[int, int, int, int]:
    return (
        max(0, min(255, int(color[0] * amount))),
        max(0, min(255, int(color[1] * amount))),
        max(0, min(255, int(color[2] * amount))),
        color[3],
    )


def cowgirl_hair_palette() -> Palette:
    base = HAIR_BASE
    dark = HAIR_DARK
    light = HAIR_LIGHT
    ink = HAIR_INK
    return base, dark, light, ink


def sample_hair_palette(
    img: Image.Image,
    region: Callable[[int, int, int, int, int], bool] | None = None,
) -> Palette:
    px = img.load()
    w, h = img.size
    hair: list[tuple[int, int, int, int]] = []
    for y in range(h):
        for x in range(w):
            if region is not None and not region(x, y, w, h):
                continue
            r, g, b, a = px[x, y]
            if is_hair_pixel(r, g, b, a):
                hair.append((r, g, b, a))
    if not hair:
        return cowgirl_hair_palette()
    base = _avg(hair)
    # Blend sampled cowboy browns toward golden cowgirl tone.
    base = (
        (base[0] + HAIR_BASE[0]) // 2,
        (base[1] + HAIR_BASE[1]) // 2,
        (base[2] + HAIR_BASE[2]) // 2,
        255,
    )
    dark = shade(base, 0.72)
    light = shade(base, 1.14)
    ink = (max(0, base[0] // 4), max(0, base[1] // 4), max(0, min(28, base[2] // 5)), 255)
    return base, dark, light, ink


def sample_bandana(img: Image.Image) -> tuple[int, int, int, int]:
    px = img.load()
    w, h = img.size
    reds: list[tuple[int, int, int, int]] = []
    for y in range(12, min(h, 28)):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 40 and r > 150 and g < 90 and b < 90:
                reds.append((r, g, b, a))
    return _avg(reds) if reds else (208, 48, 38, 255)


def find_braid_anchors(img: Image.Image) -> tuple[tuple[int, int], tuple[int, int]]:
    """Temple/ear hairline under the hat — not the hat brim."""
    px = img.load()
    w, h = img.size
    center_x = w // 2
    left_pts: list[tuple[int, int]] = []
    right_pts: list[tuple[int, int]] = []
    for y in range(17, min(h, 22)):
        for x in range(w):
            if not is_head_hair_pixel(px, x, y, w, h):
                continue
            if x <= center_x - 10:
                left_pts.append((x, y))
            elif x >= center_x + 8:
                right_pts.append((x, y))
    if not left_pts or not right_pts:
        for y in range(16, min(h, 22)):
            for x in range(w):
                if not is_hair_pixel(*px[x, y][:4]):
                    continue
                if x <= center_x - 10:
                    left_pts.append((x, y))
                elif x >= center_x + 8:
                    right_pts.append((x, y))
    if not left_pts or not right_pts:
        return (20, 18), (w - 21, 18)

    left = max(left_pts, key=lambda p: (-abs(p[1] - 18), p[0]))
    scored: list[tuple[bool, int, int, int, int]] = []
    for x, y in right_pts:
        skin_near = any(
            0 <= x + dx < w and 0 <= y + dy < h and is_skin_pixel(*px[x + dx, y + dy][:4])
            for dx, dy in [(-1, 0), (1, 0), (0, 1), (0, -1)]
        )
        scored.append((skin_near, -abs(y - 18), -x, x, y))
    right = (max(scored)[3], max(scored)[4])
    return left, right


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
    left = max(left_pts, key=lambda p: (-abs(p[1] - 30), p[0]))
    right = min(right_pts, key=lambda p: (-abs(p[1] - 30), p[0]))
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
        x = int(u * u * start[0] + 2 * u * t * control[0] + t * t * end[0])
        y = int(u * u * start[1] + 2 * u * t * control[1] + t * t * end[1])
        points.append((x, y))
    return points


def _can_paint(
    px,
    x: int,
    y: int,
    w: int,
    h: int,
    allow_over: HairPredicate | None,
    *,
    head_only: bool = False,
) -> bool:
    if not (0 <= x < w and 0 <= y < h):
        return False
    r, g, b, a = px[x, y][:4]
    if a < 40:
        return True
    if head_only:
        return is_head_hair_pixel(px, x, y, w, h)
    if is_hair_pixel(r, g, b, a):
        return True
    return allow_over is not None and allow_over(r, g, b, a)


def _paint(
    px,
    x: int,
    y: int,
    w: int,
    h: int,
    color: tuple[int, int, int, int],
    allow_over: HairPredicate | None,
    *,
    head_only: bool = False,
) -> None:
    if _can_paint(px, x, y, w, h, allow_over, head_only=head_only):
        px[x, y] = color


def _blob_radius(t: float, scale: float) -> int:
    if t < 0.15:
        return max(2, int(round(2.6 * scale)))
    if t < 0.55:
        return max(2, int(round(2.1 * scale)))
    if t < 0.82:
        return max(1, int(round(1.6 * scale)))
    return max(1, int(round(1.1 * scale)))


def _strand_color(side: str, dx: int, dy: int, radius: int, base, dark, light, ink) -> tuple[int, int, int, int]:
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


def draw_wavy_pigtail(
    img: Image.Image,
    start: tuple[int, int],
    control: tuple[int, int],
    end: tuple[int, int],
    side: str,
    palette: Palette,
    *,
    scale: float = 1.0,
    head_only: bool = False,
    wave: float = 1.4,
    phase: float = 0.0,
) -> None:
    """Thick wavy pigtail with a secondary strand for fuller flow."""
    px = img.load()
    w, h = img.size
    base, dark, light, ink = palette
    steps = max(16, int(18 * scale))
    points = _bezier2(start, control, end, steps)
    total = max(1, len(points) - 1)
    strand_offsets = (0, 1 if side == "left" else -1)
    for strand_shift in strand_offsets:
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
                    if strand_shift and abs(dx) + abs(dy) > radius:
                        color = light if color == base else color
                    _paint(px, sx + dx, sy + dy, w, h, color, None, head_only=head_only)


def draw_bangs(img: Image.Image, palette: Palette) -> None:
    """Forehead fringe visible under hat brim (reference cue)."""
    px = img.load()
    w, h = img.size
    base, dark, light, ink = palette
    cx = w // 2
    for y in range(15, 20):
        for x in range(cx - 10, cx + 11):
            if not (0 <= x < w):
                continue
            r, g, b, a = px[x, y][:4]
            if a > 40 and not is_skin_pixel(r, g, b, a) and not is_hat_brim_pixel(px, x, y, w, h):
                continue
            t = abs(x - cx) / 10.0
            color = ink if t > 0.85 else light if y <= 16 else base if t < 0.35 else dark
            px[x, y] = color


def draw_temple_volume(img: Image.Image, left: tuple[int, int], right: tuple[int, int], palette: Palette) -> None:
    """Side hair puff under hat before pigtail drop."""
    px = img.load()
    w, h = img.size
    base, dark, light, _ink = palette
    for anchor, side in ((left, "left"), (right, "right")):
        x, y = anchor
        offsets = [
            (-2, -1), (-1, -1), (0, -1), (1, -1), (2, -1),
            (-2, 0), (-1, 0), (0, 0), (1, 0), (2, 0),
            (-2, 1), (-1, 1), (0, 1), (1, 1), (2, 1),
            (-1, 2), (0, 2), (1, 2),
        ]
        if side == "right":
            offsets = [(ox, oy) for ox, oy in offsets]
        for i, (ox, oy) in enumerate(offsets):
            px_x, px_y = x + ox, y + oy
            if not (0 <= px_x < w and 0 <= px_y < h):
                continue
            r, g, b, a = px[px_x, px_y][:4]
            if a > 40 and is_skin_pixel(r, g, b, a):
                continue
            if a > 40 and not is_hat_brim_pixel(px, px_x, px_y, w, h):
                continue
            px[px_x, px_y] = light if i < 4 else base if i < 10 else dark


def draw_mounted_head_fill(
    img: Image.Image,
    left: tuple[int, int],
    right: tuple[int, int],
    palette: Palette,
) -> None:
    """Golden under-hat volume on mounted rider between pigtail roots."""
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
            color = ink if t > 0.9 else light if y <= y0 + 1 else base if t < 0.4 else dark
            px[x, y] = color


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
    dark = shade(ribbon, 0.82)
    light = shade(ribbon, 1.08)
    offsets: list[tuple[int, int, tuple[int, int, int, int]]]
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


def pigtail_controls(
    left: tuple[int, int],
    right: tuple[int, int],
    swing: float,
    *,
    scale: float = 1.0,
) -> tuple[tuple[tuple[int, int], tuple[int, int], tuple[int, int]], tuple[tuple[int, int], tuple[int, int], tuple[int, int]]]:
    lx, ly = left
    rx, ry = right
    reach = max(1, int(round(2 * scale)))
    drop_mid = max(4, int(round(9 * scale)))
    drop_end = max(8, int(round(22 * scale)))
    sway = int(round(swing))
    lift = int(round(abs(swing) * 0.4))
    left_path = (
        left,
        (lx - reach + sway, ly + drop_mid - lift),
        (lx - 3 + sway * 2, ly + drop_end),
    )
    right_path = (
        right,
        (rx + reach + sway, ry + drop_mid - lift),
        (rx + 3 + sway * 2, ry + drop_end),
    )
    return left_path, right_path


def _wave_for_swing(swing: float) -> tuple[float, float]:
    magnitude = min(3.0, 1.6 + abs(swing) * 0.35)
    phase = swing * 0.45
    return magnitude, phase


def draw_player_cowgirl_hair(img: Image.Image, swing: float = 0.0) -> None:
    palette = cowgirl_hair_palette()
    ribbon = sample_bandana(img)
    left, right = find_braid_anchors(img)
    clear_cowboy_head_hair(img)
    wave, phase = _wave_for_swing(swing)
    draw_bangs(img, palette)
    draw_temple_volume(img, left, right, palette)
    left_path, right_path = pigtail_controls(left, right, swing, scale=1.0)
    draw_wavy_pigtail(
        img, *left_path, "left", palette, scale=1.1, head_only=True, wave=wave, phase=phase,
    )
    draw_wavy_pigtail(
        img, *right_path, "right", palette, scale=1.1, head_only=True, wave=wave, phase=-phase,
    )
    draw_ribbon_knot(img, left, ribbon, "left", scale=1.0)
    draw_ribbon_knot(img, right, ribbon, "right", scale=1.0)
    touch_up_player_head_hair(img)


def _mounted_swing_for_frame(name: str) -> float:
    if "jump" in name:
        return -2.5
    if "ride_1" in name:
        return 1.2
    return 0.0


def draw_mounted_cowgirl_hair(img: Image.Image, frame_name: str = "") -> None:
    palette = cowgirl_hair_palette()
    ribbon = sample_bandana(img)
    swing = _mounted_swing_for_frame(frame_name)
    wave, phase = _wave_for_swing(swing)
    wave = max(wave, 2.4)
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
        scale=1.85, head_only=True, wave=wave, phase=phase,
    )
    draw_wavy_pigtail(
        img, right_start, right_ctrl, right_end, "right", palette,
        scale=1.85, head_only=True, wave=wave, phase=-phase,
    )
    draw_ribbon_knot(img, left_start, ribbon, "left", scale=1.55)
    draw_ribbon_knot(img, right_start, ribbon, "right", scale=1.55)
    touch_up_mounted_head_hair(img)


# Backward-compatible aliases
draw_hanging_braid = draw_wavy_pigtail
braid_controls = pigtail_controls
draw_player_braids = draw_player_cowgirl_hair
