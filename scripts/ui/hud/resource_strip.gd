class_name ResourceStrip
extends HBoxContainer
## Pinned resource counts shown at the bottom-right of the HUD.

const DEFAULT_IDS: Array[StringName] = [&"wood", &"fiber", &"stone", &"wild_berry"]
const SHORT_NAMES := {
	&"wood": "HUD_RES_WOOD",
	&"fiber": "HUD_RES_FIBER",
	&"stone": "HUD_RES_STONE",
	&"wild_berry": "HUD_RES_BERRY",
	&"coin": "HUD_RES_COIN",
}

var _inventory: InventoryContainer
var _ids: Array[StringName] = []
var _chips: Dictionary = {} ## StringName -> PanelContainer
var _labels: Dictionary = {} ## StringName -> Label
var _icons: Dictionary = {} ## StringName -> TextureRect


func _init() -> void:
	add_theme_constant_override("separation", 4)
	_ids = DEFAULT_IDS.duplicate()
	_rebuild()


func bind_inventory(inv: InventoryContainer) -> void:
	if _inventory != null and _inventory.inventory_changed.is_connected(_refresh):
		_inventory.inventory_changed.disconnect(_refresh)
	_inventory = inv
	if _inventory != null and not _inventory.inventory_changed.is_connected(_refresh):
		_inventory.inventory_changed.connect(_refresh)
	_refresh_icons()
	_refresh()


func set_pinned(ids: Array[StringName]) -> void:
	_ids = ids.duplicate()
	_rebuild()
	_refresh()


func get_pinned_ids() -> Array[StringName]:
	return _ids.duplicate()


func get_chip_text(item_id: StringName) -> String:
	var label := _labels.get(item_id) as Label
	return label.text if label != null else ""


func get_chip_icon(item_id: StringName) -> Texture2D:
	var icon := _icons.get(item_id) as TextureRect
	return icon.texture if icon != null else null


func _exit_tree() -> void:
	if _inventory != null and _inventory.inventory_changed.is_connected(_refresh):
		_inventory.inventory_changed.disconnect(_refresh)


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_chips.clear()
	_labels.clear()
	_icons.clear()
	for item_id in _ids:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(68, 28)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.10, 0.10, 0.82)
		style.border_color = Color(0.23, 0.28, 0.28, 0.9)
		style.set_border_width_all(1)
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		panel.add_theme_stylebox_override("panel", style)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = ItemIcons.icon_for(item_id)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 9)
		label.add_theme_color_override("font_color", Color(0.93, 0.91, 0.86, 1.0))
		row.add_child(label)
		panel.tooltip_text = _pretty(item_id)
		panel.add_child(row)
		add_child(panel)
		_chips[item_id] = panel
		_labels[item_id] = label
		_icons[item_id] = icon


func _refresh_icons() -> void:
	for item_id in _ids:
		var icon := _icons.get(item_id) as TextureRect
		if icon == null:
			continue
		var tags: Array = []
		if _inventory != null:
			var def := _inventory.get_item_def(item_id)
			if def != null:
				tags = def.tags
		icon.texture = ItemIcons.icon_for(item_id, tags)


func _refresh() -> void:
	for item_id in _ids:
		var label := _labels.get(item_id) as Label
		if label == null:
			continue
		var count := 0
		if _inventory != null:
			count = _inventory.count_item(item_id)
		label.text = "%s %d" % [_short_name(item_id), count]
		if count <= 0:
			label.add_theme_color_override("font_color", Color(0.55, 0.58, 0.58, 1.0))
		else:
			label.add_theme_color_override("font_color", Color(0.93, 0.91, 0.86, 1.0))


func _short_name(item_id: StringName) -> String:
	var key := str(SHORT_NAMES.get(item_id, ""))
	if key != "":
		return tr(key)
	return String(item_id).replace("_", " ").to_upper()


func _pretty(item_id: StringName) -> String:
	if _inventory != null:
		var def := _inventory.get_item_def(item_id)
		if def != null and def.display_name != "":
			return tr(def.display_name)
	var raw := String(item_id).replace("_", " ")
	if raw.is_empty():
		return raw
	return raw.substr(0, 1).to_upper() + raw.substr(1)
