# Seed — Agent Guide

> Read this before editing. It describes the repo as it is, the rules that must not
> be broken, and how to work alongside other agents.
>
> Project: `/Users/huangyuan/Projects/seed`
> Upstream shared base: `/Users/huangyuan/Projects/game-utils` (`v0.2.0`, `d50ea22`)
> Engine: Godot 4.6.2.stable

## 1. Reading order

1. [`STATE.md`](STATE.md) — what is implemented now.
2. [`ROADMAP.md`](ROADMAP.md) — pick a task from **Ready**.
3. [`DECISIONS.md`](DECISIONS.md) — do not re-litigate locked decisions.
4. The owning design doc for your task (food, colonists, plant, tech archive, opening).
5. [`story.md`](story.md) only when you need canon.

## 2. Hard rules

1. **Never edit `addons/gu_core` or `addons/gu_gameplay` in this repo.** They are
   copies. Fix shared code in `game-utils/godot/addons/`, run its gate, commit there,
   then sync with `gu addons sync --target <seed> --prune`.
2. **Seed-specific code goes in `scripts/`, `scenes/`, `data/`, `tests/`.**
3. **Reusable changes go upstream**, not into the copied addons.
4. **All `gu` commands use absolute paths.** Relative paths resolve against
   `game-utils/shell/`, not your shell's cwd.
5. **Code, comments, and commit messages are English.** Creative docs may be Chinese.
6. **Runtime content is data-driven.** Add JSON rows + schema + `ui_i18n.csv` entries.
7. **Do not delete or rewrite someone else's work** unless it is clearly obsolete and
   documented in `DECISIONS.md` / `ROADMAP.md`.
8. **Update `STATE.md` and `ROADMAP.md`** whenever behavior changes.

## 3. Repository map

```
scripts/main.gd          Seed coordinator: HUD, dialogue, hunger, build sites, pods
scripts/survival/        HungerController (decay, thresholds, eating)
scripts/colony/          ColonistPod (wake requirements)
scripts/world/           Pod07, BerryBush, HarvestNode, BuildSite
scenes/main.tscn         Graybox world; all interactables are instanced here
scenes/world/            Pod07, GeneticistPod, BerryBush, fallen branch, grass,
                         shelter site, thermal generator site
data/content/            quests.json, dialogue.json, items.json + schemas
data/ui_i18n.csv         English source key → zh
tests/test_runner.gd     Headless assertions (87 as of 2026-11-21)
docs/                    Design + engineering docs
```

## 4. Workflow

1. Pick a task from `ROADMAP.md` **Ready** (or ask the user to choose).
2. If multiple agents are active, claim the task by adding your name/session to the
   task row and avoid touching the same files.
3. Read the owning doc. If it conflicts with `STATE.md`, `STATE.md` wins for current
   behavior; update the doc.
4. Implement the smallest vertical slice.
5. Add/update tests in `tests/test_runner.gd` (or a new suite if it grows).
6. Add strings to `data/ui_i18n.csv`; run data validation.
7. Update `STATE.md`, `ROADMAP.md`, and the owning design doc.
8. Run the full gate.
9. Commit in English, one logical change per commit.

## 5. Definition of done

A task is done only when:

- [ ] The behavior is implemented in `scripts/` / `scenes/` (not just docs).
- [ ] Runtime content is in `data/content/` with a schema if it is a new table.
- [ ] All new user-facing strings exist in `data/ui_i18n.csv` with `zh`.
- [ ] Tests cover the new behavior and edge cases.
- [ ] `gu data validate` passes.
- [ ] `gu check` passes (6/6; expected assertion count updated).
- [ ] `STATE.md` and `ROADMAP.md` are updated.
- [ ] The owning design doc is updated or linked.
- [ ] No addon files changed.

## 6. Testing

```bash
GU=/Users/huangyuan/Projects/game-utils/start.sh
SEED=/Users/huangyuan/Projects/seed

$GU data validate "$SEED/data"
$GU check --project "$SEED"

# Focused headless tests
/Applications/Godot.app/Contents/MacOS/Godot --headless --path "$SEED" \
  --script res://tests/test_runner.gd
```

Test strategy:

- Prefer deterministic assertions; avoid waiting on real time.
- Expose pure methods (`can_build()`, `can_wake()`, `eat_berry()`) and test them.
- For interactables, instantiate the scene, add to the tree, then call `interact(actor)`.
- Do not depend on `_process` timing for pass/fail.
- The `pytest` step in `gu check` is **game-utils' own** Python test suite; a failure
  there means the upstream repo changed, not Seed.

## 7. Content authoring

- Tables live in `data/content/*.json` and are validated against `*.schema.json`.
- Text is authored in English (the key), translated in `data/ui_i18n.csv` (`zh`).
- Dialogue nodes support:
  - `conditions`: `flag`, `quest`, `item`
  - `effects`: `set_flag`, `inc_flag`, `start_quest`, `add_item`, `remove_item`,
    `emit_event`
  - `branches`: conditional `next`
- `DialogueBox` only calls `tr()`; it does **not** substitute `{player_name}`.
  Prefer “Commander” / second person, or add upstream token support first.
- Item definitions must be registered before `add_item` effects run. `main.gd`
  registers all rows from `GameContent.items()` at startup.

## 8. Where to put new code

| System | Put it in |
|--------|-----------|
| Hunger, thirst, temperature | `scripts/survival/` |
| Harvestables, traps, wildlife | `scripts/world/` |
| Build sites, shelters, generators | `scripts/world/` or `scripts/colony/` |
| Colonist pods, wake requirements | `scripts/colony/` |
| Power grid / thermal generator simulation | `scripts/power/` (planned) |
| 3D printing / fabrication | `scripts/fabrication/` (planned) |
| Tech tree / archive | `scripts/tech/` (planned) |
| Ship AI assistant / hints | `scripts/ship_ai/` (planned; avoid `addons/gu_gameplay/ai/`) |
| Farming / research lab | `scripts/agriculture/` (planned) |
| UI screens | `scenes/ui/` + `scripts/ui/` |

## 9. Multi-agent coordination

- **Claim tasks in `ROADMAP.md`.** Add your session/agent name and date.
- **Do not edit the same file as another active agent** unless coordinated.
- Keep changes small; avoid reformatting unrelated code.
- Update `STATE.md` in the same commit as the behavior change.
- If you change a locked decision, update `DECISIONS.md` and mark the old row
  superseded; do not silently diverge.
- Use a git worktree/branch for large features. `tools.opencode.worktree_create`
  is available in the OpenCode environment.
- If a task is blocked, move it to **Blocked** with the dependency.

## 10. Known pitfalls

- `addons/**/*.uid` is gitignored; `scripts/**/*.uid` is tracked. Keep script UIDs.
- `.gitignore` ignores `*.import` except `*.csv.import`; asset imports are not tracked.
- The current world is a **40×40 graybox plane**, not a ship interior. Pods and build
  sites are placed around the spawn point for testing.
- The geneticist pod is **locked**: no system sets `thermal_generator_built`,
  `power_capacity`, `shelter_built`, `medbay_online` except the build sites.
- There is no wake sequence, research lab, farming, ship interior, cargo hold, 4 km
  map, ocean, 3D printing, or fleet yet. Do not pretend otherwise in docs.
- AI hints are **subtitles**, not voice lines.
- Export templates are machine-level, not in the repo.
- `gu check` runs `game-utils` Python tests; they are not Seed tests.

## 11. Updating the shared base

1. Change `/Users/huangyuan/Projects/game-utils/godot/addons/`.
2. Run `game-utils`' own gate.
3. Commit upstream.
4. `gu addons sync --target "$SEED" --prune`.
5. Update the baseline version/commit in `README.md` and `docs/STATE.md`.

## 12. Useful references

- `game-utils/AGENTS.md` — upstream architecture and task routing.
- `game-utils/docs/stability.md` — verified release state.
- `game-utils/prototypes/walk-sandbox/` — terrain, weather, world reference.
- `docs/README.md` — documentation index.
