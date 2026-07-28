# Cowboy Trail

Child-friendly 2D western cowboy platformer (Godot **4.4**). Aimed at kids ~6: forgiving jumps, nonviolent lasso. **Classic mode** has no lives or game over; **Advanced Mode** (chosen in **Settings** before starting or continuing a slot) adds a three-life limit, badge milestones, and a game-over return to the start screen. Pick **Cowboy** or **Cowgirl** in Settings — the choice applies across all save slots. **German is the default language**; English is fully supported.

**Content version:** `1.7.1` (see `content_version.txt`). Launchers reimport when this stamp changes.

This README is the **binding source of truth** for gameplay, level design, art, i18n, and audio. Agents and contributors must follow it (see [Agent / contributor rules](#agent--contributor-rules)).

---

## How to run

- **Engine:** Godot 4.4 (set `GODOT_BIN` or have `godot` / `godot4` on `PATH`).
- **Linux:** `./run_linux.sh` — refreshes `.godot` import when `content_version.txt` differs from the cached stamp.
- **Windows (dev):** `run_windows.bat`, or no-install **`Play Cowboy Trail.exe`** / `.bat` (builds/unpacks engine and refreshes assets after git pulls).
- **macOS:** `Play Cowboy Trail.command` (downloads/caches Godot 4.4.1 on first run).
- **Portable Windows build:** `./create_exe.sh` or `create_exe.bat` → `dist/windows/CowboyTrail.exe`.
- **Update to newest version** (no git required; keeps `savegames/` and cached Godot engines):
  - **Linux:** `./update_to_newest.sh`
  - **Windows:** `update_to_newest.bat`
  - **macOS:** double-click **`Update to Newest Version.command`**
- Extra args are forwarded to Godot (e.g. `--headless`).

### Tests

```bash
godot --headless --path . res://tests/test_runner.tscn
godot --headless --path . res://tests/test_moving_platform_obstruction.tscn
```

---

## Campaign

**10 levels** (`GameManager.LEVEL_NAMES`):

1. Dusty Trail — learn mounted riding/jumping toward the saloon  
2. Badge Meadow — collect sheriff badges  
3. Bronco Springs — spring pads and higher ledges  
4. Canyon Ferry — clouds + wooden planks (not ferry-raft look); spring/plank/cloud variety  
5. Outlaw Cave — camps, bandits, careful jumps (workshop **Cave** style: Crystal Gate goal, cave remaps)  
6. Windy Mesa — Magic Boots, gentle wind, longer jumps  
7. Sky Ranch — Wings flying trail  
8. Rail Yard — Bubble Shields, conveyors, timed gates  
9. Moonlight Gulch — Speed Stars + earlier tricks  
10. Rainbow Saloon — finale using all skills  

**Bosses** (after clearing the listed level; same tools as the trail; classic mode uses **5 hearts** per fight; Advanced Mode uses campaign lives instead; nonviolent win):

| After | Boss | Win condition |
|-------|------|----------------|
| Level 3 | Stampede Bull | Bounce past horns; lasso glowing back ring 3× while stunned |
| Level 7 | Midnight Coach | Horse chase; lasso door handles 1→2→3 |
| Level 10 | Outlaw Kingpin | Lasso both guards, then the kingpin once |

After Kingpin: horizon victory ride, fade, dedication **VOM PAPI FÜR FINN**, then save select.

**Saves:** three slots; auto-save; local `savegames/` (gitignored). `SAVE_VERSION` 4 — older formats discarded. Delete via card context / Space / Xbox Y + confirm.

**Campaign Workshop / trail editor:** Upper half edits the trail with a **level style** picker (**Desert** / **Cave**), a **category picker** (each category shows an example thumbnail) plus stamp tools — the **Trail / path** category uses direct **Dirt / Canyon / Plank** icon buttons (canyon icon: both ridges with sky-blue gap; cave style swaps labels to Cave Floor / Cave Gap / Crystal Ledge), while other categories use a compact tool dropdown. Cave style remaps stamp presentation (poison fungus, bow skeletons, cave lizards, scorpions, lantern camps, Crystal Gate) and unlocks cave-only stamps (pink ceiling drops, falling stalactites, curve-flying bats). See `docs/cave_biome.md`. **+ Length / − Length** adjust the trail in **12-column steps** (defaults match built-in campaign width: **180 columns**; min 12, max 180). A stamp grid shows the **full level height** plus a horizontal slide bar to reach the end; a **▼ / ▶ chevron** collapses or expands the grid for the session so the live preview gets more room. **Right-click** a grid cell or the live preview to remove the element there. Sideways grid scroll is **edge auto-scroll or the slide bar only** (no wheel/trackpad pan). **Ground-standing props** (cactus/fungus, camps, springs, bandits/skeletons, trail bulls/lizards, ninjas, snakes/scorpions, power-ups, treasure chests, saloon/Crystal Gate) stamp **one row above dirt** so they stand on the trail surface; ceiling drips/stalactites hang from the top rows; hovering shows a ghost at **final in-game size** of where the stamp will land, and the live preview draws a **grid-aligned cell outline** plus a footprint at the correct world size (plank 80×24, pit 128×64, etc.). **Bounty Bandit**, **Trail Bull**, **Ninja**, and **Carrion Bird** stamps join the enemy palette (cave: Crystal Skeleton / Cave Lizard / Cave Bat instead of bird). Clicking the **live preview** places the selected stamp at the matching column/row (same as the grid). Lower half gives priority to a **live gameplay preview** (same build/theme as play) framed to the **full vertical extent**; horizontal pan uses the same **edge auto-scroll or slide bar** as the grid (no mid-pane follow). Chrome and grid heights stay compact so the preview stays visible on 720p. Explicit **Save Trail** and **Reset Changes**. The grid keeps a minimum edit height and scrolls vertically when the window is short so stamps stay tappable. Adjacent **canyon stamps merge into one wider gap** at build time. **Export Trails / Import Trails** in the workshop (or **Export Trail / Import Trail** in the editor) share custom levels as one portable `.cowboytrail` JSON pack — the editor reads/writes a single trail into the current session without auto-saving until you press Save. Translation editor (debug-only, F1 on save select) edits DE/EN CSV export into `savegames/`.

---

## Core gameplay

- **Move:** arrows or A/D; **jump:** Space (coyote ~0.16s, buffer ~0.15s, variable height). On a **ladder**, Space / W / Up climbs up and S / Down climbs down (left/right steps off). Xbox: stick/D-pad, A jump/climb-up, X lasso, B back, Menu pause.
- **Horse (Level 1):** `start_mounted` — faster run (~1.45×), jumps ~20% farther. Midnight Coach chase is mounted at that pace.
- **Lasso:** Alt / F / L (Xbox X) — ties bandits, trail bulls, and ninjas (pass-through, seated rope pose). A downward jump stomp from above also ties + small bounce; side/upward/standing contact hurts. Trail bulls **charge the cowboy** when he is nearby. **Ninjas ambush** ~6 grid cells ahead of the cowboy, then slash with a sword; while the cowboy **flies with Wings**, they throw handcrafted **shuriken**. Bandits placed in mid-air (workshop or level layout) **fall to the walkable surface below** before patrolling.
- **Modes** (one at a time; badge pickup adds ~5s): Wings / Magic Boots / Speed Star **30s**; Bubble Shield **7.5s** (blocks bandits, bounces cacti; **does not** save canyon falls).
- **Camps:** checkpoints; respawn there after canyon/cactus hurt. Classic mode has no life limit; **Advanced Mode** costs one life per respawn (three lives at start; every **30 badges** collected across the save grants +1 life; at zero lives a western game-over plays and returns to save select). Camps snapshot badges, opened chests, tied bandits/bulls/ninjas, and the active mode; respawn restores that snapshot and resets untied foes to their posts. **Bullets and shuriken are cleared** on respawn and never restored.
- **Treasure chests:** optional mid-trail rewards — touch to open once; a random power-up (Wings, Magic Boots, Speed Star, Bubble Shield) or one sheriff badge is rolled at open time, revealed with a pop-out animation, and activated immediately on the player (same effect as collecting that pickup); chest stays open and cannot be re-triggered; Advanced Mode badge milestones count only badge loot (+1), not power-ups. Chest collision scales to **~109% of player height** (scaled prop, not a flat grid stamp).
- **Player characters:** **Cowboy** or **Cowgirl** in Settings (all slots). Both share the same animation set (idle, run, jump, climb, celebrate, Magic Boots variants). **Idle uses a single pose frame** with a gentle scale breathe — do not alternate mismatched idle frames (causes flicker).
- **Canyons vs cactus vs pits:** **Canyons** are wide trail gaps (merged stamps, hand-painted rims, sky mouth). **Pits** are fixed **128×64 px** holes (`assets/world/pit.png`, no scaling) stamped only on trail **dirt** cells. Falling into a pit or canyon → spin recovery → camp. Cactus/bandit/carrion/snake hurt → camp (Bubble can block some damage). User-facing copy: call wide gaps **canyons**; call fixed holes **pits** (never use “pit” for a canyon).
- **Stars:** optional; goals are saloon doorways (flying over counts). Level clear → horse ride-in/mount/ride-out → next level: ride in, dismount, and **leave the horse at the level start**. Handmade desert skyline behind transitions.

Debug: F1 object names (+ Element Names sheet and Translation Editor on the start screen while debug is on); numpad `+`×2 next level; `-`×2 boss jump/cycle.

---

## World / level design rules

Agents **must** honor these when editing levels or trail systems:

### Naming & hazards

- User-facing copy: wide trail gaps = **canyon**; fixed 128×64 dirt holes = **pit** (legacy node names like `Pit3` on scaled canyon hazards may remain internally).
- **Pits:** workshop **Hazards** stamp; exact `pit.png` size; dirt-only placement; same fall/respawn/life rules as canyons (Bubble Shield does not save pit falls).
- Bandits: downward jump stomp from above / lasso tie; any other contact hurts; **turn at plank edges** (do not walk off).
- **Trail bulls:** reuse stampede-bull art scaled to bandit height; charge the player when nearby (always face the cowboy); lasso or head stomp plays the full boss tying sequence (rope coils → legs bound → tip over → lying on the floor at the same on-screen size); side contact hurts; **charges off canyon rims and falls**.
- **Ninjas:** handcrafted **chibi cel-shaded sprites** in the same big-head / thick-ink style as the bandit (`tools/generate_ninja_art.py`: hooded head, red headband + obi, navy gi, 4× supersample → 64×80); workshop stamp marks an **ambush anchor** — when the cowboy enters range, the ninja **appears ~6 columns (240 px) in front** of him, runs in with a **sword slash** on reach, and throws hand-drawn **shuriken** at winged flyers; lasso or head stomp ties with a unique bound rope pose.
- **No cactus inside canyon mouths** or on hand-painted rim bands (keep clear of the rim body past the gap).
- **No rattlesnake directly in front of** (approaching) a canyon mouth.
- **No timed doors** (`TimedDoor`) over ground canyon gaps or on rim bands (tall gates must not sit above canyon mouths).
- **Conveyors** must not push the cowboy into a canyon. Pair each belt with a timed door on **solid ground** in the push direction (Door0/Door4 pattern), or keep clear solid runout — never a belt that dumps into an open gap after a rim door was removed.

### Cave style

- Trail documents may set `"style": "cave"` (workshop **Level style**). Binding art/behavior notes: `docs/cave_biome.md`.
- Cave remaps stamp **presentation** (same type ids): fungus/lizard/scorpion/bow skeleton/lantern camp/**Crystal Gate** (saloon replacement). Cave-only stamps: `acid_drip`, `stalactite`, `bat`.
- Pink drips and falling stalactites hurt → camp respawn; **Bubble does not block** them. Bats can bounce off Bubble.
- Cave floors/sky use cool slate + pink mineral accents; no desert sun/mesa hills.
- **Ladders** (workshop Trail stamp): 3-cell climb; Space/Up climbs up, S/Down climbs down. Use ladder + elevated platforms so trails can split into an **upper and lower path that rejoin** later (sample branches appear on new trails and on Outlaw Cave workshop imports).

### Canyon art

- Hand-painted **rims sit outside** desert floor banks — never cover the brown desert surface span with rim sprites.
- Ridges are **full-height handcrafted cliff faces** (ink outlines, painted rock — same illustrative western style as cactus/mesas): a **thin canyon-facing edge** from the desert top down to the bottom of the trail dirt / view — not a short rim lip, not a wide orange slab over the bank, and not flat TrailFloor dirt-cut ends. The **bank/inland side is opaque packed dirt** (matching trail earth) so sky / FloorAbyss never peek beside the ridge. Ridge tops use the same warm sand crust as the trail and **align flush with the desert top** (no sky slits under the sand). The canyon-facing edge against open sky is a **natural jagged / irregular silhouette** (not a ruler-straight vertical cut). Rims draw **in front of** desert floor tiles so lips sit on the canyon edge. Desert surface tiles **inset by about one ridge width** at canyon lips so sand meets the ridge top instead of overlapping it; dirt runs nearly to the lip behind the face.
- Between the ridges: **open sky only** — punch horizon hills (Mesa backdrop) and FloorAbyss out of the gap column so trail SkyArt / Background shows through. Do **not** paint a stretched sky-fill column, depth shelves, floor wash, inner-wall fill, or mountain scenery inside the mouth; **never** a featureless black / flat near-black void or black outline framing the lips.
- Horizon hills / Mesa backdrop must **not** silhouette over or through canyon openings (sky continues through the gap).
- Widening a gap must not stretch handmade rim textures (width may shrink to fit; cliff height stays full).

### Floor height

- Where desert banks sit at different heights **with continuous ground** (no canyon between), paint a **natural soft curved slope** (gentle dune) with trail desert/dirt art (not a flat cliff face or ColorRect step). Slopes must be **walkable without jumping** (carve away Ground cliff walls into the dune; long gentle run so peak grade stays walkable). Slope crust ends must **start and end on the flat desert tops** (same height/seam, no stepped lip). Under the curved crust, pack **dense earth fill** (smaller tiles in the upper wedge) plus a solid warm underfill wedge — **no black or sky gaps** below the dune face.
- If a **canyon** separates banks at different heights, the canyon is the transition — do **not** paint a slope (or slope collision) across the gap.
- If the far bank after a canyon is **higher** than the near bank, there **must** be a spring on the approach (near) side so the jump is solvable. Without that spring, the far bank must be the same height or lower.
- Levels **7–10** each need **2–10** continuous height differences (distinct walk-surface Y changes along continuous ground; canyon-only transitions do not count).
- Every campaign level must be **solvable without power-up items** (Wings, Magic Boots, Speed Star, Bubble Shield). **Springs are allowed** and count toward reachability. Optional reward routes (raft hops, star ledges) may require items or timing.

### Canyon crossing

- Every canyon must be **crossable**: consecutive plank / mover / bridge / cloud hops within **normal jump reach** (Level 1 may use mounted reach). No impossible gaps.
- Prefer continuous assist chains; automated tests enforce campaign gap budgets.

### Moving platforms

- Default: **one-way** jump-through (land on top).
- Reverse before floor / solid obstructions (and other movers unless paired handoff sets `obstruction_include_movers = false`).
- Paired **opposite-phase** movers for timed handoffs when used.
- **Level 4:** clouds + wooden planks / spring variety — **not** ferry-step / raft-box look. Movers must not show ferry `raft.png` art (plank or cloud styling).

### Wind

- Gentle, **capped** sideways (and lift) push; stays controllable (`WindZone.max_wind_speed` / `max_wind_lift`).

### Layout QA (keep green)

Safe stars, forward-only solvability, reachable platforms/stars, visible themed art — see automated `LevelLayoutRules` / test runner checks.

---

## UI / art style

- Warm **handmade / hand-painted** western look matching trail tiles (sky, ground, props).
- HUD / doors / prompts: irregular **western wood signs** (`HandmadeSign`), not generic flat UI cards.
- Start screen, settings, pause, save select: stay **handcrafted** and trail-themed (polish may continue; do not regress to stock Godot chrome or mismatched stock art). Save select / boot title use a painted weathered **saloon wood sign** (peeling red rim, cream lettering, optional pointing-hand motif) in the same soft handmade style as trail tiles — not photoreal stock art.
- Between-level horse transitions use a dedicated hand-painted desert skyline.

---

## Audio

- **SFX / music:** `AudioManager` (`play_sfx`, trail/boot/finale music, volume settings).
- Default settings language: **`de`**; `internationalization/locale/fallback="de"`.

---

## Agent / contributor rules

**MUST follow** before changing gameplay, levels, art, i18n, or audio:

1. Read this README; treat it as binding. Do not use English-as-default, featureless black canyons, ferry-raft Level 4 look, or uncapped runaway wind.
2. Call wide gaps **canyons** and fixed dirt holes **pits** in player-facing strings.
3. Canyon rims outside desert banks; full-height ridge cliffs; open sky in the mouth (no Mesa/backdrop in the gap); never cover floor with rims; never featureless black.
4. Every canyon crossable with normal (or L1 mounted) jump hops / movers; no impossible gaps.
5. Movers: one-way; reverse before floor/obstructions; paired opposite-phase when handoffs are intended; L4 = clouds + planks, not ferry-step. Conveyors must not push into open canyons (pair with a timed door on solid ground).
6. Wind stays gentle and capped.
7. Bandits: stomp/lasso tie; side hurt; turn at plank edges.
8. Keep handmade western UI/art language; SFX via AudioManager; German default.
9. Run the headless test runner (and obstruction test when touching movers) for layout/gameplay changes.
10. If a change **requires** altering a documented rule, **update this README in the same change**.
11. **Dune slopes:** dense earth under the crust; no black/sky holes below the curved bank face.
12. **Workshop editor:** placement ghosts and preview icons use **final in-game stamp size** (`CustomLevelStore.stamp_visual_world_rect`); right-click removes stamps; **▼ / ▶** chevron collapses the stamp grid for the session.
13. **Treasure chests:** keep ~109% player-height gameplay scale unless this README and tests change together.
14. **Player idle:** one idle frame only (gentle breathe); no alternating mismatched idle poses.

**Workflow note:** after coherent completed work, commit and push to `main` per `.cursor/rules/always-commit-push.mdc` (unless the user/parent agent says otherwise for that task).
