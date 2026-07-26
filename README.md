# Cowboy Trail

Child-friendly 2D western cowboy platformer (Godot **4.4**). Aimed at kids ~6: forgiving jumps, nonviolent lasso. **Classic mode** has no lives or game over; **Advanced Mode** (chosen on the save-select screen before starting a slot) adds a three-life limit, badge milestones, and a game-over return to the start screen. **German is the default language**; English is fully supported.

**Content version:** `1.3.88` (see `content_version.txt`). Launchers reimport when this stamp changes.

This README is the **binding source of truth** for gameplay, level design, art, i18n, and audio. Agents and contributors must follow it (see [Agent / contributor rules](#agent--contributor-rules)).

---

## How to run

- **Engine:** Godot 4.4 (set `GODOT_BIN` or have `godot` / `godot4` on `PATH`).
- **Linux:** `./run_linux.sh` — refreshes `.godot` import when `content_version.txt` differs from the cached stamp.
- **Windows (dev):** `run_windows.bat`, or no-install **`Play Cowboy Trail.exe`** / `.bat` (builds/unpacks engine and refreshes assets after git pulls).
- **macOS:** `Play Cowboy Trail.command` (downloads/caches Godot 4.4.1 on first run).
- **Portable Windows build:** `./create_exe.sh` or `create_exe.bat` → `dist/windows/CowboyTrail.exe`.
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
5. Outlaw Cave — camps, bandits, careful jumps  
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

**Campaign Workshop / trail editor:** Upper half edits the trail with a **category picker** (each category shows an example thumbnail) plus stamp tools — the **Trail / path** category uses direct **Dirt / Canyon / Plank** icon buttons (canyon icon: both ridges with sky-blue gap), while other categories use a compact tool dropdown. **+ Length / − Length** adjust the trail in **12-column steps** (defaults match built-in campaign width: **180 columns**; min 12, max 180). A stamp grid shows the **full level height** plus a horizontal slide bar to reach the end; sideways grid scroll is **edge auto-scroll or the slide bar only** (no wheel/trackpad pan). **Ground-standing props** (cactus, camps, springs, bandits, snakes, power-ups, saloon) stamp **one row above dirt** so they stand on the trail surface; hovering shows a ghost of where the stamp will land, and the live preview draws a footprint outline at the correct size. **Bounty Bandit** and **Carrion Bird** stamps join the enemy palette. Clicking the **live preview** places the selected stamp at the matching column/row (same as the grid). Lower half gives priority to a **live gameplay preview** (same build/theme as play) framed to the **full vertical extent**, centered on the stamp cursor; chrome and grid heights stay compact so the preview stays visible on 720p. Explicit **Save Trail** and **Reset Changes**. The grid keeps a minimum edit height and scrolls vertically when the window is short so stamps stay tappable. Adjacent **canyon stamps merge into one wider gap** at build time. **Export Trails / Import Trails** in the workshop (or **Export Trail / Import Trail** in the editor) share custom levels as one portable `.cowboytrail` JSON pack — the editor reads/writes a single trail into the current session without auto-saving until you press Save. Translation editor (debug-only, F1 on save select) edits DE/EN CSV export into `savegames/`.

---

## Core gameplay

- **Move:** arrows or A/D; **jump:** Space (coyote ~0.16s, buffer ~0.15s, variable height). Xbox: stick/D-pad, A jump, X lasso, B back, Menu pause.
- **Horse (Level 1):** `start_mounted` — faster run (~1.45×), jumps ~20% farther. Midnight Coach chase is mounted at that pace.
- **Lasso:** Alt / F / L (Xbox X) — ties bandits (pass-through, seated rope pose). A downward jump stomp from above also ties + small bounce; side/upward/standing contact hurts. Bandits placed in mid-air (workshop or level layout) **fall to the walkable surface below** before patrolling.
- **Modes** (one at a time; badge pickup adds ~5s): Wings / Magic Boots / Speed Star **30s**; Bubble Shield **7.5s** (blocks bandits, bounces cacti; **does not** save canyon falls).
- **Camps:** checkpoints; respawn there after canyon/cactus hurt. Classic mode has no life limit; **Advanced Mode** costs one life per respawn (three lives at start; every **30 badges** collected across the save grants +1 life; at zero lives a western game-over plays and returns to save select). Camps store badges/mode state appropriately.
- **Treasure chests:** optional mid-trail rewards — touch to open once; a random power-up (Wings, Magic Boots, Speed Star, Bubble Shield) or one sheriff badge is rolled at open time, revealed with a handcrafted pop-out animation, and activated immediately on the player (same effect as collecting that pickup); chest stays open and cannot be re-triggered; Advanced Mode badge milestones count only badge loot (+1), not power-ups.
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
- **No cactus inside canyon mouths** or on hand-painted rim bands (keep clear of the rim body past the gap).
- **No rattlesnake directly in front of** (approaching) a canyon mouth.
- **No timed doors** (`TimedDoor`) over ground canyon gaps or on rim bands (tall gates must not sit above canyon mouths).
- **Conveyors** must not push the cowboy into a canyon. Pair each belt with a timed door on **solid ground** in the push direction (Door0/Door4 pattern), or keep clear solid runout — never a belt that dumps into an open gap after a rim door was removed.

### Canyon art

- Hand-painted **rims sit outside** desert floor banks — never cover the brown desert surface span with rim sprites.
- Ridges are **full-height handcrafted cliff faces** (ink outlines, painted rock — same illustrative western style as cactus/mesas): a **thin canyon-facing edge** from the desert top down to the bottom of the trail dirt / view — not a short rim lip, not a wide orange slab over the bank, and not flat TrailFloor dirt-cut ends. The **bank/inland side stays transparent** so normal TrailFloor dirt tiling shows behind the face. Ridge tops use the same warm sand crust as the trail and **align flush with the desert top** (no sky slits under the sand). The canyon-facing edge against open sky is a **natural jagged / irregular silhouette** (not a ruler-straight vertical cut). The bank/inland side still meets TrailFloor earth cleanly. Rims draw **in front of** desert floor tiles so lips sit on the canyon edge. Desert surface tiles **inset slightly at canyon lips** so sand never overhangs into the mouth; dirt runs nearly to the lip behind the thin face.
- Between the ridges: **open sky only** — punch horizon hills (Mesa backdrop) and FloorAbyss out of the gap column so trail SkyArt / Background shows through. Do **not** paint a stretched sky-fill column, depth shelves, floor wash, inner-wall fill, or mountain scenery inside the mouth; **never** a featureless black / flat near-black void or black outline framing the lips.
- Horizon hills / Mesa backdrop must **not** silhouette over or through canyon openings (sky continues through the gap).
- Widening a gap must not stretch handmade rim textures (width may shrink to fit; cliff height stays full).

### Floor height

- Where desert banks sit at different heights **with continuous ground** (no canyon between), paint a **natural soft curved slope** (gentle dune) with trail desert/dirt art (not a flat cliff face or ColorRect step). Slopes must be **walkable without jumping** (carve away Ground cliff walls into the dune; long gentle run so peak grade stays walkable). Slope crust ends must **start and end on the flat desert tops** (same height/seam, no stepped lip).
- If a **canyon** separates banks at different heights, the canyon is the transition — do **not** paint a slope (or slope collision) across the gap.
- If the far bank after a canyon is **higher** than the near bank, there **must** be a spring on the approach (near) side so the jump is solvable. Without that spring, the far bank must be the same height or lower.
- Levels **7–10** each need **2–10** continuous height differences (distinct walk-surface Y changes along continuous ground; canyon-only transitions do not count).

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

- Warm **handmade / hand-painted** western look matching trail tiles (sky, ground, props, cowboy frames).
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

**Workflow note:** after coherent completed work, commit and push to `main` per `.cursor/rules/always-commit-push.mdc` (unless the user/parent agent says otherwise for that task).
