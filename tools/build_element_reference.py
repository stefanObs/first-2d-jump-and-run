#!/usr/bin/env python3
"""Build a labeled element-name reference sheet from real game assets."""

from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "element_name_reference.png"

# (display_name, relative_asset_path, note) — class_name / level node prefixes.
ENTRIES: list[tuple[str, str, str]] = [
    # Player & mount
    ("Player", "assets/player/idle_0.png", "cowboy"),
    ("Horse / horseback", "assets/world/cowboy_horse_ride_0.png", "start_mounted"),
    # Collectibles & goals
    ("Star", "assets/world/star_badge.png", "TrailStar*"),
    ("ModeItem · Wings", "assets/world/modes/wings.png", ""),
    ("ModeItem · Magic Boots", "assets/world/modes/magic_boots.png", ""),
    ("ModeItem · Speed Star", "assets/world/modes/speed_badge.png", ""),
    ("ModeItem · Bubble Shield", "assets/world/modes/bubble_shield.png", ""),
    ("Checkpoint", "assets/world/checkpoint_active.png", "Camp"),
    ("Goal", "assets/world/goal_saloon.png", "saloon door"),
    ("Open Treasure Chest", "assets/world/treasure_chest_open.png", "TreasureChest"),
    ("Ladder", "assets/world/ladder.png", "climb branch"),
    # Hazards & foes (desert)
    ("Cactus", "assets/world/cactus.png", "Hazard"),
    ("Canyon", "assets/world/canyon_rim_left.png", "Pit* → Canyon"),
    ("Cave Canyon", "assets/world/cave_canyon_rim_left.png", "Cave gap ridges"),
    ("Carrion", "assets/world/carrion_bird.png", "Carrion"),
    ("Rattlesnake", "assets/world/rattlesnake_idle.png", ""),
    ("Opponent", "assets/world/bandit.png", "Bandit"),
    ("Trail Bull", "assets/world/boss_stampede_bull.png", "BullEnemy"),
    ("Ninja", "assets/world/ninja_idle.png", "NinjaEnemy"),
    ("SpringPad", "assets/world/spring.png", "Spring*"),
    # Platforms & world
    ("Ground", "assets/world/trail_desert_tile.png", "TrailFloor"),
    ("ConveyorBelt", "assets/world/conveyor.png", "Conveyor*"),
    ("MovingPlatform · Plank", "assets/world/wood_plank.png", "FerryStep* / Moving*"),
    ("MovingPlatform · Cloud", "assets/world/cloud.png", "Cloud* / FerryCloud*"),
    ("DisappearingPlatform", "assets/world/cloud.png", "blink cloud"),
    ("TimedDoor", "assets/world/timed_door.png", ""),
    ("WindZone", "assets/world/wind_gust.png", "Wind*"),
    ("Mesa", "assets/world/mesa.png", "backdrop"),
    ("Ledge", "assets/world/ground_tile.png", "Boots*Ledge"),
    # Bosses (desert)
    ("Stampede Bull", "assets/world/boss_stampede_bull.png", "Bull / LassoRing"),
    ("Midnight Coach", "assets/world/boss_midnight_coach_0.png", "Coach / Door0–2"),
    ("Outlaw Kingpin", "assets/world/boss_outlaw_kingpin.png", "Kingpin"),
    ("Guard", "assets/world/boss_bodyguard.png", "Guard0/1"),
    ("CoachLantern", "assets/world/lantern_fly_0.png", ""),
    # Cave remaps & cave-only
    ("Bow Skeleton", "assets/world/skeleton.png", "Opponent / skeleton"),
    ("Crystal Skeleton", "assets/world/skeleton_crystal.png", "bounty"),
    ("Cave Lizard", "assets/world/cave_lizard.png", "BullEnemy cave"),
    ("Scorpion", "assets/world/scorpion_idle.png", "Rattlesnake cave"),
    ("Bat", "assets/world/cave_bat_0.png", "BatEnemy"),
    ("Stalactite", "assets/world/stalactite.png", "StalactiteHazard"),
    ("Acid Drip", "assets/world/acid_drip.png", "AcidDrip"),
    ("Cave Ceiling", "assets/world/cave_ceiling_tile.png", "CaveCeiling / FlightCeilingCave"),
    ("Poison Fungus", "assets/world/poison_fungus.png", "Hazard cave"),
    ("Fungus Spores", "assets/world/poison_fungus_2.png", "spore-puff burst"),
    ("Crystal Gate", "assets/world/goal_crystal_gate.png", "Goal cave"),
    ("Lantern Camp", "assets/world/checkpoint_cave_active.png", "Checkpoint cave"),
    ("Cave Dragon", "assets/world/boss_cave_dragon_0.png", "boss"),
]

COLS = 5
CELL_W = 280
CELL_H = 210
PAD_X = 28
PAD_Y = 24
HEADER_H = 110
FOOTER_H = 56
MARGIN = 36

BG = (48, 28, 14)  # deep wood
PANEL = (92, 54, 28)
PANEL_EDGE = (160, 90, 40)
CREAM = (245, 220, 140)
INK = (32, 14, 6)
SUBTLE = (210, 180, 110)
PARCHMENT = (236, 210, 160, 230)
PARCHMENT_EDGE = (180, 130, 70, 200)


def load_font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
        if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
        if bold
        else "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf"
        if bold
        else "/usr/share/fonts/truetype/freefont/FreeSans.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def fit_sprite(path: Path, max_w: int, max_h: int) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    w, h = im.size
    scale = min(max_w / w, max_h / h, 1.0 if max(w, h) < 200 else 4.0)
    if max(w, h) < 120:
        scale = min(max_w / w, max_h / h)
    nw, nh = max(1, int(w * scale)), max(1, int(h * scale))
    return im.resize(
        (nw, nh),
        Image.Resampling.NEAREST if max(w, h) <= 128 else Image.Resampling.LANCZOS,
    )


def rounded_rect(draw: ImageDraw.ImageDraw, box, fill, outline, radius=16, width=3):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def main() -> None:
    rows = (len(ENTRIES) + COLS - 1) // COLS
    width = MARGIN * 2 + COLS * CELL_W + (COLS - 1) * PAD_X
    height = MARGIN * 2 + HEADER_H + rows * CELL_H + (rows - 1) * PAD_Y + FOOTER_H

    canvas = Image.new("RGBA", (width, height), BG + (255,))
    draw = ImageDraw.Draw(canvas)
    for y in range(height):
        t = y / max(1, height - 1)
        r = int(72 + 40 * t)
        g = int(42 + 18 * t)
        b = int(18 + 8 * t)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))

    rounded_rect(draw, (12, 12, width - 13, height - 13), None, PANEL_EDGE, radius=22, width=5)
    rounded_rect(draw, (22, 22, width - 23, height - 23), None, CREAM + (180,), radius=18, width=2)

    title_f = load_font(42, bold=True)
    sub_f = load_font(18, bold=False)
    name_f = load_font(18, bold=True)
    note_f = load_font(13, bold=False)

    title = "Cowboy Trail — Element Names"
    draw.text((width // 2, MARGIN + 18), title, font=title_f, fill=CREAM, anchor="mt")
    subtitle = (
        "Canonical names for commands (class_name / level node prefixes). "
        "Press F1 in-game for live labels."
    )
    draw.text((width // 2, MARGIN + 68), subtitle, font=sub_f, fill=SUBTLE, anchor="mt")

    missing: list[str] = []
    for i, (name, rel, note) in enumerate(ENTRIES):
        col = i % COLS
        row = i // COLS
        x0 = MARGIN + col * (CELL_W + PAD_X)
        y0 = MARGIN + HEADER_H + row * (CELL_H + PAD_Y)

        cell = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
        cd = ImageDraw.Draw(cell)
        rounded_rect(
            cd, (0, 0, CELL_W - 1, CELL_H - 1), PANEL + (235,), PANEL_EDGE, radius=14, width=3
        )
        rounded_rect(
            cd, (8, 8, CELL_W - 9, CELL_H - 9), PARCHMENT, PARCHMENT_EDGE, radius=10, width=2
        )

        sprite_box_h = 118
        path = ROOT / rel
        if path.exists():
            spr = fit_sprite(path, CELL_W - 36, sprite_box_h - 8)
            alpha = spr.split()[-1]
            shadow_layer = Image.new("RGBA", spr.size, (40, 20, 8, 90))
            shadow_layer.putalpha(alpha.point(lambda a: min(a, 90)))
            sx = (CELL_W - spr.width) // 2 + 2
            sy = 16 + (sprite_box_h - spr.height) // 2 + 2
            cell.alpha_composite(shadow_layer, (sx, sy))
            cell.alpha_composite(spr, (sx - 2, sy - 2))
        else:
            missing.append(rel)
            cd.text((CELL_W // 2, 60), "?", font=title_f, fill=INK, anchor="mm")

        label_y = 8 + sprite_box_h + 8
        cd.text((CELL_W // 2, label_y), name, font=name_f, fill=INK, anchor="mt")
        if note:
            cd.text((CELL_W // 2, label_y + 26), note, font=note_f, fill=(90, 55, 30), anchor="mt")

        canvas.alpha_composite(cell, (x0, y0))

    footer = (
        "Say these names in commands · e.g. TimedDoor, Bow Skeleton, Stalactite, CaveCeiling, Cave Dragon"
    )
    draw.text((width // 2, height - MARGIN - 18), footer, font=note_f, fill=SUBTLE, anchor="mb")

    if missing:
        raise SystemExit("Missing assets:\n  " + "\n  ".join(missing))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    rgb = Image.new("RGB", canvas.size, BG)
    rgb.paste(canvas, mask=canvas.split()[-1])
    rgb.save(OUT, optimize=True)
    print(f"wrote {OUT.relative_to(ROOT)} ({rgb.size[0]}x{rgb.size[1]}, {len(ENTRIES)} entries)")


if __name__ == "__main__":
    main()
