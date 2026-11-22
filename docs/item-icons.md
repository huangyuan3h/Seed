# Seed — Item Icons

> Status: v0.1 · 2026-11-22
>
> Scope: how item icons are authored, mapped, resolved, and rendered in the HUD
> and wrist computer. This is a presentation layer; gameplay item data stays in
> `data/content/items.json`.

## 1. Authored icons

Current 256 px transparent PNGs live in `assets/art/icons/`:

| File | Item | Notes |
|------|------|-------|
| `icon_wood.png` | `wood` | three-log bundle |
| `icon_fiber.png` | `fiber` | grass/fiber tuft |
| `icon_berry.png` | `wild_berry` | red berry cluster |
| `icon_chip.png` | `data_chip_07` | glass data chip |
| `icon_water.png` | future `water` | reserved |

Art rules:

- 256×256, transparent background, object only (no baked tile/panel).
- Three-quarter view, soft top-left key light, matching the current low-poly kit.
- Keep the silhouette readable at 18–32 px; avoid thin wires and tiny text.
- Filename convention: `icon_<short_name>.png`.
- Add the mapping row in `data/content/item_icons.json`; do not hard-code paths
  in UI widgets.

## 2. Mapping table

`data/content/item_icons.json` is a normal Seed content table:

```json
{ "id": "wild_berry", "icon": "res://assets/art/icons/icon_berry.png" }
```

`scripts/ui/item_icons.gd` loads it once, resolves the path, caches the
`Texture2D`, and applies it to `ItemDef.icon` when items are registered.

Why a separate table instead of adding `icon` to `items.json`?

- Icons are presentation data and can change without touching gameplay rows.
- Other agents can add items without merge conflicts in the icon table.
- Missing rows are safe: the resolver falls back to a generated glyph.

## 3. Fallback icons

Items without an authored icon get a deterministic 64 px glyph drawn at runtime
from their tags:

| Category | Example | Glyph |
|----------|---------|-------|
| food | `wild_berry` | berry cluster + leaf |
| tool | `stone_axe`, `emergency_knife`, `mallet` | handle + head/blade |
| ore | `iron_ore`, `copper_ore` | three ore chunks |
| plate | `iron_plate`, `copper` | stacked plates |
| part | `mechanical_part`, `electrical_part` | gear (bolt for electrical) |
| fuel | `coal` | coal lumps |
| data | `data_chip_07` | chip with pins |
| wood / fiber / stone | resources | log bundle / blades / rock |
| coin | `coin` | coin |
| generic | anything else | crate |

Fallbacks are cached per item id, so `stone_axe` and `stone_pickaxe` can differ
while sharing a category. They are intentionally simple; replace them with
authored PNGs over time.

## 4. Where icons render

| Surface | File | Status |
|---------|------|--------|
| Wrist `PACK` grid | `scripts/ui/wrist/wrist_computer.gd` | icon + name + count; detail panel shows 52 px icon |
| Pinned resource chips | `scripts/ui/hud/resource_strip.gd` | 18 px icon + count |
| `ItemDef.icon` | `scripts/main.gd` via `ItemIcons.apply_to()` | every registered item has a texture |
| Hotbar | `scripts/ui/hud/hotbar.gd` | **not wired yet** — owner agent is editing this file; use `ItemIcons.icon_for(item_id, def.tags)` when adding the slot `TextureRect` |
| Build-site cost rows | future | use the same resolver |

## 5. Adding a new icon

1. Render/export a 256 px transparent PNG into `assets/art/icons/`.
2. Add a row to `data/content/item_icons.json`.
3. Run:
   ```bash
   GU=/Users/huangyuan/Projects/game-utils/start.sh
   $GU data validate /Users/huangyuan/Projects/seed/data
   $GU check --project /Users/huangyuan/Projects/seed
   ```
4. No UI code change is needed; the resolver picks it up on the next run.

## 6. Testing

- `ItemIcons.icon_for(&"wood")` should return the 256 px authored texture.
- `ItemIcons.icon_for(&"stone_axe", [&"tool", &"axe"])` should return a 64 px
  fallback texture.
- `ResourceStrip.get_chip_icon(&"wood")` should be non-null after binding.
- `WristComputer.get_visible_icon_count()` should be > 0 when the pack has items.

The fallback is deliberately part of the contract: a missing icon should never
produce an empty slot.
