#!/usr/bin/env python3
"""Compose README showcase stills and GIFs from real in-game art."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "showcase"


def load(rel: str) -> Image.Image:
    path = ROOT / rel
    if not path.is_file():
        raise FileNotFoundError(path)
    return Image.open(path).convert("RGBA")


def font(size: int) -> ImageFont.ImageFont:
    for candidate in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
    ):
        if Path(candidate).is_file():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def paste(base: Image.Image, sprite: Image.Image, xy: tuple[int, int], scale: float = 1.0) -> None:
    if abs(scale - 1.0) > 0.001:
        w = max(1, int(round(sprite.width * scale)))
        h = max(1, int(round(sprite.height * scale)))
        sprite = sprite.resize((w, h), Image.Resampling.LANCZOS)
    x, y = xy
    base.alpha_composite(sprite, (int(x), int(y)))


def tile_x(base: Image.Image, tile: Image.Image, y: int, x0: int, x1: int) -> None:
    x = x0
    while x < x1:
        paste(base, tile, (x, y))
        x += tile.width - 8


def caption_bar(img: Image.Image, title: str, subtitle: str) -> Image.Image:
    bar_h = 54
    out = Image.new("RGBA", (img.width, img.height + bar_h), (42, 24, 12, 255))
    out.alpha_composite(img, (0, 0))
    draw = ImageDraw.Draw(out)
    draw.rectangle((0, img.height, img.width, img.height + bar_h), fill=(72, 42, 22, 255))
    draw.text((18, img.height + 8), title, fill=(255, 236, 196, 255), font=font(22))
    draw.text((18, img.height + 32), subtitle, fill=(230, 190, 140, 255), font=font(14))
    return out.convert("RGB")


def build_desert_trail() -> Image.Image:
    w, h = 960, 420
    canvas = Image.new("RGBA", (w, h), (148, 209, 245, 255))
    sky = load("assets/world/sky_handdrawn.png")
    sky = sky.resize((w, int(h * 0.72)), Image.Resampling.LANCZOS)
    paste(canvas, sky, (0, -40))

    mesa = load("assets/world/mesa.png")
    paste(canvas, mesa, (40, 150), 1.35)
    paste(canvas, mesa, (520, 165), 1.1)

    floor = load("assets/world/trail_desert_tile.png")
    dirt = load("assets/world/trail_dirt_tile.png")
    floor_y = 300
    tile_x(canvas, floor, floor_y, -20, w + 40)
    tile_x(canvas, dirt, floor_y + floor.height - 10, -20, w + 40)

    # Open canyon mouth with left rim + flipped right rim.
    rim = load("assets/world/canyon_rim_left.png")
    rim_h = 220
    rim_scale = rim_h / rim.height
    rim_w = int(rim.width * rim_scale)
    left = rim.resize((rim_w, rim_h), Image.Resampling.LANCZOS)
    right = left.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    gap_x = 430
    paste(canvas, left, (gap_x - rim_w + 18, floor_y + 24 - rim_h))
    paste(canvas, right, (gap_x + 110, floor_y + 24 - rim_h))

    paste(canvas, load("assets/world/cloud.png"), (gap_x + 20, 210), 0.7)
    paste(canvas, load("assets/world/cactus.png"), (70, floor_y - 70), 1.15)
    paste(canvas, load("assets/world/star_badge.png"), (250, 160), 1.4)
    paste(canvas, load("assets/world/modes/wings.png"), (300, 145), 1.1)
    paste(canvas, load("assets/world/bandit.png"), (620, floor_y - 58), 1.35)
    paste(canvas, load("assets/world/treasure_chest_closed.png"), (700, floor_y - 52), 0.85)
    paste(canvas, load("assets/world/goal_saloon.png"), (820, floor_y - 118), 0.95)
    paste(canvas, load("assets/player/run_1.png"), (190, floor_y - 58), 2.0)
    paste(canvas, load("assets/world/spring.png"), (360, floor_y - 28), 1.1)

    return caption_bar(
        canvas,
        "Desert trail",
        "Canyons, badges, bandits, springs, and the saloon goal — handmade western platforming.",
    )


def build_cave_trail() -> Image.Image:
    w, h = 960, 420
    canvas = Image.new("RGBA", (w, h), (28, 32, 48, 255))
    sky = load("assets/world/cave_sky.png").resize((w, h), Image.Resampling.LANCZOS)
    paste(canvas, sky, (0, 0))

    ceiling = load("assets/world/cave_ceiling_tile.png")
    cx = -40
    while cx < w + 40:
        paste(canvas, ceiling, (cx, -20), 0.55)
        cx += int(ceiling.width * 0.55) - 12

    floor = load("assets/world/cave_floor_tile.png")
    floor_y = 300
    tile_x(canvas, floor, floor_y, -20, w + 40)

    paste(canvas, load("assets/world/stalactite.png"), (160, 70), 1.0)
    paste(canvas, load("assets/world/acid_drip.png"), (280, 55), 1.2)
    paste(canvas, load("assets/world/poison_fungus.png"), (90, floor_y - 48), 1.2)
    paste(canvas, load("assets/world/skeleton.png"), (240, floor_y - 72), 1.25)
    paste(canvas, load("assets/world/cave_bat_0.png"), (420, 150), 1.5)
    paste(canvas, load("assets/world/ladder.png"), (520, floor_y - 110), 1.0)
    paste(canvas, load("assets/world/wood_plank.png"), (500, floor_y - 118), 0.9)
    paste(canvas, load("assets/world/scorpion_idle.png"), (640, floor_y - 36), 1.3)
    paste(canvas, load("assets/world/goal_crystal_gate.png"), (780, floor_y - 130), 0.9)
    paste(canvas, load("assets/player/cowgirl/run_2.png"), (360, floor_y - 58), 2.0)
    paste(canvas, load("assets/world/checkpoint_cave_active.png"), (700, floor_y - 70), 1.0)

    return caption_bar(
        canvas,
        "Cave arc",
        "Crystal Mouth → Dragon Gate: drips, bats, ladders, skeletons, and the Crystal Gate.",
    )


def build_bosses() -> Image.Image:
    bosses = [
        ("Stampede Bull", "assets/world/boss_stampede_bull.png", 0.85),
        ("Midnight Coach", "assets/world/boss_midnight_coach_0.png", 0.55),
        ("Outlaw Kingpin", "assets/world/boss_outlaw_kingpin.png", 0.7),
        ("Cave Dragon", "assets/world/boss_cave_dragon_0.png", 0.72),
    ]
    cell_w, cell_h = 240, 260
    pad = 16
    w = pad + len(bosses) * (cell_w + pad)
    h = cell_h + 70
    canvas = Image.new("RGBA", (w, h), (48, 28, 14, 255))
    draw = ImageDraw.Draw(canvas)
    draw.text((pad, 12), "Bosses — lasso, don’t fight", fill=(255, 236, 196, 255), font=font(22))
    for i, (name, path, scale) in enumerate(bosses):
        x0 = pad + i * (cell_w + pad)
        y0 = 48
        panel = Image.new("RGBA", (cell_w, cell_h - 20), (92, 54, 28, 255))
        draw_p = ImageDraw.Draw(panel)
        draw_p.rectangle((2, 2, cell_w - 3, cell_h - 23), outline=(160, 90, 40, 255), width=3)
        spr = load(path)
        spr_w = int(spr.width * scale)
        spr_h = int(spr.height * scale)
        spr = spr.resize((spr_w, spr_h), Image.Resampling.LANCZOS)
        px = (cell_w - spr_w) // 2
        py = (cell_h - 50 - spr_h) // 2
        panel.alpha_composite(spr, (px, max(8, py)))
        canvas.alpha_composite(panel, (x0, y0))
        draw.text((x0 + 10, y0 + cell_h - 28), name, fill=(255, 220, 170, 255), font=font(15))
    return canvas.convert("RGB")


def build_title_card() -> Image.Image:
    w, h = 960, 360
    canvas = Image.new("RGBA", (w, h), (58, 34, 18, 255))
    sky = load("assets/world/sky_handdrawn.png").resize((w, h), Image.Resampling.LANCZOS)
    paste(canvas, sky, (0, 0))
    paste(canvas, load("assets/world/mesa_near.png"), (40, 180), 1.4)
    paste(canvas, load("assets/world/mesa.png"), (620, 160), 1.5)
    board = load("assets/ui/saloon_title_board.png")
    bw = 520
    bh = int(board.height * (bw / board.width))
    board = board.resize((bw, bh), Image.Resampling.LANCZOS)
    board_xy = ((w - bw) // 2, 40)
    paste(canvas, board, board_xy)
    # Board art is blank — title is drawn in UI; paint it for the README card.
    draw = ImageDraw.Draw(canvas)
    title = "Cowboy Trail"
    title_font = font(44)
    bbox = draw.textbbox((0, 0), title, font=title_font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = board_xy[0] + (bw - tw) // 2
    ty = board_xy[1] + (bh - th) // 2 - 6
    for ox, oy in ((-2, 0), (2, 0), (0, -2), (0, 2), (-1, -1), (1, 1)):
        draw.text((tx + ox, ty + oy), title, fill=(90, 40, 20, 255), font=title_font)
    draw.text((tx, ty), title, fill=(255, 244, 214, 255), font=title_font)
    paste(canvas, load("assets/world/cowboy_horse_ride_0.png"), (70, 150), 0.55)
    paste(canvas, load("assets/player/cowgirl/idle_0.png"), (820, 230), 2.2)
    return caption_bar(
        canvas,
        "Cowboy Trail",
        "Kid-friendly western platformer — cowboy or cowgirl, German default, nonviolent lasso.",
    )


def gif_from_frames(
    paths: list[str],
    out_name: str,
    *,
    scale: float = 2.0,
    duration_ms: int = 120,
    pad: int = 12,
    bg: tuple[int, int, int, int] = (255, 255, 255, 0),
) -> None:
    frames: list[Image.Image] = []
    max_w = max_h = 0
    raw: list[Image.Image] = []
    for rel in paths:
        im = load(rel)
        w = max(1, int(round(im.width * scale)))
        h = max(1, int(round(im.height * scale)))
        im = im.resize((w, h), Image.Resampling.NEAREST)
        raw.append(im)
        max_w = max(max_w, w)
        max_h = max(max_h, h)
    for im in raw:
        frame = Image.new("RGBA", (max_w + pad * 2, max_h + pad * 2), bg)
        frame.alpha_composite(im, (pad + (max_w - im.width) // 2, pad + (max_h - im.height) // 2))
        # Flatten onto warm wood so GitHub GIF viewers don’t get checkerboard.
        flat = Image.new("RGB", frame.size, (72, 42, 22))
        flat.paste(frame, mask=frame.split()[-1])
        frames.append(flat)
    out = OUT / out_name
    frames[0].save(
        out,
        save_all=True,
        append_images=frames[1:],
        duration=duration_ms,
        loop=0,
        optimize=True,
    )
    print(f"wrote {out.relative_to(ROOT)} ({out.stat().st_size // 1024} KiB)")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    pieces = {
        "title_card.png": build_title_card(),
        "desert_trail.png": build_desert_trail(),
        "cave_trail.png": build_cave_trail(),
        "bosses.png": build_bosses(),
    }
    for name, img in pieces.items():
        path = OUT / name
        img.save(path, optimize=True)
        print(f"wrote {path.relative_to(ROOT)} ({path.stat().st_size // 1024} KiB)")

    gif_from_frames(
        [f"assets/player/run_{i}.png" for i in range(4)],
        "cowboy_run.gif",
        scale=3.0,
        duration_ms=110,
    )
    gif_from_frames(
        [f"assets/player/cowgirl/run_{i}.png" for i in range(4)],
        "cowgirl_run.gif",
        scale=3.0,
        duration_ms=110,
    )
    gif_from_frames(
        [
            "assets/world/cowboy_horse_ride_0.png",
            "assets/world/cowboy_horse_ride_1.png",
        ],
        "horse_ride.gif",
        scale=0.85,
        duration_ms=160,
    )
    gif_from_frames(
        [
            "assets/world/boss_cave_dragon_fly_0.png",
            "assets/world/boss_cave_dragon_fly_1.png",
        ],
        "dragon_fly.gif",
        scale=1.35,
        duration_ms=180,
    )
    gif_from_frames(
        [
            "assets/world/cave_bat_0.png",
            "assets/world/cave_bat_1.png",
        ],
        "cave_bat.gif",
        scale=2.5,
        duration_ms=140,
    )


if __name__ == "__main__":
    main()
