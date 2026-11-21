# Seed

A Godot 4.6 survival / colony game scaffolded from the [game-utils](https://github.com/huangyuan3h/game-utils) shared base.

You wake from the Eden system on a seeded planet, `SEED-2338 III`, with a broken ship,
a handful of sleepers, and one question: **can people learn to live here?**

## Documentation

Start with [`docs/README.md`](docs/README.md). It is the index for story, design,
current state, roadmap, and agent rules.

- [`docs/STATE.md`](docs/STATE.md) — what is implemented now
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — milestones and ready tasks
- [`docs/AGENTS.md`](docs/AGENTS.md) — how to work in this repo
- [`docs/story.md`](docs/story.md) — story canon
- [`docs/DECISIONS.md`](docs/DECISIONS.md) — locked decisions

## Playable now (graybox)

- 40×40 test plane with a `GuPlayer` and camera rig.
- **Pod 07** anomaly: empty hibernation pod, data chip, three dialogue entries.
- **Hunger loop**: hunger bar, wild berries, `H` to eat, AI threshold hints.
- **Shelter + thermal generator** build sites; wood/fiber harvest nodes.
- **Locked geneticist pod** with wake requirements (generator, power, shelter,
  food, med bay).

This is still a graybox. There is no real ship interior, 4 km map, ocean, research
lab, farming, NPC schedule, or fleet yet. See `docs/STATE.md` for the full list.

## Controls

- **WASD / Arrows**: move relative to the camera
- **Shift**: toggle run
- **Space**: strike
- **E**: interact
- **H**: eat a wild berry
- **I**: inventory
- **Scroll / `+` `-`**: camera zoom
- **ESC**: pause / save / settings
- **`` ` ``**: dev console

## Commands

```bash
GU=/Users/huangyuan/Projects/game-utils/start.sh
SEED=/Users/huangyuan/Projects/seed

$GU play   --project "$SEED"
$GU play   --project "$SEED" --editor
$GU check  --project "$SEED"
$GU addons sync --target "$SEED" --prune
$GU export --preset macOS --out "$SEED/build/macos/seed.zip"
```

Use absolute paths: `gu` resolves relative paths against `game-utils/shell/`, not your
shell's current directory.

## Shared base

Scaffolded from game-utils at `v0.2.0` (`d50ea22`). game-utils remains the source of
truth for the shared addons and tooling.

`addons/gu_core` and `addons/gu_gameplay` are **copies**. Do not edit them here:
`gu addons sync --prune` overwrites them. Seed-specific code belongs in `scripts/` and
`scenes/`; reusable changes go into game-utils `godot/addons/`, then are synced back.

## Layout

```
addons/        read-only shared plugins
data/          content tables + localization
docs/          story, design, state, roadmap, agent rules
scenes/        main graybox + world interactables
scripts/       Seed coordinator, survival, colony, world
tests/         headless assertions
```
