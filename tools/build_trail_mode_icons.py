#!/usr/bin/env python3
"""Build western trail-mode icons for the start-screen hearts switch.

Star sits in the disc center; hearts form a low crown / side accents that
stay inside the wooden plate rim.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "ui"
HEART = Image.open(OUT / "menu_icon_heart.png").convert("RGBA")
STAR = Image.open(ROOT / "assets" / "world" / "star_badge.png").convert("RGBA")
SIZE = 96
CX = SIZE // 2
CY = SIZE // 2
SAFE_RADIUS = 33


def _paste(dst: Image.Image, src: Image.Image, xy: tuple[float, float]) -> None:
    layer = Image.new("RGBA", dst.size, (0, 0, 0, 0))
    layer.paste(src, (int(round(xy[0])), int(round(xy[1]))), src)
    dst.alpha_composite(layer)


def _draw_number(draw: ImageDraw.ImageDraw, text: str, cx: int, cy: int, size: int) -> None:
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
    except OSError:
        font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = int(cx - tw * 0.5 - bbox[0])
    y = int(cy - th * 0.5 - bbox[1])
    for ox, oy in ((-2, 0), (2, 0), (0, -2), (0, 2), (-1, -1), (1, 1), (1, -1), (-1, 1)):
        draw.text((x + ox, y + oy), text, font=font, fill=(62, 22, 6, 255))
    draw.text((x, y), text, font=font, fill=(255, 242, 186, 255))


def _heart_chip(scale: float) -> Image.Image:
    return HEART.resize(
        (max(1, int(HEART.width * scale)), max(1, int(HEART.height * scale))),
        Image.Resampling.LANCZOS,
    )


def _circular_mask(radius: int = SAFE_RADIUS) -> Image.Image:
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).ellipse(
        (CX - radius, CY - radius, CX + radius, CY + radius),
        fill=255,
    )
    return mask


def _apply_circle_clip(img: Image.Image) -> Image.Image:
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0))
    src_a = img.split()[-1]
    combined = ImageChops.multiply(src_a, _circular_mask())
    r, g, b, _ = out.split()
    return Image.merge("RGBA", (r, g, b, combined))


def _paste_hearts_around_star(canvas: Image.Image, count: int, star_cy: float) -> None:
    """Hearts on a ring around the star — uses the wide middle of the disc."""
    if count >= 5:
        # Five hearts: shallow crown above the star, clear of the rim.
        scale = 0.132
        heart = _heart_chip(scale)
        hw, hh = heart.size
        # Degrees from upward axis; keep outer hearts inside SAFE_RADIUS.
        angles = (-48.0, -24.0, 0.0, 24.0, 48.0)
        radius = 22.0
        origin_y = star_cy + 1.0
    elif count == 3:
        scale = 0.145
        heart = _heart_chip(scale)
        hw, hh = heart.size
        angles = (-34.0, 0.0, 34.0)
        radius = 21.5
        origin_y = star_cy + 0.5
    else:
        heart = _heart_chip(0.2)
        _paste(canvas, heart, (CX - heart.width * 0.5, star_cy - 28))
        return

    for deg in angles:
        rad = math.radians(deg)
        x = CX + radius * math.sin(rad) - hw * 0.5
        y = origin_y - radius * math.cos(rad) - hh * 0.5
        _paste(canvas, heart, (x, y))


def build_classic() -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    heart = _heart_chip(0.34)
    _paste(img, heart, ((SIZE - heart.width) // 2, (SIZE - heart.height) // 2 - 1))
    r, g, b, a = img.split()
    a = a.point(lambda v: int(v * 0.55))
    return _apply_circle_clip(Image.merge("RGBA", (r, g, b, a)))


def build_advanced(badges: int, hearts: int) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

    star = STAR.resize((38, 38), Image.Resampling.LANCZOS)
    star_x = (SIZE - star.width) // 2
    # Drop the star so hearts-above + star balance in the disc (not top-heavy).
    star_y = CY - star.height // 2 + 10
    star_cy = star_y + star.height * 0.5

    _paste_hearts_around_star(img, hearts, star_cy)

    shadow = star.split()[-1].point(lambda a: int(a * 0.4))
    sh = Image.new("RGBA", star.size, (48, 22, 8, 255))
    sh.putalpha(shadow)
    _paste(img, sh, (star_x + 2, star_y + 3))
    _paste(img, star, (star_x, star_y))

    draw = ImageDraw.Draw(img)
    _draw_number(draw, str(badges), CX, int(star_cy) + 1, 16 if badges < 10 else 13)

    glow = img.filter(ImageFilter.GaussianBlur(0.35))
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.alpha_composite(glow)
    out.alpha_composite(img)
    return _apply_circle_clip(out)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    build_classic().save(OUT / "menu_trail_mode_classic.png")
    for badges, hearts in ((5, 5), (10, 5), (15, 3), (30, 3)):
        build_advanced(badges, hearts).save(OUT / f"menu_trail_mode_{badges}.png")
    print("Wrote trail mode icons to", OUT)


if __name__ == "__main__":
    main()
