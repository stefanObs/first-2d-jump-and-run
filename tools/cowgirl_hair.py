"""Shared pixel-braid hair drawing for cowgirl player and horse sprites."""

from __future__ import annotations

from typing import Callable

from PIL import Image

HairPredicate = Callable[[int, int, int, int], bool]
Palette = tuple[tuple[int, int, int, int], tuple[int, int, int, int], tuple[int, int, int, int], tuple[int, int, int, int]]


def is_hair_pixel(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and 45 < r < 180 and g < 110 and b < 95 and r > g and r > b


def is_skin_pixel(r: int, g: int, b: int, a: int) -> bool:
    return a > 40 and r > 175 and g > 120 and b > 90


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
        return (126, 66, 13, 255)
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
    base = _avg(hair)
    dark = shade(base, 0.78)
    light = shade(base, 1.12)
    ink = (max(0, base[0] // 3), max(0, base[1] // 3), max(0, min(24, base[2] // 4)), 255)
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

    def _pick_left(points: list[tuple[int, int]]) -> tuple[int, int]:
        return max(points, key=lambda p: (-abs(p[1] - 18), p[0]))

    def _pick_right(points: list[tuple[int, int]]) -> tuple[int, int]:
        scored: list[tuple[bool, int, int, int, int]] = []
        for x, y in points:
            skin_near = any(
                0 <= x + dx < w and 0 <= y + dy < h and is_skin_pixel(*px[x + dx, y + dy][:4])
                for dx, dy in [(-1, 0), (1, 0), (0, 1), (0, -1)]
            )
            scored.append((skin_near, -abs(y - 18), -x, x, y))
        best = max(scored)
        return (best[3], best[4])

    return _pick_left(left_pts), _pick_right(right_pts)


def find_mounted_braid_anchors(
    img: Image.Image,
    *,
    x0: int = 145,
    x1: int = 210,
    y0: int = 27,
    y1: int = 33,
) -> tuple[tuple[int, int], tuple[int, int], tuple[int, int], tuple[int, int], tuple[int, int], tuple[int, int]]:
    """Return left/right braid paths (start, control, end) for mounted rider."""
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
        fallback_y = 30
        return (
            (154, fallback_y),
            (146, fallback_y + 20),
            (140, fallback_y + 47),
            (192, fallback_y),
            (200, fallback_y + 20),
            (206, fallback_y + 47),
        )
    left = max(left_pts, key=lambda p: (-abs(p[1] - 30), p[0]))
    right = min(right_pts, key=lambda p: (-abs(p[1] - 30), p[0]))
    lx, ly = left
    rx, ry = right
    return (
        left,
        (lx - 8, ly + 20),
        (lx - 14, ly + 47),
        right,
        (rx + 8, ry + 20),
        (rx + 14, ry + 47),
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
    if t < 0.2:
        return max(1, int(round(2.2 * scale)))
    if t < 0.58:
        return max(1, int(round(1.7 * scale)))
    if t < 0.85:
        return max(1, int(round(1.2 * scale)))
    return 1


def _braid_color(side: str, dx: int, dy: int, radius: int, base, dark, light, ink) -> tuple[int, int, int, int]:
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


def draw_hanging_braid(
    img: Image.Image,
    start: tuple[int, int],
    control: tuple[int, int],
    end: tuple[int, int],
    side: str,
    palette: Palette,
    *,
    scale: float = 1.0,
    allow_over: HairPredicate | None = None,
    head_only: bool = False,
) -> None:
    px = img.load()
    w, h = img.size
    base, dark, light, ink = palette
    points = _bezier2(start, control, end, max(10, int(12 * scale)))
    total = max(1, len(points) - 1)
    for i, (cx, cy) in enumerate(points):
        t = i / total
        radius = _blob_radius(t, scale)
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if abs(dx) + abs(dy) > radius + 1:
                    continue
                color = _braid_color(side, dx, dy, radius, base, dark, light, ink)
                _paint(px, cx + dx, cy + dy, w, h, color, allow_over, head_only=head_only)


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
        offsets = [
            (0, 0, ribbon),
            (-1, 0, dark),
            (0, 1, dark),
            (-1, 1, light),
        ]
    else:
        offsets = [
            (0, 0, ribbon),
            (1, 0, dark),
            (0, 1, dark),
            (1, 1, light),
        ]
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


def braid_controls(
    left: tuple[int, int],
    right: tuple[int, int],
    swing: float,
    *,
    scale: float = 1.0,
) -> tuple[tuple[tuple[int, int], tuple[int, int], tuple[int, int]], tuple[tuple[int, int], tuple[int, int], tuple[int, int]]]:
    lx, ly = left
    rx, ry = right
    reach = max(1, int(round(2 * scale)))
    drop_mid = max(2, int(round(6 * scale)))
    drop_end = max(4, int(round(12 * scale)))
    sway = int(round(swing))
    left_path = (
        left,
        (lx - reach + sway, ly + drop_mid),
        (lx - 1 + sway, ly + drop_end),
    )
    right_path = (
        right,
        (rx + reach + sway, ry + drop_mid),
        (rx + 1 + sway, ry + drop_end),
    )
    return left_path, right_path


def _blend_braid_roots(img: Image.Image, left: tuple[int, int], right: tuple[int, int], palette: Palette) -> None:
    px = img.load()
    w, h = img.size
    base, dark, _light, ink = palette
    for anchor, side in ((left, "left"), (right, "right")):
        x, y = anchor
        offsets = [(-1, 0), (0, 0), (1, 0), (0, 1)] if side == "left" else [(1, 0), (0, 0), (-1, 0), (0, 1)]
        for i, (ox, oy) in enumerate(offsets):
            px_x, px_y = x + ox, y + oy
            if 0 <= px_x < w and 0 <= px_y < h and _can_paint_head_hair(px, px_x, px_y, w, h):
                px[px_x, px_y] = ink if i == 0 else base if i == 1 else dark


def draw_player_braids(img: Image.Image, swing: float = 0.0) -> None:
    px = img.load()
    w, h = img.size
    palette = sample_hair_palette(
        img,
        region=lambda x, y, _w, _h: 16 <= y < 24 and is_head_hair_pixel(px, x, y, _w, _h),
    )
    ribbon = sample_bandana(img)
    left, right = find_braid_anchors(img)
    _blend_braid_roots(img, left, right, palette)
    left_path, right_path = braid_controls(left, right, swing, scale=1.0)
    draw_hanging_braid(img, *left_path, "left", palette, scale=1.0, head_only=True)
    draw_hanging_braid(img, *right_path, "right", palette, scale=1.0, head_only=True)
    draw_ribbon_knot(img, left, ribbon, "left", scale=1.0)
    draw_ribbon_knot(img, right, ribbon, "right", scale=1.0)
