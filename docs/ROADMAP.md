# Seed — Roadmap

> Living plan. `STATE.md` is what exists; this file is what comes next.
> Pick a **Ready** task, claim it, keep it small, and update this file when done.

## 1. Milestones

| ID | Milestone | Status | Exit criteria |
|----|-----------|--------|---------------|
| M0 | Scaffold + gate | Done | `gu check` green on the starter project |
| M1 | First hour: hunger / forage / berries | Done (graybox) | hunger decays, berries harvest, `H` eats, AI thresholds |
| M2 | Shelter + thermal generator + wake geneticist | **In progress** | build shelter/generator, flags/power set, geneticist wake sequence |
| M2.5 | **Simplified factory + road logistics** | **F1 + F2 done; F3 next** | hand-fed machine loop → road + steam trucks → auto line → 6 tech nodes |
| M3 | Research lab + plant P0–P2 + simple farming | Planned | geneticist researches slides/samples, first crop harvest |
| M4 | Ship exterior landmark + interior subset + energy bay / cargo hold | **In progress (S0–S3 blockout + interactions)** | 1.24 km exterior, connected cryo/med/corridor/breach, sealed S4+, glass slides |
| M5 | NPC experts + shared tech tree | Planned | 5+1 roster, branch ownership, 2+ expert shared nodes |
| M6 | 4 km continent + ocean layers | Planned | terrain, shallow/deep sea, giant-octopus boundary |
| M7 | Industry / nuclear / orbital shipyard / relay / fleet | Planned | power tiers, manufacturing, orbital shipyard, relay repair, fleet |
| M8 | Human augmentation + continuation endgame | Optional | augmentation tiers, continue/share/stay choice |

## 2. Current milestone: M2

### Done

- Food/hunger loop.
- Pod 07 anomaly + dialogue + data chip.
- Geneticist pod locked + requirement display.
- Shelter build site (5 wood + 3 fiber → `shelter_built`).
- Thermal generator build site (8 wood + 4 fiber → `thermal_generator_built`,
  `power_capacity = 20`, `medbay_online = true`).
- Wood/fiber harvest nodes.
- Visual foundation: procedural 300 m landing site, dawn sky/fog, MultiMesh foliage,
  animated player model, pod detailing, title key art (`art-direction.md`).

### Ready

T2.1 design: [`thermal-power.md`](thermal-power.md).

| ID | Task | Files | Acceptance |
|----|------|-------|------------|
| T2.1 | Thermal generator fuel/charging simulation | `scripts/power/`, `scripts/world/thermal_generator_site.gd` | generator consumes fuel, charges `power_capacity` over time, HUD/AI feedback |
| T2.2 | Geneticist wake sequence + placeholder NPC | `scripts/colony/`, `scenes/world/`, `data/content/dialogue.json` | interact when ready → wake animation/dialogue → NPC appears, `geneticist_awake` flag |
| T2.3 | Research lab build site | `scenes/world/research_lab.tscn`, `scripts/world/build_site.gd` | costs power/materials, sets `research_lab_built`, AI hint |
| T2.4 | Save/load verification for hunger + build flags | `tests/test_runner.gd`, `scripts/survival/` | save/load preserves hunger, shelter, generator, pod state |
| T2.5 | AI hint bus consolidation | `scripts/ship_ai/` | all hints go through one cooldown/priority system |
| T2.6 | Tool + printer data layer | `data/content/tools.json`, `data/content/patterns.json`, `scripts/tools/` | schema valid; printing consumes feedstock/battery; tests cover |
| T2.7 | Tree + axe gate | `scripts/world/tree.gd`, `scenes/world/tree.tscn` | no axe → hint; axe → timber + wood; stump remains |
| T2.8 | Bark container + water | `scripts/world/water_source.gd`, `scripts/tools/` | container holds 3 water; generator hints when water missing |
| T2.9 | Generator tool/resource gate | `scripts/world/build_site.gd`, `scenes/main.tscn` | missing timber/water/mallet gives clear hints; build consumes them |

### Blocked

| Task | Blocked by |
|------|------------|
| Research lab power draw | T2.1 power simulation |
| Geneticist research UI | T2.2 wake + T2.3 lab |
| Simple farming | T3.1 plant P0 |

## 2.5 M2.5 — Simplified factory + road logistics

Design: [`factory-loop.md`](factory-loop.md).

**Goal:** prove the core loop — hand-feed machines, then build a road and one
**steam truck**, then let the line run itself. Nine materials, six tech nodes.
Electric trucks and field charging are F3/F4.

**F1 status:** implemented in `scenes/factory/factory_lab.tscn`; see `STATE.md` §2.7.
**F2 status:** implemented in `scenes/factory/factory_logistics_lab.tscn`; see `STATE.md` §2.8.
F3 (copper/electrical + electric trucks) is the next vertical slice.

| ID | Task | Files | Acceptance |
|----|------|-------|------------|
| F1.1 | Item + recipe data | `data/content/items.json`, `data/content/recipes.json` + schema | 5 raw + 4 processed items; recipes validate |
| F1.2 | Machine base | `scripts/factory/machine.gd` | input/output buffers, recipe selection, power draw, tick |
| F1.3 | Smelter / workbench / research bench | `scripts/factory/`, `scenes/factory/` | hand-feed → plates → parts → tech progress |
| F1.4 | Tech table + unlock flags | `data/content/tech.json` + schema, `scripts/tech/` | 6 nodes; research consumes parts; unlocks machines |
| F1.5 | Thermal generator as a real machine | `scripts/power/`, `scripts/world/thermal_generator_site.gd` | burns wood/coal; supplies 20 power; satisfaction ratio |
| F1.6 | F1 tests | `tests/test_runner.gd` | recipe, power, research consumption/unlock |
| F2.1 | Road network + placement | `scripts/logistics/road_network.gd` | grid road graph, 90° turns, demo auto-build |
| F2.2 | Logistics station | `scripts/logistics/logistics_station.gd` | input/output buffers, producer/consumer links, fuel slot |
| F2.3 | Steam truck | `scripts/logistics/steam_truck.gd` | path following, load/unload, one route, coal/wood fuel, wait reasons |
| F2.4 | Route UI | `scripts/logistics/logistics_panel.gd` | pick truck → pickup → dropoff → one item; assign |
| F2.5 | Miner + ore nodes | `scripts/factory/miner.gd`, `scripts/factory/ore_node.gd` | power draw, ore output, blocked feedback |
| F2.6 | F2 tests | `tests/test_runner.gd` | truck moves cargo; station buffers; auto line unlocks Copper Working |
| F3.1 | Copper + electrical parts | `data/content/items.json`, recipes | copper ore → copper → electrical parts |
| F3.2 | Tech 2–3 | `data/content/tech.json` | copper working; electrical engineering; AI routing |
| F3.3 | Electric truck + charging | `scripts/logistics/`, `scenes/logistics/charger.tscn` | battery, low-battery return, charge at station, power draw |
| F3.4 | F3 tests | `tests/test_runner.gd` | two research inputs; power satisfaction slows fleet; charge queue |
| F4.1 | Field tower + field charging | `scripts/logistics/field_tower.gd` | radius, power draw, vehicles recharge inside field |
| F4.2 | Heavy hauler + warehouse | `scripts/logistics/`, `scenes/logistics/warehouse.tscn` | capacity 50; buffer storage; route priority |
| F4.3 | AI route suggestions | `scripts/ship_ai/`, `scripts/logistics/` | Mira suggests a route when a station is starved |

### Blocked

| Task | Blocked by |
|------|------------|
| Road/truck implementation | F1 machine + power loop |
| AI route suggestions | F2 route UI + electrical engineering |
| Multiple factory sites | F2 road graph + M6 terrain |

## 3. M3 — Research lab + plant branch

| ID | Task | Files | Acceptance |
|----|------|-------|------------|
| T3.1 | Plant P0 seed survey | `data/content/tech.json`, `data/content/crops.json`, `scripts/tech/` | analyzing 3 seed batches fills P0 %, unlocks greenhouse |
| T3.2 | Greenhouse build site | `scenes/world/greenhouse.tscn` | power + water + printed modules; first test crop |
| T3.3 | First crop / farm plot | `scripts/agriculture/`, `scenes/world/farm_plot.tscn` | plant, grow, harvest, hunger restore |
| T3.4 | Simple farming UI | `scenes/ui/farm_panel.tscn` | crop selection, water/soil, harvest |
| T3.5 | Geneticist dialogue + research hints | `data/content/dialogue.json` | AI/geneticist comments on P0/P1 progress |

## 4. M4 — Large ship + tech archive

Design: [`ship-structure.md`](ship-structure.md) (sections, scenes, kit, budgets),
[`tech-tree.md`](tech-tree.md) (node rules, slides, archive sections), and
[`tech-archive.md`](tech-archive.md) (cargo hold discovery).

### Done (blockout)

- T4.0 exterior hull + breach ramp: `scenes/ship/ship_exterior.tscn` / preview.
- T4.1 interior subset: cryo bay + med bay + spine corridor + sealed energy door,
  connected; `scenes/ship/ship_preview.tscn`.
- T4.1b inspection points: Pod 07, suit rack, locker, med screen, autodoc,
  sealed door; airlock ↔ breach scene transition; landing-site `ShipEntry`.
- 28 generated GLBs under `assets/models/ship/`; scene assembly in
  `tools/godot/generate_ship_scenes.py`.

| ID | Task | Files | Acceptance |
|----|------|-------|------------|
| T4.1a | Wire ship blockout into new game/opening | `scripts/main.gd`, `scenes/ship/`, `scenes/main.tscn` | new game spawns in cryo bay; breach transitions to exterior; no duplicate player/world |
| T4.1b | **Done (blockout)**: ship prop inspection + transitions | `scripts/ship/`, `scenes/ship/` | Pod 07, suit rack, med screen, sealed door and airlock give feedback; interior ↔ exterior works |
| T4.2 | Energy bay | `scenes/ship/energy_bay.tscn`, `scripts/power/` | built-in batteries/generation, section unlock |
| T4.3 | Cargo hold + glass slides | `scenes/ship/cargo_hold.tscn`, `scripts/tech/` | AI hint, collectible slides, missing archive |
| T4.4 | Tech archive state | `scripts/tech/archive_state.gd` | slides unlock nodes; missing branches tracked |
| T4.5 | Cargo hold discovery scene | `data/content/dialogue.json` | AI guides player; “the cargo is still here — the road is gone” reveal |

## 5. M5 — NPC experts + shared tech

Design: [`tech-tree.md`](tech-tree.md) §4–§7, [`colonist-wake-chain.md`](colonist-wake-chain.md).

| ID | Task | Files | Acceptance |
|----|------|-------|------------|
| T5.1 | Colonist data table | `data/content/colonists.json` + schema | 5+1 roster with branches, requirements, wake dialogue |
| T5.2 | Tech ownership model | `data/content/tech.json` + schema | nodes carry `owners` / `shared` / `min_owners` / `fallback_owners` |
| T5.3 | NPC work schedules | `scripts/colony/npc_*.gd` | experts move between lab/workshop/farm |
| T5.4 | Shared tech gate | `scripts/tech/` | required owners awake + facility + power; paused nodes keep %; fallback at 0.5× |
| T5.5 | Expert collaboration UI | `scenes/ui/tech_tree.tscn` | assign experts, see contribution % |
| T5.6 | Full tech tree data + validator | `data/content/tech.json`, `data/content/slides.json`, `scripts/tech/tech_validator.gd` | 18 spine + ~64 branch nodes; weights sum 100; no cycles; spine never depends on branch; critical slides guaranteed |

## 6. M6 — World map

| ID | Task | Files | Acceptance |
|----|------|-------|------------|
| T6.1 | 4 km terrain prototype | `scripts/map/`, `scripts/terrain/` | seeded continent + shallow/deep sea |
| T6.2 | Ocean boundary | `scripts/world/` | shallow sailing, deep-sea warning, giant-octopus boundary |
| T6.3 | Landing-site biome | `scenes/world/` | water, berries, grass, rabbit trails, shelter sites |
| T6.4 | Deterministic world seed | `scripts/main.gd`, save | same seed → same world; critical POIs guaranteed |

## 7. M7 — Industry / fleet

| ID | Task | Acceptance |
|----|------|------------|
| T7.1 | Power grid tiers | thermal → solar/wind → geothermal/hydro → nuclear |
| T7.2 | 3D printing tiers | items → modules → industrial → shipyard |
| T7.3 | Manufacturing | materials + robotics + shared tech |
| T7.4 | Shipyard | construction + materials + robotics |
| T7.5 | Fleet / return: ~100 years at 0.4c; home is ~200 years older; the same near-immortal elites may still be in power | all core experts + AI, endgame choice |
| T7.6 | Beam relay repair / return launch infrastructure | repair destination relay + ship drive; refit the seeding ship, not a new fleet |

## 8. Parallel work streams

Multiple agents can work at once if they stay in separate areas:

| Stream | Owns | Avoid |
|--------|------|-------|
| A. Survival / power | `scripts/survival/`, `scripts/world/`, `scripts/power/` | ship interior, tech tree data |
| B. Ship / archive | `scenes/ship/`, `scripts/tech/`, `scenes/world/cargo*` | hunger, build sites |
| C. Colonists / tech data | `data/content/colonists.json`, `data/content/tech.json`, `scripts/colony/` | survival code |
| D. Content / i18n / tests | `data/content/*.json`, `data/ui_i18n.csv`, `tests/` | gameplay scripts |
| E. World / terrain | `scripts/map/`, `scripts/terrain/`, ocean | colony systems |
| F. Visual / art | `assets/`, `scenes/world/landscape.tscn`, `world_art.tscn`, `seed_environment.tscn`, `crashed_ship.tscn` | gameplay scripts, data tables |
| F. UI / HUD | `scenes/ui/hud.tscn`, `scenes/ui/wrist_computer.tscn`, `scripts/ui/`, `scripts/world/world_time.gd` | gameplay systems, addons |

### UI / HUD workstream

Design: [`ui-hud.md`](ui-hud.md). UI work can start in parallel; each phase is
independently shippable.

| ID | Status | Task | Files | Acceptance |
|----|--------|------|-------|------------|
| UI-1 | **Done** | Time service + clock widget | `scripts/world/world_time.gd`, `scenes/ui/hud.tscn` | day/hour/phase derived from `GameClock`; save/load correct; tests |
| UI-2 | **Done** | HUD shell: vitals, objective, hotbar, pinned resources, prompt/AI re-layout | `scenes/ui/hud.tscn`, `scripts/ui/hud/` | no overlap at 1280×720 / 1024×576; replaces `GameplayHud` usage |
| UI-3 | **Partial** | Wrist terminal + pack/equipment | `scenes/ui/wrist_computer.tscn`, `scripts/ui/wrist/` | `I`/`Tab`/`Esc` behave; inventory no longer a centered modal |
| UI-3.5 | **Done** | Hotbar selection + tool-driven action keys | `scripts/ui/hud/hotbar.gd`, `scripts/ui/hud/hotbar_controller.gd` | `1–6` select, `F` uses; old `1–4` verbs released; tests |
| UI-4 | **Partial** | Archive/tech panel | `scripts/ui/wrist/wrist_computer.gd`, `scripts/tech/` | six F1 tech rows are read-only; branch/node/source/slide states still pending |
| UI-5 | Blocked | Colony dashboard (overview/resources/power) | `scripts/ui/wrist/colony_screen.gd` | numbers match runtime; depends T2.1/F1.5 |
| UI-6 | Blocked | Logistics route UI | `scripts/ui/wrist/logistics_screen.gd` | assign pickup → dropoff → item; depends F2.4 |

The wrist shell is implemented. `ARCHIVE` lists the six F1 tech fragments (read-only);
`COLONY` is still a placeholder. UI-3 (pack/equipment) is partly done; UI-3.5 is done.

Coordination rules:

- Claim the task row before starting.
- Do not edit another stream's files without agreement.
- Shared files (`scripts/main.gd`, `scenes/main.tscn`, `tests/test_runner.gd`,
  `docs/STATE.md`, `docs/ROADMAP.md`) need small, coordinated edits.
- If a change affects multiple streams, split it into sequential tasks.

## 9. Task template

```md
### T?.? — Title

- Goal:
- Files:
- Depends on:
- Acceptance:
- Tests:
- Docs to update:
```

## 10. Definition of done

See `AGENTS.md` §5. In short: code + content + i18n + tests + docs + `gu check` green.
