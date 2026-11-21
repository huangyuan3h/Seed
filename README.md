# Game Starter

A playable Godot 4.6 project scaffolded by `game-utils`.

## Controls

- **WASD / Arrows**: move relative to the camera
- **Shift**: toggle run
- **Space**: strike
- **E**: interact (talk to the guide)
- **Scroll / `+` `-`**: camera zoom
- **`I`**: inventory
- **ESC**: pause menu / save slots / settings

## What is wired

- `gu_core` autoloads: settings, input contexts, audio buses, save slots, UI router, game flow, clock, events, pools, dev console.
- `GuPlayer` and `CameraRig` from `gu_gameplay`.
- A guide NPC (`DialogueInteractable`), a `DialogueBox`, an interaction prompt, and a quest HUD.
- A sample quest (`meet_guide`) and guide dialogue loaded from `data/content/`.

## Add content

Edit the JSON tables under `data/content/`:

| File | Rows |
|------|------|
| `quests.json` | `id`, `title`, `description`, `objectives`, `rewards`, `auto_start` |
| `dialogue.json` | `id`, `start`, `nodes` with text, choices, conditions, and effects |
| `items.json` | `id`, `display_name`, `max_stack`, `tags` |

Text is authored in English and translated through `data/ui_i18n.csv` (`keys,en,zh`).
`tr()` resolves it at render time, so missing translations fall back to English.

Validate and run the quality gate from the game-utils repository:

```bash
# from the game-utils repository
./start.sh data validate path/to/this/project/data
./start.sh check --project path/to/this/project
```

## Shared base

This project was scaffolded from [game-utils](https://github.com/huangyuan3h/game-utils) at `v0.2.0` (`d50ea22`). game-utils stays the source of truth for the shared addons and tooling; this repository only contains Seed.

```bash
GU=~/Projects/game-utils/start.sh

$GU play  --project "$(pwd)"
$GU play  --project "$(pwd)" --editor
$GU check --project "$(pwd)"
$GU addons sync --target "$(pwd)" --prune
```

Use absolute paths: `gu` resolves relative paths against the game-utils `shell/` directory, not your shell's working directory.

`addons/gu_core` and `addons/gu_gameplay` are copies. Do not edit them here — `gu addons sync --prune` overwrites them. Game-specific code belongs in `scripts/` and `scenes/`; reusable changes go into game-utils `godot/addons/`, then get synced back and the base version recorded above is bumped.
