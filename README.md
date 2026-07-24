# Cowboy Trail

Child-friendly 2D western cowboy platformer (Godot **4.4**). Aimed at kids ~6: forgiving jumps, no lives/game-over, nonviolent lasso. **German is the default language**; English is fully supported. Optional spoken instructions use local OS TTS (Narrator).

**Content version:** `1.3.35` (see `content_version.txt`). Launchers reimport when this stamp changes.

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

**Bosses** (after clearing the listed level; same tools as the trail; 5 hearts; nonviolent win):

| After | Boss | Win condition |
|-------|------|----------------|
| Level 3 | Stampede Bull | Bounce past horns; lasso glowing back ring 3× while stunned |
| Level 7 | Midnight Coach | Horse chase; lasso door handles 1→2→3 |
| Level 10 | Outlaw Kingpin | Lasso both guards, then the kingpin once |

After Kingpin: horizon victory ride, fade, dedication **VOM PAPI FÜR FINN**, then save select.

**Saves:** three slots; auto-save; local `savegames/` (gitignored). `SAVE_VERSION` 4 — older formats discarded. Delete via card context / Space / Xbox Y + confirm.

**Campaign Workshop / trail editor:** edit a copy of any built-in level or insert an extra trail before a campaign position. The bottom stamp row is the trail line (Dirt vs Canyon sets the surface and underside). A large hover magnifier at the top shows the hovered columns game-like; a thin overview strip remains under it. Editor has explicit **Save Trail** and **Reset Changes** (snapshot restore). Translation editor edits DE/EN CSV export into `savegames/`.

---

## Core gameplay

- **Move:** arrows or A/D; **jump:** Space (coyote ~0.16s, buffer ~0.15s, variable height). Xbox: stick/D-pad, A jump, X lasso, B back, Menu pause.
- **Horse (Level 1):** `start_mounted` — faster run (~1.45×), jumps ~20% farther. Midnight Coach chase is mounted at that pace.
- **Lasso:** Alt / F / L (Xbox X) — ties bandits (pass-through, seated rope pose). Head stomp also ties + small bounce. Side contact hurts.
- **Modes** (one at a time; badge pickup adds ~5s): Wings / Magic Boots / Speed Star **30s**; Bubble Shield **7.5s** (blocks bandits, bounces cacti; **does not** save canyon falls).
- **Camps:** checkpoints; respawn there after canyon/cactus hurt; no life limit. Camps store badges/mode state appropriately.
- **Canyons vs cactus:** canyon fall → spin recovery → camp. Cactus/bandit/carrion/snake hurt → camp (Bubble can block some damage). Call gaps **canyons**, never “pits”, in user-facing text.
- **Stars:** optional; goals are saloon doorways (flying over counts). Level clear → horse ride-in/mount/ride-out → next level dismount. Handmade desert skyline behind transitions.

Debug: F1 object names; numpad `+`×2 next level; `-`×2 boss jump/cycle.

---

## World / level design rules

Agents **must** honor these when editing levels or trail systems:

### Naming & hazards

- User-facing and UI copy: **canyon**, not pit (legacy node names like `PitMouth` may remain internally).
- Bandits: head stomp / lasso tie; side contact hurts; **turn at plank edges** (do not walk off).

### Canyon art

- Hand-painted **rims sit outside** desert floor banks — never cover the brown desert surface with rim sprites.
- Between the ridges: **open sky blue only** — no depth shelves, floor wash, inner-wall fill, or mountain scenery inside the mouth; **never** a featureless black / flat near-black void.
- Horizon hills must **not** silhouette over canyon openings (sky continues through the gap).
- Widening a gap must not stretch handmade rim textures.

### Floor height

- Where desert banks sit at different heights, paint a **natural soft slope** with trail desert/dirt art (not a flat cliff face or ColorRect step). Slopes must be walkable.

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
- **Narration:** `Narrator` + setting `narration` (default on). Prefers a **male** voice; German locale preferred; on Windows with no DE voice, fall back to male English then any voice (never stay silent if a voice exists).
- Project setting: `audio/general/text_to_speech=true`.
- Default settings language: **`de`**; `internationalization/locale/fallback="de"`.

---

## Agent / contributor rules

**MUST follow** before changing gameplay, levels, art, i18n, or audio:

1. Read this README; treat it as binding. Do not reintroduce “pits”, English-as-default, featureless black canyons, ferry-raft Level 4 look, or uncapped runaway wind.
2. Call gaps **canyons** in player-facing strings.
3. Canyon rims outside desert banks; illustrated interior with sky OK; never cover floor with rims; never featureless black.
4. Every canyon crossable with normal (or L1 mounted) jump hops / movers; no impossible gaps.
5. Movers: one-way; reverse before floor/obstructions; paired opposite-phase when handoffs are intended; L4 = clouds + planks, not ferry-step.
6. Wind stays gentle and capped.
7. Bandits: stomp/lasso tie; side hurt; turn at plank edges.
8. Keep handmade western UI/art language; SFX via AudioManager; male-preferring Narrator TTS; German default.
9. Run the headless test runner (and obstruction test when touching movers) for layout/gameplay changes.
10. If a change **requires** altering a documented rule, **update this README in the same change**.

**Workflow note:** after coherent completed work, commit and push to `main` per `.cursor/rules/always-commit-push.mdc` (unless the user/parent agent says otherwise for that task).
