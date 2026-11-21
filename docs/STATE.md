# Seed — Current State

> Snapshot: 2026-11-21. This file is the source of truth for **what exists now**.
> If a design doc describes something here as “not implemented”, it is not playable.

## 1. Gate

```
[PASS] addons-parity: 96 files in sync
[PASS] pytest: 34 passed            (game-utils' own Python suite)
[PASS] data-validate: 3 tables, 1 localization
[PASS] godot-import: exit=0
[PASS] godot-tests: 87 assertions
[PASS] godot-smoke: frames=30 exit=0
```

## 2. Implemented

### 2.1 Starter scaffold

- `scenes/main.tscn`: 40×40 graybox plane, `GuPlayer`, `CameraRig`, guide NPC.
- Title → main scene, pause/save/settings UI, sample quest `meet_guide`.
- 11 autoloads from `gu_core` + `gu_gameplay` components.

### 2.2 Pod 07 anomaly

- `scenes/world/pod_07.tscn` + `scripts/world/pod_07.gd`.
- Three dialogue entries in `data/content/dialogue.json`:
  - `pod_07` (30 nodes)
  - `pod_07_after_power` (10 nodes; trigger not wired yet)
  - `pod_07_chip_log` (7 nodes; analysis not wired yet)
- `data_chip_07` item.
- 79 localized strings added for the dialogue (plus the rest of the CSV).
- `pod_07_after_power` and `pod_07_chip_log` exist in content but **have no trigger**
  because there is no power system / AI analysis table yet.

### 2.3 Hunger loop

- `scripts/survival/hunger_controller.gd`:
  - `hunger` stat, 0–100, starts at 65.
  - Decays at `0.05`/second (~3/min) while gameplay is active.
  - Threshold hints at 40% and 15%.
  - `H` eats a wild berry (+12 hunger).
  - HUD eat hint `[H] Eat Wild Berry (n)`.
- HUD hunger bar via `GameplayHud.add_stat_bar`.
- AI subtitle label (`Ship AI: ...`) for hunger/colonist/build hints.
- `scenes/world/berry_bush.tscn` + `scripts/world/berry_bush.gd`:
  - 3 berries per harvest, 30 s respawn.
- Two berry bushes near spawn.
- `wild_berry` item.

### 2.4 Geneticist pod (locked)

- `scenes/world/geneticist_pod.tscn` + `scripts/colony/colonist_pod.gd`.
- Shows missing requirements through the AI subtitle:
  - thermal generator
  - power `0/20`
  - shelter
  - food `n/10`
  - med bay
- `can_wake()` checks flags + inventory.
- When all requirements are met, emits “All requirements met. We can try waking the geneticist.”
- **No wake sequence exists.** The pod stays locked in normal play until the power /
  shelter systems set the flags.

### 2.5 Shelter and thermal generator build sites

- `scripts/world/build_site.gd` (generic).
- `scenes/world/shelter_site.tscn`:
  - costs 5 wood + 3 fiber
  - sets `shelter_built = true`
- `scenes/world/thermal_generator_site.tscn`:
  - costs 8 wood + 4 fiber
  - sets `thermal_generator_built = true`, `power_capacity = 20.0`,
    `medbay_online = true`
- `scripts/world/harvest_node.gd` + scenes:
  - fallen branch → 3 wood, 40 s respawn
  - grass patch → 3 fiber, 40 s respawn
- Two of each near spawn.
- The build sites are **one-shot graybox flag setters**: no fuel, no charging time,
  no power simulation.

### 2.6 Tests

`tests/test_runner.gd` has **87 assertions**, including:

- autoloads and core systems
- pod 07 scene + dialogue + item
- berry bush harvest / eating / hunger
- geneticist pod initial lock
- shelter + thermal generator build chain
- geneticist unlock after the build chain

## 3. Designed but not implemented

| System | Design doc | Status |
|--------|-----------|--------|
| Full ship interior / energy bay | `story.md` §5 | designed |
| Cargo hold + glass tech-tree slides | `story.md` §5, `tech-archive.md` | designed |
| Geneticist wake sequence + NPC | `colonist-wake-chain.md` | designed |
| NPC experts + shared tech tree | `colonist-wake-chain.md`, `design.md` | designed |
| Research lab + plant P0–P8 | `plant-branch.md` | designed |
| Simple farming | `plant-branch.md` | designed |
| Thermal generator simulation (fuel/charge) | `story.md` §10 | designed |
| Power grid / solar / wind / nuclear | `story.md` §9 | designed |
| 3D printing | `design.md` | designed |
| AI assistant capabilities | `design.md` | designed |
| 4 km continent + ocean + deep sea | `story.md` §4 | designed |
| Human augmentation / biomechanical | `story.md`, `design.md` | designed |
| Shipyard / fleet / return | `story.md` §8 | designed |

## 4. Known limitations

- The world is a **graybox plane**, not the ship or the 4 km continent.
- Build sites set flags once; there is no resource drain, fuel, or charging loop.
- The geneticist cannot be woken; the pod is a requirement display.
- The AI is a subtitle system, not a voice-acted companion.
- Pod 07's power-gated follow-up and chip log have no triggers yet.
- No research lab, farming, cargo hold, tech archive, power grid, 3D printing,
  NPC schedules, shared tech, or fleet.
- There is no Seed CI. `gu check` is local.
- Export templates are machine-level, not in the repo.

## 5. How to verify

```bash
GU=/Users/huangyuan/Projects/game-utils/start.sh
SEED=/Users/huangyuan/Projects/seed

$GU check --project "$SEED"

# focused test run
/Applications/Godot.app/Contents/MacOS/Godot --headless --path "$SEED" \
  --script res://tests/test_runner.gd
```

Manual smoke:

1. Start a new game.
2. Walk to a berry bush, press `E`, press `H`.
3. Watch the hunger bar and the AI subtitle at 40% / 15%.
4. Gather wood/fiber from branches/grass; build the shelter and thermal generator.
5. Check the geneticist pod: all requirements should be met if you have 10 berries.

## 6. Next

See `ROADMAP.md` → **M2 / M3**. The immediate next tasks are:

1. Thermal generator fuel/charging simulation.
2. Geneticist wake sequence + placeholder NPC.
3. Research lab build site.
4. Plant P0 data table + first crop.
