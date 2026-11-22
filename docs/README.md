# Seed — Documentation

> Godot 4.6 survival / colony game. Scaffolded from `game-utils` v0.2.0 (`d50ea22`).
> Last updated: 2026-11-22.
>
> **Language split:** creative docs are written in Chinese; engineering docs
> (`AGENTS.md`, `STATE.md`, `ROADMAP.md`, `DECISIONS.md`) are in English so other
> agents and tools can work from them directly.

## Start here

Read in this order depending on what you need:

| # | Document | Why |
|---|----------|-----|
| 1 | [`STATE.md`](STATE.md) | What is actually implemented **right now** |
| 2 | [`story.md`](story.md) | Canon: world, characters, ship, hidden backstory |
| 3 | [`story-spine.md`](story-spine.md) | Four-act narrative spine, mysteries, endings |
| 4 | [`story-timeline.md`](story-timeline.md) | 180-year timeline, coup, crash, AI memory, continuation |
| 5 | [`cast.md`](cast.md) | Names, gender, personality, hobbies, relationships |
| 6 | [`design.md`](design.md) | Design pillars and the Factorio comparison |
| 7 | [`tech-tree.md`](tech-tree.md) | **Tech tree design**: 5 phases, 7 branches, node rules, shared tech, slides |
| 8 | [`ui-hud.md`](ui-hud.md) | Game UI: time, resources, pack, tech archive, colony, notifications |
| 9 | [`first-phase-food.md`](first-phase-food.md) | First-hour food / foraging / trap loop |
| 10 | [`chapter-1-tools.md`](chapter-1-tools.md) | Chapter 1 tools, printer, verbs, first tree/power |
| 11 | [`factory-loop.md`](factory-loop.md) | **Gameplay loop**: materials → roads → steam/electric/field fleet → tech |
| 12 | [`thermal-power.md`](thermal-power.md) | Thermal generator components and tech unlocks |
| 13 | [`materials-and-industry.md`](materials-and-industry.md) | Material ladder, salvage, mining, orbital fleet |
| 14 | [`ship-energy.md`](ship-energy.md) | 0.4c energy, beam road, reactor, confirmed decisions |
| 15 | [`ship-structure.md`](ship-structure.md) | **Ship structure, scene layout, and model kit** |
| 16 | [`colonist-wake-chain.md`](colonist-wake-chain.md) | Roster, wake requirements, shared tech |
| 17 | [`plant-branch.md`](plant-branch.md) | Geneticist's plant branch (P0–P8) |
| 18 | [`tech-archive.md`](tech-archive.md) | Cargo hold, glass slides, road-cut archive |
| 19 | [`opening.md`](opening.md) | Opening storyboard (wake → first exterior) |
| 20 | [`anomaly-01-empty-pod.md`](anomaly-01-empty-pod.md) | Pod 07 anomaly |
| 21 | [`dialogue-pod-07.md`](dialogue-pod-07.md) | Pod 07 dialogue tree (already merged) |
| 22 | [`ROADMAP.md`](ROADMAP.md) | Milestones and ready tasks |
| 23 | [`AGENTS.md`](AGENTS.md) | How to work in this repo |
| 24 | [`DECISIONS.md`](DECISIONS.md) | Locked decisions and superseded ones |

## Source of truth

When documents disagree, use this order:

1. **Runtime content**: `data/content/*.json`, `data/ui_i18n.csv`
2. **Code**: `scripts/`, `scenes/`, `tests/`
3. **Current state**: `docs/STATE.md`
4. **Per-system design**: `docs/tech-tree.md`, `art-direction.md`, `ui-hud.md`, `first-phase-food.md`, `chapter-1-tools.md`, `factory-loop.md`, `thermal-power.md`, `materials-and-industry.md`, `ship-energy.md`, `ship-structure.md`, `colonist-wake-chain.md`, `plant-branch.md`, `tech-archive.md`
5. **Story canon**: `docs/story.md`
6. **Historical changelog entries** (do not treat old entries as current truth)

`addons/gu_core` and `addons/gu_gameplay` are read-only copies. Their source of
truth is `/Users/huangyuan/Projects/game-utils/godot/addons/`.

## Docs map

| File | Type | Status | Source of truth for |
|------|------|--------|---------------------|
| `STATE.md` | engineering | living | implemented vs designed, known gaps |
| `ROADMAP.md` | engineering | living | milestones, ready tasks, dependencies |
| `AGENTS.md` | engineering | living | workflow, rules, definition of done |
| `DECISIONS.md` | engineering | living | locked / superseded decisions |
| `story.md` | creative | canon | world, characters, ship, hidden coup |
| `story-spine.md` | creative | proposal | four-act narrative spine, mysteries, endings |
| `story-timeline.md` | creative | proposal | 180-year timeline, coup timing, crash, AI memory, continuation |
| `cast.md` | creative | proposal | names, gender, personality, hobbies, relationships |
| `design.md` | creative | design | pillars, Factorio lessons, 3D printing/AI/tech tree |
| `tech-tree.md` | creative | **tech tree design** | 5 phases, 7 branches, spine/branch nodes, shared tech, slides, data model |
| `art-direction.md` | creative | design | palette, shapes, lighting, materials, asset pipeline |
| `item-icons.md` | creative + engineering | living | item icon rules, mapping table, fallbacks, UI surfaces |
| `ui-hud.md` | creative | design | HUD layout, time, resources, pack, tech archive, colony, notifications |
| `thermal-power.md` | creative | design | thermal generator as bootstrap key, tech unlocks, T2.1 scope |
| `first-phase-food.md` | creative | design | hunger, foraging, rabbits, snares, first night |
| `chapter-1-tools.md` | creative | design | chapter 1 tools, wrist printer, verbs, tree/axe/power chain |
| `factory-loop.md` | creative | **F1 + F2 playable** | 9 materials, road logistics, steam/electric/field fleet, 6 tech nodes, F1–F5 |
| `materials-and-industry.md` | creative | design | material ladder, ship salvage, ore processing, orbital fleet |
| `ship-energy.md` | creative | design | 0.4c energy budget, beam road, reactor, confirmed decisions |
| `ship-structure.md` | creative | design + blockout | ship sections, scene layout, modular kit, S0–S3 blockout status |
| `colonist-wake-chain.md` | creative | design + graybox | roster, wake gates, shared tech |
| `plant-branch.md` | creative | design | geneticist's plant branch |
| `tech-archive.md` | creative | design | cargo hold, glass slides, road-cut archive |
| `opening.md` | creative | storyboard | opening beats and dialogue |
| `anomaly-01-empty-pod.md` | creative | design + implemented | Pod 07 scene and clue ladder |
| `dialogue-pod-07.md` | creative | implemented | Pod 07 dialogue JSON and tests |

## Current milestone

**M2 — Shelter + thermal generator + wake the geneticist.**

- Food/hunger loop: implemented.
- Visual foundation: procedural landing site, dawn environment, animated player,
  detailed pods, title key art: implemented (see [`art-direction.md`](art-direction.md)).
- Shelter and thermal generator build sites: implemented (graybox, flag-only).
- Geneticist pod + requirements: implemented (locked; no wake sequence yet).
- Research lab + simple farming: designed, not implemented.
- Ship blockout: **S0–S3** exterior landmark + connected cryo/med/corridor subset
  implemented as preview scenes (`scenes/ship/`) with inspection points and
  interior ↔ exterior transitions; new game still starts at the landing site.
  Energy bay, cargo hold and tech archive remain designed
  (see [`ship-structure.md`](ship-structure.md) and [`tech-archive.md`](tech-archive.md)).

See `ROADMAP.md` for ready tasks.

## Current gate

As of 2026-11-21:

```
[PASS] addons-parity: 96 files in sync
[PASS] pytest: 34 passed
[PASS] data-validate: 6 tables, 1 localization
[PASS] godot-import: exit=0
[PASS] godot-tests: 200 assertions
[PASS] godot-smoke: frames=30 exit=0
```

## Repository map

```
seed/
├── addons/                 # read-only copies of gu_core / gu_gameplay
├── data/
│   ├── content/            # quests, dialogue, items (JSON + schemas)
│   └── ui_i18n.csv         # English source strings → zh
├── docs/                   # this folder
├── scenes/
│   ├── main.tscn           # landing-site world + visual layer
│   ├── ship/               # blockout: cryo bay, med bay, corridor, exterior
│   ├── ui/                 # title, pause, HUD, wrist computer
│   └── world/              # pods, build sites, landscape, environment, ship
├── scripts/
│   ├── main.gd             # Seed coordinator
│   ├── ship/               # ship preview player / future ship systems
│   ├── survival/           # hunger loop
│   ├── colony/             # colonist pod / wake requirements
│   ├── ui/hud/             # SeedHud, vitals, hotbar, resources
│   ├── ui/wrist/           # PACK / ARCHIVE / COLONY
│   └── world/              # interactables, harvest nodes, build sites, WorldTime
├── assets/                 # key art, CC0 player model, shaders, ship GLBs
├── tools/
│   ├── blender/            # procedural ship model generators
│   └── godot/              # scene assembly scripts
└── tests/test_runner.gd    # 200 assertions
```

## Commands

```bash
GU=/Users/huangyuan/Projects/game-utils/start.sh
SEED=/Users/huangyuan/Projects/seed

$GU play   --project "$SEED"
$GU play   --project "$SEED" --editor
$GU check  --project "$SEED"
$GU addons sync --target "$SEED" --prune
```

Always use absolute paths: `gu` resolves relative paths against `game-utils/shell/`.

## Documentation rules

- Keep the version header and changelog in each doc.
- Mark uncertain content as **提议 / 待定**; do not silently promote it to canon.
- Link to the owning document instead of duplicating large sections.
- Update `STATE.md` and `ROADMAP.md` after any implementation change.
- If a decision changes, add a row to `DECISIONS.md` and mark the old one superseded.
- Do not rewrite historical changelog entries; append a new one.
