class_name ItemIcons
extends RefCounted
## Resolves item icons for HUD, wrist computer, and inventory surfaces.
##
## Authored 256 px icons live in `assets/art/icons/` and are mapped through
## `data/content/item_icons.json`. Items without an authored icon get a
## deterministic 64 px category glyph so the UI never shows an empty slot.

const ICON_DIR := "res://assets/art/icons"
const FALLBACK_SIZE := 64

const COL_LOG := Color("#7a5a36")
const COL_LOG_DARK := Color("#43301c")
const COL_LEAF := Color("#4f6b3a")
const COL_FIBER := Color("#b7a266")
const COL_FIBER_DARK := Color("#6f623c")
const COL_STONE := Color("#77746b")
const COL_STONE_DARK := Color("#46443e")
const COL_IRON := Color("#9a9a94")
const COL_COPPER := Color("#b06a3a")
const COL_COAL := Color("#3d4747")
const COL_PLATE := Color("#b8bdb8")
const COL_PART := Color("#79c7d8")
const COL_TOOL := Color("#c9b99a")
const COL_TOOL_DARK := Color("#5b4a33")
const COL_COIN := Color("#e0b85c")
const COL_DATA := Color("#1e2a2e")
const COL_CHIP := Color("#d8efe8")
const COL_BERRY := Color("#a83a56")
const COL_WATER := Color("#5aa3b8")
const COL_GENERIC := Color("#6b6a60")
const COL_OUTLINE := Color(0.05, 0.06, 0.06, 0.85)

static var _table_loaded := false
static var _overrides: Dictionary = {} ## String item id -> String icon path
static var _cache: Dictionary = {} ## String item id -> Texture2D


static func icon_for(item_id: StringName, tags: Array = []) -> Texture2D:
	var key := String(item_id)
	if _cache.has(key):
		return _cache[key] as Texture2D
	_ensure_table()
	var path := str(_overrides.get(key, ""))
	if path != "":
		if not path.begins_with("res://"):
			path = ICON_DIR.path_join(path)
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex != null:
				_cache[key] = tex
				return tex
	var fallback := _make_fallback(key, tags)
	_cache[key] = fallback
	return fallback


static func apply_to(def: ItemDef) -> void:
	if def == null:
		return
	def.icon = icon_for(def.id, def.tags)


static func apply_all(defs: Array) -> void:
	for raw_def in defs:
		var def := raw_def as ItemDef
		if def != null:
			apply_to(def)


static func clear_cache() -> void:
	_cache.clear()
	_table_loaded = false
	_overrides.clear()


static func _ensure_table() -> void:
	if _table_loaded:
		return
	_table_loaded = true
	for row in GameContent.database().rows("item_icons"):
		var id := str(row.get("id", ""))
		var icon := str(row.get("icon", ""))
		if id != "" and icon != "":
			_overrides[id] = icon


static func _category(item_id: String, tags: Array) -> String:
	var set := {}
	for raw_tag in tags:
		set[String(raw_tag)] = true
	if set.has("berry") or set.has("food"):
		return "food"
	if set.has("water"):
		return "water"
	if set.has("tool"):
		return "tool"
	if set.has("part"):
		return "part"
	if set.has("processed") or set.has("plate"):
		return "plate"
	if set.has("ore") or set.has("iron") or set.has("copper"):
		return "ore"
	if set.has("fuel"):
		return "fuel"
	if set.has("currency"):
		return "coin"
	if set.has("data") or set.has("chip"):
		return "data"
	if set.has("wood") or item_id.contains("wood"):
		return "wood"
	if set.has("fiber"):
		return "fiber"
	if set.has("stone"):
		return "stone"
	return "generic"


static func _make_fallback(item_id: String, tags: Array) -> Texture2D:
	var img := Image.create(FALLBACK_SIZE, FALLBACK_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var category := _category(item_id, tags)
	match category:
		"food":
			_draw_food(img)
		"water":
			_draw_water(img)
		"tool":
			_draw_tool(img, item_id)
		"ore":
			_draw_ore(img, tags)
		"part":
			_draw_part(img, item_id)
		"plate":
			_draw_plate(img)
		"fuel":
			_draw_fuel(img)
		"coin":
			_draw_coin(img)
		"data":
			_draw_data(img)
		"wood":
			_draw_wood(img)
		"fiber":
			_draw_fiber(img)
		"stone":
			_draw_stone(img)
		_:
			_draw_generic(img)
	return ImageTexture.create_from_image(img)


# --- Glyphs ------------------------------------------------------------------

static func _draw_food(img: Image) -> void:
	_leaf(img, 32, 20, 13, 6, COL_LEAF)
	_line(img, 32, 15, 32, 27, 3, COL_LOG_DARK)
	for centre in [Vector2i(22, 38), Vector2i(32, 34), Vector2i(42, 38)]:
		_disc(img, centre.x, centre.y, 11, COL_OUTLINE)
		_disc(img, centre.x, centre.y, 9, COL_BERRY)
		_disc(img, centre.x - 3, centre.y - 3, 3, COL_BERRY.lightened(0.28))


static func _draw_water(img: Image) -> void:
	_disc(img, 32, 38, 16, COL_OUTLINE)
	_disc(img, 32, 38, 14, COL_WATER)
	_tri(img, Vector2i(32, 8), Vector2i(20, 32), Vector2i(44, 32), COL_OUTLINE)
	_tri(img, Vector2i(32, 13), Vector2i(23, 32), Vector2i(41, 32), COL_WATER)
	_disc(img, 27, 35, 4, COL_WATER.lightened(0.35))


static func _draw_wood(img: Image) -> void:
	for y in [26, 39, 52]:
		_capsule(img, 12, y, 50, y, 7, COL_OUTLINE)
		_capsule(img, 12, y, 50, y, 5, COL_LOG)
		_disc(img, 50, y, 5, COL_LOG_DARK)
		_disc(img, 50, y, 3, COL_LOG.lightened(0.18))


static func _draw_fiber(img: Image) -> void:
	for tip in [Vector2i(14, 18), Vector2i(23, 14), Vector2i(32, 12), Vector2i(41, 14), Vector2i(50, 18)]:
		_line(img, 32, 55, tip.x, tip.y, 5, COL_OUTLINE)
		_line(img, 32, 55, tip.x, tip.y, 3, COL_FIBER)
	_line(img, 32, 56, 32, 46, 3, COL_FIBER_DARK)


static func _draw_stone(img: Image) -> void:
	_poly(img, [Vector2i(32, 12), Vector2i(52, 28), Vector2i(45, 51), Vector2i(19, 49), Vector2i(12, 28)], COL_OUTLINE)
	_poly(img, [Vector2i(32, 16), Vector2i(48, 29), Vector2i(42, 47), Vector2i(22, 45), Vector2i(16, 29)], COL_STONE)
	_poly(img, [Vector2i(32, 16), Vector2i(48, 29), Vector2i(32, 34)], COL_STONE.lightened(0.16))


static func _draw_ore(img: Image, tags: Array) -> void:
	var set := {}
	for raw_tag in tags:
		set[String(raw_tag)] = true
	var colour := COL_IRON
	if set.has("copper"):
		colour = COL_COPPER
	for centre in [Vector2i(21, 42), Vector2i(33, 32), Vector2i(45, 43)]:
		_diamond(img, centre.x, centre.y, 11, 13, COL_STONE_DARK)
		_diamond(img, centre.x, centre.y, 8, 10, colour)
		_diamond(img, centre.x - 2, centre.y - 3, 3, 4, colour.lightened(0.3))


static func _draw_plate(img: Image) -> void:
	_poly(img, [Vector2i(10, 38), Vector2i(50, 38), Vector2i(44, 51), Vector2i(16, 51)], COL_OUTLINE)
	_poly(img, [Vector2i(14, 40), Vector2i(47, 40), Vector2i(42, 48), Vector2i(19, 48)], COL_PLATE.darkened(0.14))
	_poly(img, [Vector2i(18, 22), Vector2i(56, 22), Vector2i(50, 35), Vector2i(22, 35)], COL_OUTLINE)
	_poly(img, [Vector2i(21, 25), Vector2i(52, 25), Vector2i(47, 32), Vector2i(25, 32)], COL_PLATE)
	_line(img, 24, 27, 48, 27, 2, COL_PLATE.lightened(0.35))


static func _draw_part(img: Image, item_id: String) -> void:
	for i in 8:
		var a := TAU * float(i) / 8.0
		var cx := 32 + int(round(cos(a) * 19.0))
		var cy := 32 + int(round(sin(a) * 19.0))
		_disc(img, cx, cy, 7, COL_OUTLINE)
		_disc(img, cx, cy, 5, COL_PART)
	_disc(img, 32, 32, 18, COL_OUTLINE)
	_disc(img, 32, 32, 15, COL_PART)
	_disc(img, 32, 32, 6, COL_OUTLINE)
	if item_id.contains("electrical"):
		_poly(img, [Vector2i(36, 15), Vector2i(26, 33), Vector2i(33, 33), Vector2i(28, 50), Vector2i(43, 29), Vector2i(35, 29)], COL_OUTLINE)
		_poly(img, [Vector2i(35, 19), Vector2i(29, 31), Vector2i(34, 31), Vector2i(31, 44), Vector2i(40, 30), Vector2i(34, 30)], Color("#ffd25e"))


static func _draw_tool(img: Image, item_id: String) -> void:
	_line(img, 17, 51, 42, 18, 8, COL_OUTLINE)
	_line(img, 17, 51, 42, 18, 5, COL_TOOL)
	_line(img, 17, 51, 24, 43, 3, COL_TOOL_DARK)
	if item_id.contains("pickaxe"):
		_line(img, 28, 24, 56, 31, 6, COL_OUTLINE)
		_line(img, 28, 24, 56, 31, 4, COL_STONE)
		_line(img, 34, 18, 56, 24, 3, COL_STONE.lightened(0.2))
	elif item_id.contains("knife"):
		_poly(img, [Vector2i(33, 24), Vector2i(54, 10), Vector2i(44, 34)], COL_OUTLINE)
		_poly(img, [Vector2i(35, 24), Vector2i(50, 14), Vector2i(42, 32)], COL_PLATE)
	elif item_id.contains("hammer") or item_id.contains("mallet"):
		_rect(img, 34, 12, 22, 16, COL_OUTLINE)
		_rect(img, 36, 14, 18, 12, COL_STONE)
	else:
		_poly(img, [Vector2i(34, 22), Vector2i(54, 17), Vector2i(48, 37), Vector2i(36, 31)], COL_OUTLINE)
		_poly(img, [Vector2i(36, 24), Vector2i(51, 20), Vector2i(46, 34), Vector2i(37, 30)], COL_STONE)


static func _draw_fuel(img: Image) -> void:
	_disc(img, 30, 38, 15, COL_STONE_DARK)
	_disc(img, 30, 38, 13, COL_COAL)
	_disc(img, 42, 33, 10, COL_STONE_DARK)
	_disc(img, 42, 33, 8, COL_COAL.lightened(0.08))
	_disc(img, 25, 33, 3, COL_COAL.lightened(0.38))
	_disc(img, 35, 29, 2, COL_COAL.lightened(0.28))


static func _draw_coin(img: Image) -> void:
	_disc(img, 32, 32, 20, COL_OUTLINE)
	_disc(img, 32, 32, 17, COL_COIN)
	_disc(img, 32, 32, 11, COL_COIN.darkened(0.18))
	_disc(img, 32, 32, 8, COL_COIN)
	_disc(img, 26, 25, 3, COL_COIN.lightened(0.4))


static func _draw_data(img: Image) -> void:
	_rect(img, 13, 20, 38, 27, COL_OUTLINE)
	_rect(img, 16, 23, 32, 21, COL_DATA)
	_rect(img, 20, 27, 24, 13, COL_CHIP)
	for i in 4:
		_rect(img, 17 + i * 8, 47, 4, 6, COL_OUTLINE)
	_rect(img, 24, 31, 13, 4, COL_DATA.lightened(0.2))


static func _draw_generic(img: Image) -> void:
	_rect(img, 13, 13, 38, 38, COL_OUTLINE)
	_rect(img, 16, 16, 32, 32, COL_GENERIC)
	_line(img, 16, 16, 48, 48, 3, COL_GENERIC.lightened(0.2))
	_line(img, 48, 16, 16, 48, 3, COL_GENERIC.lightened(0.2))


# --- Pixel helpers -----------------------------------------------------------

static func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for py in range(maxi(0, y), mini(FALLBACK_SIZE, y + h)):
		for px in range(maxi(0, x), mini(FALLBACK_SIZE, x + w)):
			img.set_pixel(px, py, col)


static func _disc(img: Image, cx: int, cy: int, radius: int, col: Color) -> void:
	var r2 := radius * radius
	for py in range(maxi(0, cy - radius), mini(FALLBACK_SIZE, cy + radius + 1)):
		for px in range(maxi(0, cx - radius), mini(FALLBACK_SIZE, cx + radius + 1)):
			var dx := px - cx
			var dy := py - cy
			if dx * dx + dy * dy <= r2:
				img.set_pixel(px, py, col)


static func _line(img: Image, x0: int, y0: int, x1: int, y1: int, thickness: int, col: Color) -> void:
	var steps := maxi(absi(x1 - x0), absi(y1 - y0))
	if steps == 0:
		_disc(img, x0, y0, maxi(1, thickness / 2), col)
		return
	for i in steps + 1:
		var t := float(i) / float(steps)
		var x := int(round(lerpf(float(x0), float(x1), t)))
		var y := int(round(lerpf(float(y0), float(y1), t)))
		_disc(img, x, y, maxi(1, thickness / 2), col)


static func _capsule(img: Image, x0: int, y0: int, x1: int, y1: int, radius: int, col: Color) -> void:
	_line(img, x0, y0, x1, y1, radius * 2, col)
	_disc(img, x0, y0, radius, col)
	_disc(img, x1, y1, radius, col)


static func _diamond(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
	for py in range(maxi(0, cy - ry), mini(FALLBACK_SIZE, cy + ry + 1)):
		for px in range(maxi(0, cx - rx), mini(FALLBACK_SIZE, cx + rx + 1)):
			var nx := float(px - cx) / float(maxi(1, rx))
			var ny := float(py - cy) / float(maxi(1, ry))
			if absf(nx) + absf(ny) <= 1.0:
				img.set_pixel(px, py, col)


static func _leaf(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
	for py in range(maxi(0, cy - ry), mini(FALLBACK_SIZE, cy + ry + 1)):
		for px in range(maxi(0, cx - rx), mini(FALLBACK_SIZE, cx + rx + 1)):
			var nx := float(px - cx) / float(maxi(1, rx))
			var ny := float(py - cy) / float(maxi(1, ry))
			if absf(nx) + absf(ny) <= 1.0 and (nx - ny) < 0.55:
				img.set_pixel(px, py, col)


static func _tri(img: Image, a: Vector2i, b: Vector2i, c: Vector2i, col: Color) -> void:
	var min_x := mini(a.x, mini(b.x, c.x))
	var max_x := maxi(a.x, maxi(b.x, c.x))
	var min_y := mini(a.y, mini(b.y, c.y))
	var max_y := maxi(a.y, maxi(b.y, c.y))
	var area := _edge(a, b, c)
	if area == 0.0:
		return
	for py in range(maxi(0, min_y), mini(FALLBACK_SIZE, max_y + 1)):
		for px in range(maxi(0, min_x), mini(FALLBACK_SIZE, max_x + 1)):
			var p := Vector2i(px, py)
			var w0 := _edge(b, c, p) / area
			var w1 := _edge(c, a, p) / area
			var w2 := _edge(a, b, p) / area
			if w0 >= -0.001 and w1 >= -0.001 and w2 >= -0.001:
				img.set_pixel(px, py, col)


static func _poly(img: Image, points: Array, col: Color) -> void:
	if points.size() < 3:
		return
	var p0: Vector2i = points[0]
	for i in range(1, points.size() - 1):
		var p1: Vector2i = points[i]
		var p2: Vector2i = points[i + 1]
		_tri(img, p0, p1, p2, col)


static func _edge(a: Vector2i, b: Vector2i, c: Vector2i) -> float:
	return float((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x))
