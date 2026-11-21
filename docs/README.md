# Seed — Documentation

> Godot 4.6 survival / colony game. Scaffolded from `game-utils` v0.2.0 (`d50ea22`).
> Last updated: 2026-11-21.
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
| 4 | [`cast.md`](cast.md) | Names, gender, personality, hobbies, relationships |
| 5 | [`design.md`](design.md) | Design pillars and the Factorio comparison |
| 6 | [`first-phase-food.md`](first-phase-food.md) | First-hour food / foraging / trap loop |
| 7 | [`thermal-power.md`](thermal-power.md) | Thermal generator components and tech unlocks |
| 8 | [`colonist-wake-chain.md`](colonist-wake-chain.md) | Roster, wake requirements, shared tech |
| 9 | [`plant-branch.md`](plant-branch.md) | Geneticist's plant branch (P0–P8) |
| 10 | [`tech-archive.md`](tech-archive.md) | Cargo hold, glass slides, discarded tech tree |
| 11 | [`opening.md`](opening.md) | Opening storyboard (wake → first exterior) |
| 12 | [`anomaly-01-empty-pod.md`](anomaly-01-empty-pod.md) | Pod 07 anomaly |
| 13 | [`dialogue-pod-07.md`](dialogue-pod-07.md) | Pod 07 dialogue tree (already merged) |
| 14 | [`ROADMAP.md`](ROADMAP.md) | Milestones and ready tasks |
| 15 | [`AGENTS.md`](AGENTS.md) | How to work in this repo |
| 16 | [`DECISIONS.md`](DECISIONS.md) | Locked decisions and superseded ones |

## Source of truth

When documents disagree, use this order:

1. **Runtime content**: `data/content/*.json`, `data/ui_i18n.csv`
2. **Code**: `scripts/`, `scenes/`, `tests/`
3. **Current state**: `docs/STATE.md`
4. **Per-system design**: `docs/first-phase-food.md`, `colonist-wake-chain.md`, `plant-branch.md`, `tech-archive.md`
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
| `cast.md` | creative | proposal | names, gender, personality, hobbies, relationships |
| `design.md` | creative | design | pillars, Factorio lessons, 3D printing/AI/tech tree |
| `thermal-power.md` | creative | design | thermal generator components, tech unlocks, T2.1 scope |
| `first-phase-food.md` | creative | design | hunger, foraging, rabbits, snares, first night |
| `colonist-wake-chain.md` | creative | design + graybox | roster, wake gates, shared tech |
| `plant-branch.md` | creative | design | geneticist's plant branch |
| `tech-archive.md` | creative | design | cargo hold, glass slides, tech tree recovery |
| `opening.md` | creative | storyboard | opening beats and dialogue |
| `anomaly-01-empty-pod.md` | creative | design + implemented | Pod 07 scene and clue ladder |
| `dialogue-pod-07.md` | creative | implemented | Pod 07 dialogue JSON and tests |

## Current milestone

**M2 — Shelter + thermal generator + wake the geneticist.**

- Food/hunger loop: implemented.
- Shelter and thermal generator build sites: implemented (graybox, flag-only).
- Geneticist pod + requirements: implemented (locked; no wake sequence yet).
- Research lab + simple farming: designed, not implemented.
- Large ship sections, energy bay, cargo hold/tech archive: designed, not implemented.

See `ROADMAP.md` for ready tasks.

## Current gate

As of 2026-11-21:

```
[PASS] addons-parity: 96 files in sync
[PASS] pytest: 34 passed
[PASS] data-validate: 3 tables, 1 localization
[PASS] godot-import: exit=0
[PASS] godot-tests: 87 assertions
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
│   ├── main.tscn           # graybox world
│   └── world/              # pod_07, geneticist_pod, berry_bush, build sites
├── scripts/
│   ├── main.gd             # Seed coordinator
│   ├── survival/           # hunger loop
│   ├── colony/             # colonist pod / wake requirements
│   └── world/              # interactables, harvest nodes, build sites
└── tests/test_runner.gd    # 87 assertions
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
