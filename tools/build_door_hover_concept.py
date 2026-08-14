#!/usr/bin/env python3
"""Concept art: save doors ajar on hover, peeking desert/cave instead of red ring."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "showcase" / "menu_door_hover_ajar_concept.png"


def _font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    for base in (
        "/usr/share/fonts/truetype/dejavu/",
        "/usr/share/fonts/truetype/liberation/",
    ):
        path = Path(base) / name.replace("DejaVuSans", "LiberationSans")
        if not path.is_file():
            path = Path(base) / name
        if path.is_file():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def _split_door(door: Image.Image) -> tuple[Image.Image, Image.Image]:
    """Return (stone_frame_without_leaf, wood_leaf)."""
    w, h = door.size
    pix = door.load()
    wood = Image.new("L", (w, h), 0)
    wp = wood.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = pix[x, y]
            if a < 20:
                continue
            # Pale porthole glass rides with the leaf.
            if r > 200 and g > 170 and b > 130 and abs(r - g) < 50:
                wp[x, y] = 255
                continue
            if r > 70 and r > g + 15 and r > b + 25 and g > 35 and b < 120:
                wp[x, y] = 255
    wood = wood.filter(ImageFilter.MaxFilter(3))
    leaf_mask = Image.new("L", (w, h), 0)
    ld = ImageDraw.Draw(leaf_mask)
    ld.pieslice((38, 48, w - 38, h * 2 - 80), 180, 360, fill=255)
    ld.rectangle((38, h // 2 - 20, w - 38, h - 55), fill=255)
    wood_leaf = ImageChops.multiply(wood, leaf_mask)

    leaf = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    stone_frame = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    lp, sfp = leaf.load(), stone_frame.load()
    wl = wood_leaf.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = pix[x, y]
            if a < 20:
                continue
            if wl[x, y] > 80:
                lp[x, y] = (r, g, b, a)
                continue
            sfp[x, y] = (r, g, b, a)
    return stone_frame, leaf.filter(ImageFilter.GaussianBlur(0.35))


def _crop_peek(src: Image.Image, kind: str, size: tuple[int, int]) -> Image.Image:
    h = min(720, src.height)
    base = src.crop((0, 0, src.width, h))
    if kind == "desert":
        box = (420, 180, 900, 560)
    else:
        box = (380, 140, 900, 560)
    return base.crop(box).resize(size, Image.Resampling.LANCZOS)


def _ring_overlay(ring: Image.Image, door_w: int, door_h: int) -> Image.Image:
    scaled = ring.resize((door_w + 36, door_h + 36), Image.Resampling.LANCZOS)
    out = []
    for r, g, b, a in scaled.getdata():
        if r < 40 and g < 40 and b < 40:
            out.append((r, g, b, 0))
        else:
            out.append((r, g, b, a))
    scaled.putdata(out)
    return scaled


def _make_ajar(
    stone_frame: Image.Image,
    leaf: Image.Image,
    peek: Image.Image,
    *,
    open_deg: float = 30.0,
) -> Image.Image:
    """Left-hinged wood leaf, ajar at a normal open angle; peek on the free (right) side."""
    w, h = stone_frame.size
    canvas = Image.new("RGBA", (w + 40, h + 16), (0, 0, 0, 0))
    origin = (16, 8)

    # True door swing around the LEFT hinge (knob = free right edge).
    # Open slightly toward the viewer so the free edge reads as a normal ajar door.
    hinge_x = 38.0
    top_y, bot_y = 48.0, 375.0
    right_x = 242.0
    theta = math.radians(open_deg)
    cos_t = math.cos(theta)
    sin_t = math.sin(theta)
    leaf_w = right_x - hinge_x
    new_right = hinge_x + leaf_w * cos_t
    # Free edge nearer the camera → mild vertical grow (outward swing).
    grow = 1.0 + 0.06 * sin_t
    mid = (top_y + bot_y) * 0.5
    half = (bot_y - top_y) * 0.5
    new_top = mid - half * grow
    new_bot = mid + half * grow

    # Dark room + peek only in the revealed right gap (not under the leaf).
    interior = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    idr = ImageDraw.Draw(interior)
    idr.pieslice((40, 52, w - 40, h * 2 - 90), 180, 360, fill=(18, 10, 6, 255))
    idr.rectangle((40, h // 2 - 10, w - 40, h - 58), fill=(18, 10, 6, 255))

    arch = Image.new("L", (w, h), 0)
    ad = ImageDraw.Draw(arch)
    ad.pieslice((44, 56, w - 44, h * 2 - 95), 180, 360, fill=255)
    ad.rectangle((44, h // 2 - 5, w - 44, h - 62), fill=255)
    gap_mask = Image.new("L", (w, h), 0)
    gd = ImageDraw.Draw(gap_mask)
    gap_x0 = int(new_right) + 1
    gd.rectangle((gap_x0, 52, w - 44, h - 58), fill=255)
    gap_mask = ImageChops.multiply(gap_mask, arch)

    peek_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    peek_rgba = peek.convert("RGBA")
    ox = (w - peek.width) // 2
    oy = 70
    peek_layer.paste(peek_rgba, (ox, oy))
    peek_layer.putalpha(ImageChops.multiply(peek_layer.split()[-1], gap_mask))

    warm = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    wd = ImageDraw.Draw(warm)
    wd.rectangle((gap_x0, 56, w - 44, h - 62), fill=(255, 214, 150, 40))
    warm.putalpha(ImageChops.multiply(warm.split()[-1], gap_mask))

    canvas.paste(interior, origin, interior)
    canvas.paste(peek_layer, origin, peek_layer)
    canvas.paste(warm, origin, warm)

    closed = [
        (hinge_x, top_y),
        (right_x, top_y),
        (right_x, bot_y),
        (hinge_x, bot_y),
    ]
    ajar = [
        (hinge_x, top_y),
        (new_right, new_top),
        (new_right, new_bot),
        (hinge_x, bot_y),
    ]
    matrix = _perspective_coeffs(ajar, closed)
    swung = leaf.transform(
        (w, h),
        Image.Transform.PERSPECTIVE,
        matrix,
        resample=Image.Resampling.BICUBIC,
    )

    # Free-edge thickness (door opening toward camera).
    edge = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ed = ImageDraw.Draw(edge)
    thickness = max(4, int(10 * sin_t))
    ed.line(
        [(new_right + thickness * 0.35, new_top), (new_right + thickness * 0.35, new_bot)],
        fill=(55, 30, 14, 220),
        width=thickness,
    )
    ed.line(
        [(new_right + 1, new_top), (new_right + 1, new_bot)],
        fill=(30, 16, 8, 180),
        width=2,
    )

    shadow_a = swung.split()[-1].point(lambda a: int(a * 0.28))
    shadow_a = shadow_a.filter(ImageFilter.GaussianBlur(5))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow.putalpha(shadow_a)
    canvas.paste(shadow, (origin[0] + 4, origin[1] + 6), shadow)
    canvas.paste(swung, origin, swung)
    canvas.paste(edge, origin, edge)
    canvas.paste(stone_frame, origin, stone_frame)
    return canvas


def _perspective_coeffs(
    output_xy: list[tuple[float, float]],
    input_uv: list[tuple[float, float]],
) -> list[float]:
    """PIL PERSPECTIVE coeffs mapping output (x,y) -> input (u,v). Pure Python."""
    # Rows: a0..a7 for each of 4 point pairs (2 eqs each).
    a: list[list[float]] = []
    for (x, y), (u, v) in zip(output_xy, input_uv):
        a.append([x, y, 1.0, 0.0, 0.0, 0.0, -u * x, -u * y, u])
        a.append([0.0, 0.0, 0.0, x, y, 1.0, -v * x, -v * y, v])
    # Gaussian elimination with partial pivoting.
    n = 8
    for col in range(n):
        pivot = max(range(col, n), key=lambda r: abs(a[r][col]))
        if abs(a[pivot][col]) < 1e-12:
            raise ValueError("singular perspective system")
        a[col], a[pivot] = a[pivot], a[col]
        div = a[col][col]
        for j in range(col, n + 1):
            a[col][j] /= div
        for r in range(n):
            if r == col:
                continue
            factor = a[r][col]
            for j in range(col, n + 1):
                a[r][j] -= factor * a[col][j]
    return [a[i][n] for i in range(n)]

def _make_closed_with_ring(door: Image.Image, ring: Image.Image) -> Image.Image:
    w, h = door.size
    canvas = Image.new("RGBA", (w + 30, h + 10), (0, 0, 0, 0))
    canvas.paste(door, (15, 5), door)
    overlay = _ring_overlay(ring, w, h)
    canvas.paste(overlay, (0, -5), overlay)
    return canvas


def main() -> int:
    door = Image.open(ROOT / "assets/ui/menu_save_door.png").convert("RGBA")
    ring = Image.open(ROOT / "assets/ui/menu_door_select_ring.png").convert("RGBA")
    desert = Image.open(ROOT / "docs/showcase/desert_trail.png").convert("RGB")
    cave = Image.open(ROOT / "docs/showcase/cave_trail.png").convert("RGB")
    backdrop = Image.open(ROOT / "docs/showcase/main_menu_current_composite.png").convert("RGB")

    stone_frame, leaf = _split_door(door)
    w, h = door.size
    desert_peek = _crop_peek(desert, "desert", (w - 70, h - 100))
    cave_peek = _crop_peek(cave, "cave", (w - 70, h - 100))

    closed_ring = _make_closed_with_ring(door, ring)
    ajar_desert = _make_ajar(stone_frame, leaf, desert_peek)
    ajar_cave = _make_ajar(stone_frame, leaf, cave_peek)

    bg = backdrop.resize((1400, 788), Image.Resampling.LANCZOS)
    bg = ImageEnhance.Brightness(bg).enhance(0.55)
    bg = ImageEnhance.Color(bg).enhance(0.85)
    board = bg.convert("RGBA")
    overlay = Image.new("RGBA", board.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rounded_rectangle((40, 24, 1360, 110), radius=16, fill=(62, 34, 16, 220))
    board = Image.alpha_composite(board, overlay)

    draw = ImageDraw.Draw(board)
    font_title = _font(34, bold=True)
    font_sub = _font(18)
    font_cap = _font(20, bold=True)
    draw.text(
        (70, 40),
        "Door hover concept — ajar peek (no red ring)",
        fill=(255, 236, 196),
        font=font_title,
    )
    draw.text(
        (70, 78),
        "Left-hinged wood leaf opens ~30° on hover; desert / cave trail peeks through the free (right) edge.",
        fill=(230, 190, 140),
        font=font_sub,
    )

    cards = [
        (closed_ring, "Today", "Bandana-red focus ring"),
        (ajar_desert, "Hover · Desert save", "Door ajar → dusty trail peek"),
        (ajar_cave, "Hover · Cave save", "Door ajar → crystal cave peek"),
    ]
    slot_w, slot_h = 360, 520
    start_x = 70
    y0 = 150
    gap = 40
    for i, (img, title, subtitle) in enumerate(cards):
        x = start_x + i * (slot_w + gap)
        plate = Image.new("RGBA", (slot_w, slot_h), (0, 0, 0, 0))
        pd = ImageDraw.Draw(plate)
        pd.rounded_rectangle(
            (0, 0, slot_w - 1, slot_h - 1),
            radius=18,
            fill=(78, 46, 24, 230),
            outline=(160, 100, 50),
            width=3,
        )
        board.paste(plate, (x, y0), plate)
        scale = min((slot_w - 40) / img.width, (slot_h - 110) / img.height)
        dw, dh = int(img.width * scale), int(img.height * scale)
        fitted = img.resize((dw, dh), Image.Resampling.LANCZOS)
        px = x + (slot_w - dw) // 2
        py = y0 + 28
        board.paste(fitted, (px, py), fitted)
        draw.text((x + 24, y0 + slot_h - 70), title, fill=(255, 236, 196), font=font_cap)
        draw.text((x + 24, y0 + slot_h - 42), subtitle, fill=(230, 190, 140), font=font_sub)

    draw.rounded_rectangle((40, 700, 1360, 760), radius=12, fill=(42, 24, 12, 210))
    draw.text(
        (70, 718),
        "Concept only — hinges on the left (knob on the right). Red ring replaced by a normal ajar opening.",
        fill=(255, 220, 170),
        font=font_sub,
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    board.convert("RGB").save(OUT, optimize=True, quality=92)
    print(f"wrote {OUT.relative_to(ROOT)} ({OUT.stat().st_size // 1024} KiB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
