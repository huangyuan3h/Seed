# Seed — Current State

> Snapshot: 2026-11-22. This file is the source of truth for **what exists now**.
> If a design doc describes something here as “not implemented”, it is not playable.

## 1. Gate

```
[PASS] addons-parity: 96 files in sync
[PASS] pytest: 34 passed            (game-utils' own Python suite)
[PASS] data-validate: 6 tables, 1 localization
[PASS] godot-import: exit=0
[PASS] godot-tests: 200 assertions
[PASS] godot-smoke: frames=30 exit=0
```

## 2. Implemented

### 2.1 Starter scaffold

- `scenes/main.tscn`: landing-site scene with procedural terrain, dawn environment,
  MultiMesh set dressing, `GuPlayer` (animated model), `CameraRig`, guide NPC.
- Title → main scene, pause/save/settings UI, sample quest `meet_guide`.
- 12 autoloads from `gu_core` + `gu_gameplay` components, plus Seed's `WorldTime`.

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
- HUD hunger bar via Seed's `VitalRow` inside `SeedHud`.
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

### 2.6 HUD shell + wrist computer

- `scripts/world/world_time.gd` (`WorldTime` autoload):
  - 30 real minutes per local day (24 in-game hours, 75 real seconds per hour).
  - Starts on `DAY 001` at `06:00`; day phases `dawn` / `day` / `dusk` / `night`.
  - `minute_changed`, `phase_changed`, `day_changed`; derives from `GameClock.world_seconds`.
  - Sleep API: `sleep_hours()` / `sleep_until()`; no forced sleep.
- `scenes/ui/hud.tscn` + `scripts/ui/hud/`:
  - Top bar: day, `HH:MM`, phase, night/dawn countdown; AI status.
  - Vitals: HP, hunger, stamina (`VitalRow`).
  - Objective: existing `QuestHud` at top-right.
  - Six-slot `Hotbar` with `1–6` selection and a selected-item/verb hint.
  - Four pinned resource chips (`wood`, `fiber`, `stone`, `wild_berry`).
  - Replaces `GameplayHud` usage; addon remains untouched.
- `scripts/ui/hud/hotbar_controller.gd`:
  - `1–6` select hotbar slots; `F` uses the selected item.
  - Tool tags drive actions: knife → `gather`, axe → `chop`, pickaxe → `mine`,
    mallet → `build`, weapon → `strike`; food → eat.
  - `F` on a focused berry bush / harvest node / build site calls `interact()`.
  - Legacy `1–4` action verbs and `F` repeat are released from `InputMap`.
  - New-game starting kit gives `emergency_knife`; `stone_axe`,
    `stone_pickaxe`, and `mallet` item definitions exist for later acquisition.
- `H` still eats a berry; selected food can also be used with `F`.
- `scenes/ui/wrist_computer.tscn` + `scripts/ui/wrist/wrist_computer.gd`:
  - Tabs `PACK` / `ARCHIVE` / `COLONY`; `I`, `T`, `Tab` open it.
  - Opening pauses the scene tree and `GameClock`; closing resumes in `PLAYING`.
  - PACK shows the live 16-slot inventory and item details.
  - ARCHIVE lists the six F1 factory tech fragments (read-only remote view).
  - COLONY is a placeholder until power/colony data exists.

### 2.7 Factory F1 (hand-fed)

- `data/content/items.json`: added the nine factory materials (`stone`, `iron_ore`,
  `copper_ore`, `coal`, `iron_plate`, `copper`, `mechanical_part`, `electrical_part`).
- `data/content/recipes.json` + schema: iron/copper smelting, mechanical/electrical parts.
- `data/content/tech.json` + schema: six tech nodes; Basic Automation costs 10 mechanical parts.
- `scripts/factory/`:
  - `factory_content.gd`: reads recipes/tech through `GameContent`.
  - `factory_state.gd`: unlocked techs + optional `FlagStore` mirror.
  - `factory_machine.gd`: buffers, recipe selection, power draw, timed production.
  - `research_bench.gd`: tech rows become recipes; completion unlocks the tech.
  - `factory_panel.gd`: hand-feeding UI (select recipe, insert 1/10, take output).
  - `factory_demo.gd`: self-contained F1 lab; spawns machines and starter materials.
- `scripts/power/power_grid.gd`: supply/demand/satisfaction ratio.
- `scripts/power/thermal_generator.gd`: real wood/coal generator, 20 power.
- `scenes/factory/factory_lab.tscn`: playable lab that instances `main.tscn` and adds the demo.
- Flow: add coal to generator → smelter (iron ore + coal) → workbench (plates → parts)
  → research bench (10 parts → Basic Automation).
- Tests cover items/recipes/tech, smelter/workbench production, power gating,
  research unlock, and generator fuel exhaustion.

Run the lab:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/huangyuan/Projects/seed \
  scenes/factory/factory_lab.tscn
```

### 2.8 Road logistics (F2)

- `scripts/logistics/road_network.gd`: grid BFS road graph with 90° turns and
  auto-built demo roads (player road placement is next).
- `scripts/logistics/logistics_station.gd`: input/output/fuel buffers, producer
  pull, consumer push, truck refuelling, 0.25 power draw.
- `scripts/logistics/steam_truck.gd`: first transport tier — 12 capacity, 4 m/s,
  coal/wood fuel, one item per route, pickup → dropoff → return.
- `scripts/logistics/logistics_panel.gd`: route editor (truck, pickup, dropoff,
  one item) plus “restore demo routes”.
- `scripts/factory/miner.gd`: power-hungry miner that turns an ore node into an
  item stream; `scripts/factory/ore_node.gd` is the visible deposit.
- `scripts/factory/factory_demo.gd`: `enable_logistics` mode adds two generators,
  iron/coal miners, five stations, four steam trucks and auto routes.
- `scenes/factory/factory_logistics_lab.tscn`: playable F2 lab.
- Flow: iron ore + coal → smelter → iron plates → workbench → mechanical parts →
  research bench → **Copper Working**; the line runs without hand-feeding.
- Tests cover road turns, station transfer, truck delivery/fuel, miner output,
  and an end-to-end simulation that unlocks Copper Working.

Run the F2 lab:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/huangyuan/Projects/seed \
  scenes/factory/factory_logistics_lab.tscn
```

### 2.9 Visual foundation (art pass)

- `scenes/world/seed_environment.tscn` + `scripts/world/seed_environment.gd`:
  procedural sky, distance/height fog, SSAO, glow, ACES tonemap; the sun and moon
  arcs follow `WorldTime` (dawn/day/dusk/night), and the player headlight switches
  on when `get_night_factor()` rises.
- `scenes/world/landscape.tscn` + `scripts/world/landscape.gd`:
  deterministic 300×300 m low-poly heightfield with a **flat 24 m play centre**,
  bilinear `sample_height()` for `GuPlayer`, an impact shelf under the wreck,
  vertex-coloured ground and a procedural ground shader (dry patches, worn pad,
  slope rock).
- `scripts/world/world_art.gd`: seeded MultiMesh set dressing — ~26k grass tufts,
  wildflowers, shrubs, boulders, pines and broadleaf trees, all outside a
  14–27 m clear ring so the graybox interactions stay readable.
- Authored model kit `assets/models/seed/` (generated by `tools/blender/build_seed_assets.py`):
  `prop_pod_07.glb` is instanced for Pod 07, and `prop_shelter.glb` /
  `prop_thermal_generator.glb` replace the built-state graybox meshes. Trees, rocks, berry bush
  and HUD icons are still procedural/unwired; the authored ship rib is instanced
  as wreck debris. See `assets/models/seed/README.md` and `docs/art/`.
- `scenes/world/crashed_ship.tscn` + `scripts/world/crashed_ship.gd`:
  distant ring-and-hull wreck silhouette on the horizon, amber emergency beacon,
  vine strips; it sits on a flattened crash shelf.
- Player uses the CC0 Quaternius `AnimatedHuman.fbx`
  (`assets/models/quaternius/`, license included) with a tinted undersuit material and a
  backpack so the placeholder rig reads as a suited colonist; the debug `NameLabel`
  is hidden.
- Guide NPC gets a cloak/head/pack/staff pass over the shared auto-generated visual.
- Pod 07 and the geneticist pod get a ceramic body, glass frame, rails, base,
  vents and feet; glass colour stays diagnostic (red = anomaly, blue = sleeper).
- Title screen: `assets/art/title_key_art.svg` vector key art plus Seed tagline;
  `TITLE_TAG` / `TITLE_TAGLINE` are localized.
- `docs/art-direction.md` records palette, shape language, lighting, materials,
  asset pipeline, and the next asset list.
- `tools/blender/build_seed_assets.py` generates an authored low-poly kit into
  `assets/models/seed/` (pod 07, thermal generator, shelter, berry bush, two trees,
  rock, hull rib) plus five 256 px item icons in `assets/art/icons/`. The kit is
  **partly instanced**: Pod 07, shelter, thermal generator and hull rib are in
  scenes; trees, rocks and berry bush still use the procedural pass above.

**Visual limits:** the terrain is a 300 m landing patch, not the M6 4 km continent;
the wreck is a distant silhouette, not a walkable interior; foliage and rocks are
still procedural stand-ins in-scene even though authored replacements now exist on
disk.

### 2.10 Ship blockout (first subset)

- `tools/blender/build_ship_models.py` (Blender 5.2 headless) generates 28 low-poly
  glTF assets under `assets/models/ship/`:
  - `kit/`: floor/wall/ceiling tiles, 8 m corridor, 12 m junction, 8×6 m airlock.
  - `props/`: cryo pod + broken Pod 07 variant, suit rack, autodoc, med screen,
    tool locker, console, crate, shelf, cable tray, pipe run, light strip, railing,
    vent, battery rack, stairs, bulkhead door, sealed door.
  - `sections/`: 64×30×7.5 m cryo bay shell and 16×12×4.5 m med bay shell.
  - `exterior/`: ~1.28 km crashed hull (80 m ring, radiators, cargo pods, landing
    legs, breach) and a breach ramp.
- `tools/godot/generate_ship_scenes.py` assembles the first connected subset:
  - `scenes/ship/sections/cryo_bay.tscn`: 24 pod instances (including broken Pod 07),
    suit rack, tool locker, console, crates, cryo lighting.
  - `scenes/ship/sections/med_bay.tscn`: autodoc, med screen, locker, console, vents.
  - `scenes/ship/sections/spine_corridor.tscn`: junction, three 8 m corridors,
    airlock, sealed energy-bay door + collision, door leaves, pipes, cable tray.
  - `scenes/ship/ship_interior.tscn`: connects the three sections in a loop.
  - `scenes/ship/ship_exterior.tscn`: hull, breach ramp, ground/hull collision,
    breach light. The hull is a landmark, not walkable.
  - Preview scenes `ship_preview.tscn` and `ship_exterior_preview.tscn` include a
    simple walk controller, third-person camera, inspection points, and a working
    interior ↔ exterior transition at the D3 airlock/breach.
  - The landing-site scene has a `ShipEntry` transition at the crashed wreck
    (`-40, 1.2, -55`) → `ship_preview.tscn`.
- Regenerate everything:

```bash
blender -b --python tools/blender/build_ship_models.py -- all
python3 tools/godot/generate_ship_scenes.py
```

- Preview:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/huangyuan/Projects/seed \
  scenes/ship/ship_preview.tscn
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/huangyuan/Projects/seed \
  scenes/ship/ship_exterior_preview.tscn
```

**Blockout limits:** the previews are **not wired into the title/new-game flow or the
opening sequence**. Props have no interaction/dialogue, there is no save state for
ship sections, lighting is placeholder, and only S0–S3 exist; energy bay, cargo hold,
bridge, sample vault and engineering remain sealed/not modeled. The exterior hull is
a low-poly landmark with coarse collision, not the final art.

### 2.11 Item icon layer

- `scripts/ui/item_icons.gd` (`ItemIcons`): resolves authored icons from
  `data/content/item_icons.json`, caches them, and generates deterministic 64 px
  fallback glyphs from item tags when no PNG exists.
- Authored 256 px icons: wood, fiber, wild berry, data chip, water
  (`assets/art/icons/`). Fallback categories: food, tool, ore, plate, part,
  fuel, data, wood, fiber, stone, coin, generic.
- Every `ItemDef.icon` is populated when items are registered in `scripts/main.gd`,
  so any future inventory panel can render icons without extra wiring.
- Wired UI: wrist `PACK` grid (icon + name + count), item detail 52 px icon,
  bottom pinned-resource chips (20 px icon + count), and the six-slot hotbar
  (24 px icon + name + count, selected slot highlighted).
- Docs: `docs/item-icons.md` (rules, mapping table, fallbacks, adding icons).

### 2.12 Tests

`tests/test_runner.gd` has **200 assertions**, including:

- autoloads and core systems
- `WorldTime` clock/phase/sleep behavior
- pod 07 scene + dialogue + item
- berry bush harvest / eating / hunger
- geneticist pod initial lock
- shelter + thermal generator build chain
- geneticist unlock after the build chain
- Seed HUD bindings and wrist pause/resume
- hotbar selection, tool→action mapping, selected-food use, focused knife harvest
- visual scaffold (landscape, set dressing, dawn environment, player art model, title key art)
- item icon resolution (authored PNG + procedural fallback)
- factory items/recipes/tech, smelter/workbench production, power gating, research unlock
- road BFS turns, station transfer, steam truck delivery/fuel, miner output, end-to-end F2 line
- ship blockout scenes load, interior subset connects, sealed door exists,
  exterior hull > 1 km, preview player/camera exist, inspection points and
  interior ↔ exterior transitions exist, landing-site ship entry exists

## 3. Designed but not implemented

| System | Design doc | Status |
|--------|-----------|--------|
| Full ship interior / energy bay | `ship-structure.md`, `story.md` §5 | designed |
| Cargo hold + glass tech-tree slides | `story.md` §5, `tech-archive.md` | designed |
| Unified tech tree: 5 phases / 7 branches / 18 spine + ~64 branch nodes | `tech-tree.md` | designed |
| Ship exterior landmark + interior subset + modular model kit | `ship-structure.md` | **blockout implemented (S0–S3)**; rest designed |
| Geneticist wake sequence + NPC | `colonist-wake-chain.md` | designed |
| NPC experts + shared tech tree | `colonist-wake-chain.md`, `design.md`, `tech-tree.md` | designed |
| Research lab + plant P0–P8 | `plant-branch.md` | designed |
| Simple farming | `plant-branch.md` | designed |
| Thermal generator simulation (fuel/charge) | `story.md` §10, `thermal-power.md` | F1 real generator in lab; main build site still flag-only |
| Chapter 1 tool chain + wrist printer | `chapter-1-tools.md` | designed |
| Simplified factory + road logistics (steam/electric/field fleet) | `factory-loop.md` | **F1 + F2 labs implemented**; F3 electric/copper next |
| Material ladder, salvage, ore processing | `materials-and-industry.md` | designed |
| Ship energy / beam road / continuation refit | `ship-energy.md` | designed |
| Power grid / solar / wind / nuclear | `story.md` §9 | designed |
| 3D printing | `design.md` | designed |
| AI assistant capabilities | `design.md` | designed |
| 4 km continent + ocean + deep sea | `story.md` §4 | designed |
| Human augmentation / biomechanical | `story.md`, `design.md` | designed |
| Shipyard / fleet / return | `story.md` §8 | designed |

## 4. Known limitations

- The world is a **300 m procedural landing patch** (flat 24 m play centre), not the
  4 km continent; the wreck is still the distant art-pass silhouette.
- The ship blockout lives in **separate preview scenes** (`scenes/ship/`); the landing
  site has an entry transition at the wreck, but new game still starts at the landing
  site and the opening sequence is not wired. Only S0–S3 exist.
- Ship props have short inspection toasts, not full dialogue; ship section state is
  not saved. Interior ↔ exterior transitions reload at default spawns, not at the
  door the player used.
- Main build sites still set flags once; the F1 lab has a real generator/power loop,
  but it is not wired into the main build sites yet.
- The geneticist cannot be woken; the pod is a requirement display.
- The AI is a subtitle system, not a voice-acted companion.
- Pod 07's power-gated follow-up and chip log have no triggers yet.
- The factory labs are standalone F1/F2 scenes; they are not yet merged into the main scene.
- Factory F1/F2 UI/item names are English-only; localization is pending.
- F2 roads are auto-built for the demo; player road placement is not implemented yet.
- F2 only has steam trucks; electric charging (F3) and field charging (F4) are next.
- Truck/station buffers are not saved yet.
- `data/content/tech.json` is a 6-node F1 slice; the full `tech_nodes` tree in
  `tech-tree.md` is not migrated yet.
- No research lab, farming, cargo hold, tech archive data/service, 3D printing,
  NPC schedules, shared tech, or fleet (the F1 research bench is a prototype).
- Hotbar selection/use is one press; holding `F` to loop an action is not wired yet.
- Axe / pickaxe / mallet are data-only items; there is no crafting or printer path yet.
- Tool gates on harvest nodes/build sites exist but are empty by default, so `E`
  still works without a tool.
- The controls screen still lists the old gather/mine/chop/build/repeat actions;
  their keys are intentionally blank while the new hotbar verbs own `1–6` and `F`.
- Wrist `ARCHIVE` is read-only and lists only the six F1 factory techs; no glass-slide
  archive or progress tracking yet. `COLONY` is still a placeholder.
- No suit battery/temperature simulation; vitals currently show HP, hunger, stamina.
- No sleep UI yet; `WorldTime.sleep_until()` exists but is not exposed in-game.
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
6. Check the top bar clock (`DAY 001`, `06:00`, `DAWN`) and the night countdown.
7. Press `I` / `T` / `Tab`: the wrist opens, the world pauses; `Esc` closes and resumes.

Ship blockout smoke:

1. Run `res://scenes/ship/ship_preview.tscn`.
2. Walk from the cryo bay through the north door, into the junction, then north
   to the med bay and east to the airlock.
3. Check Pod 07 (red light, `07 // OCCUPIED`), the suit rack, autodoc, and the
   sealed west door in the junction.
4. Run `res://scenes/ship/ship_exterior_preview.tscn`; walk toward the hull and
   up the breach ramp.

## 6. Next

See `ROADMAP.md` → **M2 / M3 / UI**. The immediate next tasks are:

1. Thermal generator fuel/charging simulation.
2. Geneticist wake sequence + placeholder NPC.
3. Research lab build site.
4. Plant P0 data table + first crop.
5. UI-3: PACK item actions/equipment; hotbar selection/use is done (UI-3.5).
6. UI-4/5: replace ARCHIVE / COLONY placeholders when tech and power data exist.
7. Wire the ship blockout into the new-game/opening flow (T4.1a).
8. Add ship prop interaction and the Pod 07 dialogue bridge (T4.1b).
