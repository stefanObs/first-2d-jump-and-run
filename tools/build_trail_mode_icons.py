#!/usr/bin/env python3
"""Build western trail-mode icons for the start-screen hearts switch."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "ui"
HEART = Image.open(OUT / "menu_icon_heart.png").convert("RGBA")
STAR = Image.open(ROOT / "assets" / "world" / "star_badge.png").convert("RGBA")


def _paste(dst: Image.Image, src: Image.Image, xy: tuple[int, int], scale: float = 1.0) -> None:
    if scale != 1.0:
        w = max(1, int(src.width * scale))
        h = max(1, int(src.height * scale))
        src = src.resize((w, h), Image.Resampling.LANCZOS)
    layer = Image.new("RGBA", dst.size, (0, 0, 0, 0))
    layer.paste(src, (int(xy[0]), int(xy[1])), src)
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
    heart = HEART.resize(
        (max(1, int(HEART.width * scale)), max(1, int(HEART.height * scale))),
        Image.Resampling.LANCZOS,
    )
    return heart


def _hearts_row(canvas: Image.Image, count: int, y: int, scale: float) -> None:
    heart = _heart_chip(scale)
    gap = 1 if count >= 5 else 3
    total = count * heart.width + (count - 1) * gap
    x0 = (canvas.width - total) // 2
    for i in range(count):
        _paste(canvas, heart, (x0 + i * (heart.width + gap), y))


def _parchment() -> Image.Image:
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((4, 4, 92, 92), fill=(255, 214, 140, 70), outline=(120, 62, 22, 90), width=2)
    return img


def build_classic() -> Image.Image:
    img = _parchment()
    heart = _heart_chip(0.52)
    _paste(img, heart, ((96 - heart.width) // 2, 22))
    # Quiet Classic look — dim the single heart.
    r, g, b, a = img.split()
    a = a.point(lambda v: int(v * 0.55))
    img = Image.merge("RGBA", (r, g, b, a))
    return img


def build_advanced(badges: int, hearts: int) -> Image.Image:
    img = _parchment()
    heart_scale = 0.22 if hearts >= 5 else 0.30
    _hearts_row(img, hearts, 8 if hearts >= 5 else 12, heart_scale)

    star = STAR.resize((50, 50), Image.Resampling.LANCZOS)
    shadow = star.split()[-1].point(lambda a: int(a * 0.4))
    sh = Image.new("RGBA", star.size, (48, 22, 8, 255))
    sh.putalpha(shadow)
    _paste(img, sh, (25, 42))
    _paste(img, star, (23, 38))

    draw = ImageDraw.Draw(img)
    _draw_number(draw, str(badges), 48, 62, 20 if badges < 10 else 17)

    glow = img.filter(ImageFilter.GaussianBlur(0.5))
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.alpha_composite(glow)
    out.alpha_composite(img)
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    build_classic().save(OUT / "menu_trail_mode_classic.png")
    for badges, hearts in ((5, 5), (10, 5), (15, 3), (30, 3)):
        build_advanced(badges, hearts).save(OUT / f"menu_trail_mode_{badges}.png")
    print("Wrote trail mode icons to", OUT)


if __name__ == "__main__":
    main()
