# Seed — Roadmap

> Living plan. `STATE.md` is what exists; this file is what comes next.
> Pick a **Ready** task, claim it, keep it small, and update this file when done.

## 1. Milestones

| ID | Milestone | Status | Exit criteria |
|----|-----------|--------|---------------|
| M0 | Scaffold + gate | Done | `gu check` green on the starter project |
| M1 | First hour: hunger / forage / berries | Done (graybox) | hunger decays, berries harvest, `H` eats, AI thresholds |
| M2 | Shelter + thermal generator + wake geneticist | **In progress** | build shelter/generator, flags/power set, geneticist wake sequence |
| M3 | Research lab + plant P0–P2 + simple farming | Planned | geneticist researches slides/samples, first crop harvest |
| M4 | Ship interior + energy bay + cargo hold / tech archive | Planned | interior graybox, energy section, cargo hold with glass slides |
| M5 | NPC experts + shared tech tree | Planned | 5+1 roster, branch ownership, 2+ expert shared nodes |
| M6 | 4 km continent + ocean layers | Planned | terrain, shallow/deep sea, giant-octopus boundary |
| M7 | Industry / nuclear / shipyard / fleet | Planned | power tiers, manufacturing, shipyard, launch |
| M8 | Human augmentation + endgame | Optional | augmentation tiers, return/share choice |

## 2. Current milestone: M2

### Done

- Food/hunger loop.
- Pod 07 anomaly + dialogue + data chip.
- Geneticist pod locked + requirement display.
- Shelter build site (5 wood + 3 fiber → `shelter_built`).
- Thermal generator build site (8 wood + 4 fiber → `thermal_generator_built`,
  `power_capacity = 20`, `medbay_online = true`).
- Wood/fiber harvest nodes.

### Ready

T2.1 design: [`thermal-power.md`](thermal-power.md).

| ID | Task | Files | Acceptance |
|----|------|-------|------------|
| T2.1 | Thermal generator fuel/charging simulation | `scripts/power/`, `scripts/world/thermal_generator_site.gd` | generator consumes fuel, charges `power_capacity` over time, HUD/AI feedback |
| T2.2 | Geneticist wake sequence + placeholder NPC | `scripts/colony/`, `scenes/world/`, `data/content/dialogue.json` | interact when ready → wake animation/dialogue → NPC appears, `geneticist_awake` flag |
| T2.3 | Research lab build site | `scenes/world/research_lab.tscn`, `scripts/world/build_site.gd` | costs power/materials, sets `research_lab_built`, AI hint |
| T2.4 | Save/load verification for hunger + build flags | `tests/test_runner.gd`, `scripts/survival/` | save/load preserves hunger, shelter, generator, pod state |
| T2.5 | AI hint bus consolidation | `scripts/ship_ai/` | all hints go through one cooldown/priority system |

### Blocked

| Task | Blocked by |
|------|------------|
| Research lab power draw | T2.1 power simulation |
| Geneticist research UI | T2.2 wake + T2.3 lab |
| Simple farming | T3.1 plant P0 |

## 3. M3 — Research lab + plant branch

| ID | Task | Files | Acceptance |
|----|------|-------|------------|
| T3.1 | Plant P0 seed survey | `data/content/tech.json`, `data/content/crops.json`, `scripts/tech/` | analyzing 3 seed batches fills P0 %, unlocks greenhouse |
| T3.2 | Greenhouse build site | `scenes/world/greenhouse.tscn` | power + water + printed modules; first test crop |
| T3.3 | First crop / farm plot | `scripts/agriculture/`, `scenes/world/farm_plot.tscn` | plant, grow, harvest, hunger restore |
| T3.4 | Simple farming UI | `scenes/ui/farm_panel.tscn` | crop selection, water/soil, harvest |
| T3.5 | Geneticist dialogue + research hints | `data/content/dialogue.json` | AI/geneticist comments on P0/P1 progress |

## 4. M4 — Large ship + tech archive

| ID | Task | Files | Acceptance |
|----|------|-------|------------|
| T4.1 | Ship interior graybox | `scenes/ship/`, `scripts/ship/` | hibernation bay → med bay → corridor → energy bay → cargo hold |
| T4.2 | Energy bay | `scenes/ship/energy_bay.tscn`, `scripts/power/` | built-in batteries/generation, section unlock |
| T4.3 | Cargo hold + glass slides | `scenes/ship/cargo_hold.tscn`, `scripts/tech/` | AI hint, collectible slides, missing archive |
| T4.4 | Tech archive state | `scripts/tech/archive_state.gd` | slides unlock nodes; missing branches tracked |
| T4.5 | Cargo hold discovery scene | `data/content/dialogue.json` | AI guides player; “they dumped the archive” reveal |

## 5. M5 — NPC experts + shared tech

| ID | Task | Files | Acceptance |
|----|------|-------|------------|
| T5.1 | Colonist data table | `data/content/colonists.json` + schema | 5+1 roster with branches, requirements, wake dialogue |
| T5.2 | Tech ownership model | `data/content/tech.json` + schema | nodes carry `owners` / `shared` |
| T5.3 | NPC work schedules | `scripts/colony/npc_*.gd` | experts move between lab/workshop/farm |
| T5.4 | Shared tech gate | `scripts/tech/` | 2+ owners awake + facility → shared node unlocks |
| T5.5 | Expert collaboration UI | `scenes/ui/tech_tree.tscn` | assign experts, see contribution % |

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

## 8. Parallel work streams

Multiple agents can work at once if they stay in separate areas:

| Stream | Owns | Avoid |
|--------|------|-------|
| A. Survival / power | `scripts/survival/`, `scripts/world/`, `scripts/power/` | ship interior, tech tree data |
| B. Ship / archive | `scenes/ship/`, `scripts/tech/`, `scenes/world/cargo*` | hunger, build sites |
| C. Colonists / tech data | `data/content/colonists.json`, `data/content/tech.json`, `scripts/colony/` | survival code |
| D. Content / i18n / tests | `data/content/*.json`, `data/ui_i18n.csv`, `tests/` | gameplay scripts |
| E. World / terrain | `scripts/map/`, `scripts/terrain/`, ocean | colony systems |

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
