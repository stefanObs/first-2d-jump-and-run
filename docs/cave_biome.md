# Cave biome concept (Crystal Cavern)

Hand-painted western cartoon cave trail — same thick warm-brown ink and soft cel
shading as the desert trail, but with a cooler underground palette: slate blue
stone, dusty mauve shadows, soft pink glow from mineral drips, and amber lantern
light. Tier A chibi for skeleton/ninja; Tier B naturalistic cartoon for animals,
fungus, bats, and rock.

## Saloon replacement — Crystal Gate (Kristalltor)

The trail ends at a **Crystal Gate**: a carved stone arch framed with hanging
lanterns and glowing pink/teal crystals. Crossing it leaves the cavern toward
daylight (same clear rules as the desert saloon: reach the gate’s X, flyovers
count). Workshop stamp id stays `goal`; cave style swaps the art and label.

## Level style (trail editor)

Each trail document stores `"style": "desert" | "cave"` (default `desert`).

When **Cave** is selected, stamp labels/icons switch and cave-only tools appear.
Stamp **type ids stay the same** for remapped foes/hazards so packs stay simple:

| Desert stamp | Cave presentation |
|---|---|
| Dirt / Canyon / Plank | Cave floor / Cave gap / Crystal ledge |
| Cactus | Poison fungus |
| Pit | Floor hole |
| Bandit / Bounty Bandit | Bow skeleton / Crystal skeleton |
| Bull | Cave lizard (same charge + tie poses) |
| Rattlesnake | Scorpion |
| Carrion Bird | *(hidden in cave)* |
| Camp | Lantern camp |
| Saloon | Crystal Gate |
| Ninja | Ninja (unchanged) |

### Cave-only stamps

| Stamp id | Behavior |
|---|---|
| `acid_drip` | Pink mineral drops fall from the ceiling on a timer; hit → camp respawn (Bubble does **not** block) |
| `stalactite` | Hangs dormant; when the cowboy nears, it drops; contact hurts; floor impact plays a shatter/settle animation |
| `bat` | Flies a smooth curve through the cavern; contact hurts (Bubble can block) |
| `ladder` | Climb with Space/Up (up) and S/Down (down); used for upper/lower path splits that rejoin |

Ceiling stamps place on the top rows; ground props still sit one row above dirt. Ladders stand on the trail and rise three cells.

## Path splits (ladders)

Stamp a **ladder**, run **one-way crystal ledges** along the climb top, then **drop off the end** back to the dirt trail. Lower dirt stays walkable the whole time — kids can take the high ledge or stay low. Workshop defaults and cave imports include a sample up-ladder branch (no down ladder).

## Hazards & enemies

- **Pink drips:** soft glowing droplets; telegraph with a small sparkle before falling; **splash on the floor** then respawn.
- **Stalactites:** cowboy-style rock spikes hanging from the ceiling band. Theme décor spawns a **sparse** row of dropping teeth along the trail (skips cells that already have a stamped hazard nearby), with tops embedded in the rock so they read as part of the ceiling before they fall. **Falling** ones wiggle, pull free, fall, then shatter with a transparent impact puff. **Ceiling Spike** stamps can stay put as static rock.
- **Bats:** two-frame wing flap on a sine/arc path (transparent cutouts).
- **Lizards:** reuse bull AI (charge, face player, canyon falls, full tie sequence) with a single lizard sprite.
- **Poison fungus:** cactus rules (hurt / Bubble bounce) with mushroom art and a soft toxic tint.
- **Scorpions:** rattlesnake raise/strike timing with a tail sting pose.
- **Bow skeletons:** bandit patrol + shoot cadence, but spawn **arrows** instead of revolver bullets; lasso/stomp still ties. Idle/walk/tied frames share one body height on a transparent canvas; tied pose keeps stand scale and sits on the dirt.
- **Ninjas:** ambush appears ~12 columns ahead of the cowboy.
- **Floor holes:** same pit rules (128×64), cave mouth art.

## Own extras (shipped with the style)

1. **Lantern camp** — checkpoint with a warm lantern instead of desert bedrolls.
2. **Crystal ledge** — platform art: cool stone plank with crystal flecks (replaces wood plank look).
3. **Glow shard** (optional future pickup) — brief silhouette of drip/stalactite danger columns; not required for v1 playability.
4. **Cave wash backdrop** — no sun/mesas; deep `cave_sky` wash that meets the trail floor + hanging rock ceiling. Solid `cave_ceiling_fill` closes the sky gap above the camera; the wavy lip (`cave_ceiling_tile`) sits about **2cm (~76px)** below the top of a normal grounded view with sparse droppable stalactite teeth fused under it (**Dragon Gate** and the **Cave Dragon** arena keep a clean rock band with no teeth). Rock band is solid (`FlightCeilingCave`); touching it while flying respawns at camp.
5. **Mineral vein floor** — dense cool stone crust with pink crystal flecks; underfill dirt is a **fully opaque** slate tile (no transparent side margins / sky holes when tiled); deep `FloorAbyss` slate under the bank.
## Campaign note

Builtin **Outlaw Cave** (level 5) and cave arc **levels 11–15** (`Crystal Mouth` → `Dragon Gate`) use `"style": "cave"`. After Dragon Gate the **Cave Dragon** boss flies left↔right below the ceiling (facing travel direction, wing-flap + landing poses), spits a few flameballs in a straight line toward the cowboy (2 rounds × 2 shots), lands for a lasso, then repeats; after three lassos his mouth is tied and the campaign victory plays. Workshop imports for 11–15 use the stamp catalog in `CaveCampaignLevels`. Custom trails can pick Cave style freely.

## Art checklist

- Env: `cave_sky.png`, `cave_ceiling_fill.png`, `cave_ceiling_tile.png`, `cave_floor_tile.png`, `cave_dirt_tile.png`, `cave_plank.png`, `cave_pit.png`
- Goal: `goal_crystal_gate.png`
- Camp: `checkpoint_cave_active.png` / `_inactive` (transparent cutout)
- Fungus: `poison_fungus.png`
- Lizard: stand / tied_legs / down (bull-sized aspect)
- Skeleton: idle + walk strip + tied (+ crystal/red bounty set) — walk frames same height as idle
- Scorpion: idle + sting
- Bat: 2 distinct flap frames (`cave_bat_0` / `_1`)
- Stalactite: hang + static décor + transparent impact rubble
- Acid drip: droplet + floor splash
- Ladder: transparent between rungs
