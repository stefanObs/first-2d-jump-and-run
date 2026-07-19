# First 2D Jump-and-Run

A small, friendly 2D platform game for children around six years old.

## Chapter 1: Vision

### Goal and design principles

- Complete 10 long trail levels; a full clear should take about 45 minutes.
- Keep controls simple, forgiving, and understandable without much reading.
- Make every level slightly harder while avoiding sudden difficulty spikes.
- Reward exploration and progress; do not punish failure.
- Use cheerful visuals, clear sounds, large buttons, and no advertisements or online features.
- Theme the adventure as a friendly wild-west cowboy journey with readable, colorful graphics suited to a six-year-old.

## Chapter 2: Feature list

### Core features

- 10 long levels with a gradual difficulty curve (~45 minutes total)
- Simple running and jumping with forgiving controls
- Full keyboard and Xbox controller support on PC
- Three numbered save slots with automatic saving
- Checkpoints and instant retries without limited lives
- Stars to collect as an optional extra challenge
- Collectible items that temporarily activate special player modes
- A dedicated flying level
- Simple opponents and obstacles that can hurt the player
- A short celebration and automatic transition after every level
- A longer final celebration after level 10
- Large, child-friendly menus with minimal reading
- Pause, restart, settings, and save-selection screens
- Three local custom-trail slots with a grid-based family level editor and play-test flow
- Original hand-drawn cowboy animation and looping cheerful trail music
- Local offline play with no advertisements, purchases, or online account

### Gameplay features

- Coyote time, jump buffering, and variable jump height
- Moving and disappearing platforms
- Spring pads, wind zones, conveyor belts, and timed doors
- Flying, high-jump, speed, and invincibility modes
- Slow, predictable opponents that are avoided by jumping over them
- Clear visual and audio feedback for goals, checkpoints, and collectibles
- Optional animated or spoken hints
- Music, sound, and controller vibration settings
- Fullscreen/windowed mode and remappable controls

## Chapter 3: Gameplay and controls

### Core gameplay

The player can run left and right, jump, collect stars and mode items, activate checkpoints, avoid opponents and obstacles, and reach a clearly marked goal. Falling into a pit or taking damage returns the player to the latest checkpoint after a short recovery animation, without losing lives or saved progress.

### Keyboard controls

- Keyboard: arrow keys or `A`/`D` to move, `Space` to jump
- `Escape`: pause

### Xbox controller support

The game must be fully playable with an Xbox One or Xbox Series controller connected to the PC by USB or Bluetooth. No keyboard or mouse should be required after the game starts.

- Left stick or D-pad: move and navigate menus
- `A`: jump and confirm
- `B`: go back
- Menu button: pause
- Controller vibration: optional feedback for checkpoints and level completion

All menus must show the correct Xbox button prompts when a controller is active. The game should switch automatically between keyboard and controller prompts based on the last input used. Connecting or disconnecting a controller while playing must not interrupt the game.

Jumping should include coyote time, jump buffering, and variable jump height so that it feels forgiving. Moving platforms should carry the player reliably.

## Chapter 4: Items and player modes

Special items found in the levels temporarily change how the player moves or interacts with the world. Each item must have a unique shape, color, icon, and sound so a child can recognize it without reading.

- **Wings:** activates flying mode; the player holds the jump button to rise and releases it to descend.
- **Magic Boots:** increases jump height and makes long gaps easier.
- **Speed Star:** makes the player run faster while keeping acceleration controllable.
- **Bubble Shield:** makes the player immune to all damage for a limited time. Pits still return the player safely to the latest checkpoint.

An item plays a short transformation animation when collected. A large icon and a simple visual timer show which mode is active and when it will end. Mode items should be placed where their ability is useful, with a safe practice area before any difficult section.

Only one special mode is active at a time. Collecting another mode item replaces the current mode. Important items respawn if the player returns to a checkpoint, preventing the player from becoming stuck.

## Chapter 5: Opponents, obstacles, and damage

Opponents use simple, repeating movement patterns, such as walking between two points or slowly flying up and down. They are obstacles rather than combat targets: the player avoids them by jumping over, flying around, or waiting for a safe moment. There are no weapons and opponents do not need to be defeated.

Harmful obstacles may include spikes, rolling objects, falling objects, and moving barriers. Every danger must be clearly visible, move predictably, and provide enough reaction time for a young child. Taking damage causes a gentle bounce, a clear sound, and a quick return to the latest checkpoint; there is no health counter, life limit, or game-over screen.

## Chapter 6: Level progression

1. **Dusty Trail** – walking, jumping, and the saloon goal
2. **Badge Meadow** – collecting sheriff badges across a long meadow
3. **Bronco Springs** – spring pads and higher ledges
4. **Canyon Ferry** – moving rafts across canyon gaps
5. **Outlaw Cave** – camps, simple outlaws, and careful jumps
6. **Windy Mesa** – Magic Boots, gentle wind, and longer jumps
7. **Sky Ranch** – Wings for a flying trail between cloud barns
8. **Rail Yard** – Bubble Shields, conveyors, and timed yard gates
9. **Moonlight Gulch** – Speed Stars mixed with earlier trail tricks
10. **Rainbow Saloon** – a celebratory finale using all learned skills

Each level introduces at most one new mechanic, demonstrates it safely, and then asks the player to use it. Optional stars provide an extra challenge but are never required to continue.

## Chapter 7: Level completion and progression

Reaching the goal disables player input and starts a 3–5 second celebration: the character cheers, collected stars fly into the counter, music plays, and the screen transitions with a colorful wipe. The next level then starts automatically. After level 10, a longer celebration returns to the save selection screen.

## Chapter 8: Save system

The start screen displays three large save cards numbered **1**, **2**, and **3**. Each card shows the current level, collected stars, and total play time. Selecting an empty card starts level 1; selecting an existing card continues immediately.

Progress is saved automatically after every level. A parent-accessible hold-to-confirm action can erase a save, preventing accidental deletion. Saves are stored locally and the game works fully offline.

## Chapter 9: Child-friendly design and accessibility

- No lives, game-over screen, weapons, timers, or permanent failure
- Frequent checkpoints and instant retries
- Predictable opponents and clearly marked harmful obstacles
- Optional spoken or animated hints instead of text-heavy instructions
- Adjustable music and sound volume
- Fullscreen/windowed mode and remappable controls
- High-contrast goal markers and mechanics that do not rely on color alone
- Pause menu with **Continue**, **Restart Level**, **Save Selection**, and **Settings**

## Chapter 10: Technology stack

- **Engine:** Godot 4.x
- **Language:** GDScript
- **Rendering:** Godot 2D renderer using tile maps and animated sprites
- **Input:** Godot InputMap actions for keyboard and joypad controls
- **Controller support:** Godot joypad API and built-in controller mappings, tested with Xbox One and Xbox Series controllers over USB and Bluetooth
- **Data:** Godot resources for level metadata; versioned JSON files for the three saves
- **Audio:** OGG music and WAV/OGG sound effects
- **Targets:** Windows PC first, followed by Linux and optional web export
- **Testing:** Scene-based headless suite plus manual keyboard, Xbox controller, and child play-testing

Godot is well suited to a small 2D game, has a compact scene system, exports to the intended platforms, supports Xbox-compatible controllers without an additional input library, and does not require licensing fees. The Windows desktop build is the primary release because it provides the most predictable Xbox controller experience.

### Running the game

The launch scripts locate Godot 4, set the project directory correctly, and forward any additional command-line arguments to Godot.

- **Linux:** run `./run_linux.sh`
- **Windows PC:** double-click `run_windows.bat` or run it from Command Prompt
- **Tests:** `godot --headless --path . res://tests/test_runner.tscn`

Godot must either be available on `PATH` or be specified with the `GODOT_BIN` environment variable. On Windows, the launcher also detects a `Godot_v*-stable_win64.exe` placed beside the script.

## Chapter 11: Implementation approach

Use reusable Godot scenes rather than building each level independently:

- `Main` manages menus, save selection, and scene transitions.
- `GameManager` tracks the active save, level progress, stars, and settings.
- `InputManager` maps keyboard and controller actions, detects the active device, changes button prompts, and handles controller connection changes.
- `Player` contains movement, animation, checkpoints, damage handling, and input handling.
- `ModeController` activates timed player modes and updates their visual indicator.
- `LevelBase` defines spawn points, checkpoints, collectibles, and the goal.
- Reusable components implement opponents, hazards, mode items, moving platforms, springs, wind, doors, and conveyors.
- A transition controller owns the completion animation and loads the next level.

All gameplay code should read named actions such as `move_left`, `move_right`, `jump`, `confirm`, `back`, and `pause` instead of checking physical keys or controller buttons directly. This keeps keyboard and Xbox controller behavior consistent and allows controls to be remapped.

### Code quality and development best practices

Keep the codebase clean, readable, and easy to resume after a pause. Every iteration must follow these practices:

- Prefer small, single-purpose scripts, scenes, and functions over large multi-purpose files.
- Use clear names for nodes, actions, signals, and variables; avoid abbreviations that need explaining.
- Keep gameplay logic in dedicated scripts and keep scenes free of duplicated configuration.
- Prefer composition with reusable scenes and components over deep inheritance.
- Avoid magic numbers in gameplay code; expose tunable values as exported properties with sensible defaults.
- Keep side effects explicit: input, saves, scene changes, and audio belong in clearly named managers.
- Do not leave dead code, commented-out experiments, or unused scenes in the repository.
- Add automated tests for new gameplay logic and keep existing tests green before tagging an iteration.
- Match existing formatting and structure; do not introduce a second style for the same kind of file.
- Document only non-obvious decisions; let names and structure carry most of the meaning.
- Treat the README progress block as part of the delivery: update it before ending a cycle.

### Iterative development workflow

Development is organized into small, playable iterations. Every iteration follows the same process:

1. Select a small group of related changes from the specification.
2. Implement the changes incrementally, keeping the game playable after each step.
3. Add or update automated tests for gameplay logic, save data, input handling, and transitions.
4. Run the complete automated test suite and fix all failures.
5. Start the game and test the affected behavior thoroughly with keyboard and Xbox controller.
6. Confirm every touched level still has safe star collection and forward-only solvability (see Chapter 14).
7. Play through all completed levels to check for regressions.
8. Confirm that the iteration meets its acceptance criteria.
9. Commit the finished work and create an annotated Git tag for the iteration.

Iteration tags use semantic versioning, starting with `v0.1.0`. Minor versions mark playable feature iterations, patch versions mark fixes, and `v1.0.0` marks the first complete release. A tag is created only when tests pass and the iteration is playable.

### Planning future extensions

When all currently planned features are complete, review the game and create a list of possible extensions before starting more implementation. Each extension should include:

- A short description and benefit for the player
- Estimated implementation effort: **Low**, **Medium**, or **High**
- Expected child-friendly value: **1–5**
- Technical risk: **Low**, **Medium**, or **High**
- Priority rating: **1–5**, where 5 is the strongest candidate

Extensions remain optional and must not delay a stable `v1.0.0` release. The highest-rated ideas can be selected for later iterations and receive their own version tags.

## Chapter 12: Development milestones

1. Prototype movement and one gray-box level.
2. Add keyboard and Xbox controller input, including menu navigation and device switching.
3. Add checkpoints, damage, goals, and automatic level transitions.
4. Add reusable mode items, flying controls, opponents, and harmful obstacles.
5. Add the three-slot save system and menus.
6. Create all 10 levels using reusable components.
7. Add art, animation, sound, hints, settings, controller prompts, and accessibility features.
8. Play-test with adults first, then supervised children; tune jump distances, opponent speed, and checkpoint placement.

Each milestone may contain several small iterations. Every completed iteration must follow the workflow above and receive its own Git tag.

## Chapter 13: Progress and resumability

The progress of every development cycle must be recorded in this README so work can continue safely after a pause, exhausted credits, a compressed context window, or a new development session. The README is the human-readable source of truth and must be updated before ending a work session whenever practical.

Each cycle must maintain the following status block:

### Current development status

- **Current iteration:** `v1.3.0` reachable hazards, hand-drawn cowboy, music, and custom trail builder
- **Last completed step:** Removed blocking plank highways, repaired pits/checkpoints/fall recovery, added original art/music and a three-slot editor
- **Currently in progress:** Final verification and release commit
- **Next step:** Supervised child play-test and live Xbox verification
- **Completed features:** Long 10-level cowboy trail; reachable hazards/ground mechanics; hand-drawn cowboy; looping music; three custom editor slots; saves; modes; Xbox-ready input; stronger Chapter 14 QA
- **Remaining work:** Additional SFX; live Xbox verification; supervised child play-tests
- **Tests last run:** `godot --headless --path . res://tests/test_runner.tscn` — all 19 tests passed; custom hub/editor/runtime smoke tests passed
- **Known issues or blockers:** Xbox controller not physically verified on this machine
- **Latest iteration tag:** `v1.3.0`
- **Relevant commit:** *(set after release commit)*

### Cycle notes — 2026-07-19 (v1.3.0)

- Removed the 36-plank highway from every campaign level; pits, cacti, opponents, springs, pickups, gates, and belts can now be reached from the ground.
- Widened pit sensors, moved unsafe camps onto solid ground, added below-level fall recovery, and removed stars left floating after the plank removal.
- Strengthened automated QA for reachable stars, supported checkpoints, and accidental plank highways.
- Replaced the cowboy frames with original hand-drawn idle/run/jump/celebration art.
- Added original looping cheerful cowboy music with a persistent Music bus controlled by the existing volume setting.
- Added **Build Your Own Trail** from the save screen: three local slots, stamp/grid editing, automatic saves, and isolated play-testing.

### Cycle notes — 2026-07-19 (v1.2.10)

- First conveyor ride explains the belt push; closed gates shout WAIT!.
- Save-select title gently bobs for a friendlier welcome.

### Cycle notes — 2026-07-19 (v1.2.9)

- Yard gates stay open longer and show OPEN / WAIT / HURRY so kids can react in time.
- First spring bounce teaches "Boing! Springs launch you up!"

### Cycle notes — 2026-07-19 (v1.2.8)

- Approaching the saloon shows a bouncing THIS WAY! cue.
- Gates and clouds warn longer before changing; Magic Boots sparkle at the cowboy's feet.

### Cycle notes — 2026-07-19 (v1.2.7)

- Badge counter pops when a star is collected; Zoom mode kicks up dust.
- Save select sun gently glows to make the title screen friendlier.

### Cycle notes — 2026-07-19 (v1.2.6)

- Cheerful milestone toasts at 25/50/75/92% of each long trail.
- Camp marks on the progress bar; confetti on level complete; bandits flash JUMP! when nearby.

### Cycle notes — 2026-07-19 (v1.2.5)

- Power-ups last longer on the long trail; camera zooms out a little more.
- Landing dust puffs; cacti say OUCH!; bandits are labeled; badge milestones cheer.
- HUD trail % shows how far kids have ridden toward the saloon.

### Cycle notes — 2026-07-19 (v1.2.4)

- Each level greets kids with a "Let's go" toast naming the trail.
- Camera zooms out slightly so more of the long course is visible.
- Saloon goal pulses; Bubble Shield draws a clear aqua bubble; conveyors push more gently.

### Cycle notes — 2026-07-19 (v1.2.3)

- Camps pop and wave when saved; pits show a clear PIT! label; cacti are larger.
- Pause and save screens use kid-friendly trail wording and bigger buttons.
- Gates, rafts, and mode pickups are more obvious on the long courses.

### Cycle notes — 2026-07-19 (v1.2.2)

- Springs, rafts, wind, and cloud platforms got clearer kid-readable labels and colors.
- Canyon pits show a rim; cacti are larger; outlaws patrol slower.
- Level-clear overlay uses a warm desert celebration wipe.

### Cycle notes — 2026-07-19 (v1.2.1)

- Badge stars and mode pickups gently bob so they stay easy to spot.
- Outlaws look more cartoonish; HUD uses parchment banners.
- Slightly more forgiving coyote/buffer/jump for long courses.

### Cycle notes — 2026-07-19 (v1.2.0)

- Expanded every level to a long multi-section trail (~7200px) aiming for ~45 minutes full clear.
- Added sun, mesas, fence posts, grass-topped ground, brighter badges, and camp flag tips.
- Three camps (checkpoints) per level; camera limits follow the saloon goal.
- Renamed levels to Dusty Trail → Rainbow Saloon; updated GameManager titles.
- Chapter 1/2/6 updated for the longer adventure.

### Cycle notes — 2026-07-19 (v1.1.1)

- Expanded Chapter 14 with level-completion, platform-reachability, effect-visibility, and environment-styling requirements.
- Extended `LevelLayoutRules` to model platform-to-platform reachability and verify visible themed art on gameplay objects.
- The strict test command now rejects script, parse, and compile errors in addition to failed assertions.

### Cycle notes — 2026-07-19 (v1.1.0)

- Documented mandatory QA: stars collectible without dying, levels solvable without backtracking behind checkpoints.
- Added animated cowboy player frames and wild-west props (cactus, badge stars, saloon goal, desert UI).
- Added `LevelLayoutRules` automated checks for all 10 levels.

### Cycle notes — 2026-07-19 (v1.0.1)

- Fixed stars that sat above normal jump height, especially on levels 3, 5, and 6.
- Added a star platform on Checkpoint Cave and lowered the Windy Hill platform for Magic Boots.
- Increased spring bounce and Magic Boots jump multiplier for child-friendly reach.
- Added `StarReachability` helper and a regression test.

### Rated possible extensions (post-v1.0.0)

| Extension | Effort | Child value (1–5) | Risk | Priority (1–5) |
| --- | --- | --- | --- | --- |
| Hand-drawn character and level art pack | High | 5 | Medium | 5 |
| Cheerful music and sound effects | Medium | 5 | Low | 5 |
| Spoken animated tutorial tips | Medium | 4 | Medium | 4 |
| Cooperative two-controller mode | High | 4 | High | 3 |
| Photo-mode / sticker scrapbook of cleared levels | Medium | 4 | Low | 3 |
| Seasonal costume unlocks | Low | 3 | Low | 2 |
| Level editor for parents | High | 3 | High | 2 |

### Cycle notes — 2026-07-19 (v1.0.0)

- Added `GameManager`, `InputManager`, `ModeController`, pause/settings/save-select UI, HUD, and reusable world components.
- Built all 10 specification levels with progressive mechanics.
- Bubble Shield blocks opponent damage; pits still respawn to checkpoints.
- Tests now run through `res://tests/test_runner.tscn`.
- Run game: `./run_linux.sh` or `run_windows.bat`.
- Run tests: `godot --headless --path . res://tests/test_runner.tscn`

### Cycle notes — 2026-07-19 (v0.2.1)

- Added `run_linux.sh` and `run_windows.bat`.
- Both launchers resolve the repository root and forward optional Godot arguments.
- Linux checks `GODOT_BIN`, `godot4`, `godot`, and the user-local Godot binary.
- Windows checks `GODOT_BIN`, `godot4.exe`, `godot.exe`, and a Godot executable beside the script.

### Cycle notes — 2026-07-19 (v0.2.0)

- Added `LevelController`, `LevelCompletionFlow`, `Checkpoint`, `Goal`, `Hazard`, and `LevelTransition`.
- Level 01 now includes a mid-level flag, a pit hazard, a working goal, and auto-loads Level 02 after a short celebration.
- Player supports input lock, respawn, and brief invulnerability after being hurt.
- Files touched: `scripts/levels/**`, `scripts/world/**`, `scripts/ui/**`, `scripts/player/player.gd`, `scenes/**`, `tests/run_tests.gd`, `README.md`.

### Cycle notes — 2026-07-19 (v0.1.0)

- Added code quality and development best practices to Chapter 11.
- Created Godot 4.4.1 project under this repository root.
- Implemented `JumpAssist`, `Player`, `InputBindings`, `scenes/main.tscn`, and `scenes/levels/level_01.tscn`.
- Run the game with: `godot --path .`
- Run tests with: `godot --headless --path . -s res://tests/run_tests.gd`

At the end of each cycle:

1. Update every field in the status block.
2. List the exact files and systems changed.
3. Record tests run, their results, and any manual checks performed.
4. Record unfinished work, known defects, assumptions, and important decisions.
5. Describe one concrete next action that can be started without reconstructing prior context.
6. Add the relevant commit hash and iteration tag after committing and tagging.

Detailed cycle notes may be added below the status block under a dated heading. Keep only information needed to resume work; move obsolete details into Git history instead of allowing the README to become a long activity log.

## Chapter 14: Level QA and automated testing requirements

Every iteration that changes levels, stars, hazards, checkpoints, or player movement must keep these checks green:

1. **Safe star collection:** Every star can be collected without taking damage or falling into a hazard at the moment of collection. Stars must not overlap hazards or opponent hurt boxes, and collecting a star must not require standing inside a dangerous volume.
2. **Forward-only solvability:** Every level can be finished without going back behind a mid-level checkpoint after that checkpoint has been activated. Required route objects stay ahead of or on the way to the next forward landmark (spawn → checkpoint → goal).
3. **Reachable stars:** Every star remains within jump, spring, boots, flight, or clearly intended assist range from a standable surface.
4. **Level completion:** Every level has a valid, continuous route from spawn to goal using the abilities available before they are needed.
5. **Reachable platforms:** Every platform can be reached from the ground, another reachable platform, or an available assist such as springs, Magic Boots, moving platforms, or Wings.
6. **Visible effects:** Power-up, checkpoint, damage, collection, goal, and completion effects must be clearly visible against the background and understandable without text.
7. **Styled environments:** Backgrounds, ground, platforms, hazards, goals, opponents, and collectibles must have deliberate theme styling—not unstyled debug shapes or invisible collision-only objects.
8. **Manual smoke:** After layout, movement, or visual changes, play each touched level with keyboard and, when available, an Xbox controller. Confirm visual effects remain readable during movement.

Automated tests must encode rules 1–7 where they can be verified structurally or mathematically. Manual play-testing completes the visual and feel checks. A tagged iteration is invalid if these checks fail.

## Chapter 15: Definition of done


- All 10 levels can be completed with keyboard and gamepad.
- The complete game and every menu can be used with an Xbox controller connected to the PC.
- USB/Bluetooth connection changes and switching between keyboard and controller work safely.
- The flying level and all collectible player modes work with keyboard and controller.
- The Bubble Shield prevents damage for its full active duration.
- Opponents and harmful obstacles are predictable, clearly visible, and never remove saved progress.
- Difficulty increases gradually and every new mechanic is introduced safely.
- Completion animation always leads directly to the next level.
- All three save slots load, save, display, and erase progress correctly.
- Closing and reopening the game preserves completed levels and settings.
- The game can be completed without reading instructions or losing progress.
- Every star is reachable and collectible without dying on collection.
- Every level is solvable without backtracking behind an activated mid-level checkpoint.
- Every level can be completed and every platform is reachable with an ability available on the forward route.
- All effects are clearly visible, and every environment and platform is properly styled for the wild-west theme.
- The player uses a wild-west cowboy appearance with visible movement animation.
