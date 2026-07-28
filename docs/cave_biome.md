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

Stamp a **ladder**, run **platforms** along the upper row at the ladder top, then a second **ladder** back to the dirt trail. Lower dirt stays walkable the whole time — kids can take the high ledge or stay low; both ways meet again after the second ladder. Workshop defaults and Outlaw Cave imports include a sample split.

## Hazards & enemies

- **Pink drips:** soft glowing droplets; telegraph with a small sparkle before falling.
- **Stalactites:** thick ink rock spikes; wiggle briefly, fall, then crack into a short-lived rubble puff on the floor.
- **Bats:** wing flaps on a sine/arc path (not a straight patrol).
- **Lizards:** reuse bull AI (charge, face player, canyon falls, full tie sequence) with lizard frames.
- **Poison fungus:** cactus rules (hurt / Bubble bounce) with mushroom art and a soft toxic tint.
- **Scorpions:** rattlesnake raise/strike timing with a tail sting pose.
- **Bow skeletons:** bandit patrol + shoot cadence, but spawn **arrows** instead of revolver bullets; lasso/stomp still ties.
- **Ninjas:** unchanged ambush/sword/shuriken kit.
- **Floor holes:** same pit rules (128×64), cave mouth art.

## Own extras (shipped with the style)

1. **Lantern camp** — checkpoint with a warm lantern instead of desert bedrolls.
2. **Crystal ledge** — platform art: cool stone plank with crystal flecks (replaces wood plank look).
3. **Glow shard** (optional future pickup) — brief silhouette of drip/stalactite danger columns; not required for v1 playability.
4. **Cave wash backdrop** — no sun/mesas; dark rock ceiling band + soft depth fog instead of desert sky/hills.
5. **Mineral vein floor** — sand crust becomes cool stone with pink crystal flecks; underfill is deep slate.

## Campaign note

Builtin **Outlaw Cave** (level 5) should eventually dress as `cave` when rebuilt or
imported into the workshop. Until then, custom trails can pick Cave style freely.

## Art checklist

- Env: `cave_sky.png`, `cave_floor_tile.png`, `cave_dirt_tile.png`, `cave_plank.png`, `cave_pit.png`, `cave_rim_left.png` (optional remap)
- Goal: `goal_crystal_gate.png`
- Camp: `checkpoint_cave_active.png` (+ inactive if needed)
- Fungus: `poison_fungus.png`
- Lizard: stand / tied_legs / down (bull-sized aspect)
- Skeleton: idle + walk strip + tied (+ crystal/red bounty set)
- Scorpion: idle + sting
- Bat: 2-frame flap
- Stalactite: hang + impact rubble
- Acid drip: droplet (+ optional sparkle)
