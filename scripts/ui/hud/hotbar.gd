class_name Hotbar
extends HBoxContainer
## Six-slot quickbar preview. Selection/use is wired when the tool system lands.

const SLOT_COUNT := 6

var _inventory: InventoryContainer
var _slots: Array[PanelContainer] = []
var _numbers: Array[Label] = []
var _icons: Array[TextureRect] = []
var _names: Array[Label] = []
var _counts: Array[Label] = []
var _slot_item_ids: Array[StringName] = []
var _slot_styles: Array[StyleBoxFlat] = []
var _selected_index := 0


func _init() -> void:
	add_theme_constant_override("separation", 4)
	for index in SLOT_COUNT:
		_slots.append(_make_slot(index))
		_slot_item_ids.append(&"")
	_apply_selection()


func bind_inventory(inv: InventoryContainer) -> void:
	if _inventory != null and _inventory.inventory_changed.is_connected(_refresh):
		_inventory.inventory_changed.disconnect(_refresh)
	_inventory = inv
	if _inventory != null and not _inventory.inventory_changed.is_connected(_refresh):
		_inventory.inventory_changed.connect(_refresh)
	_refresh()


func set_selected(index: int) -> void:
	_selected_index = clampi(index, 0, SLOT_COUNT - 1)
	_apply_selection()


func get_selected_index() -> int:
	return _selected_index


func get_slot_item_id(index: int) -> StringName:
	if index < 0 or index >= _slot_item_ids.size():
		return &""
	return _slot_item_ids[index]


func get_slot_item_ids() -> Array[StringName]:
	return _slot_item_ids.duplicate()


func get_slot_icon(index: int) -> Texture2D:
	if index < 0 or index >= _icons.size():
		return null
	return _icons[index].texture


func get_slot_texts() -> PackedStringArray:
	var result := PackedStringArray()
	for index in SLOT_COUNT:
		var name_text := _names[index].text.strip_edges()
		var count_text := _counts[index].text.strip_edges()
		result.append((name_text + " " + count_text).strip_edges())
	return result


func _exit_tree() -> void:
	if _inventory != null and _inventory.inventory_changed.is_connected(_refresh):
		_inventory.inventory_changed.disconnect(_refresh)


func _make_slot(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(56, 56)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.10, 0.78)
	style.border_color = Color(0.23, 0.28, 0.28, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	panel.add_theme_stylebox_override("panel", style)
	_slot_styles.append(style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)

	var number := Label.new()
	number.text = str(index + 1)
	number.add_theme_font_size_override("font_size", 8)
	number.add_theme_color_override("font_color", Color(0.55, 0.70, 0.72, 1.0))
	box.add_child(number)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(0, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)

	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.add_theme_color_override("font_color", Color(0.93, 0.91, 0.86, 1.0))
	box.add_child(name_label)

	var count_label := Label.new()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 9)
	count_label.add_theme_color_override("font_color", Color(0.47, 0.78, 0.85, 1.0))
	box.add_child(count_label)

	_numbers.append(number)
	_icons.append(icon)
	_names.append(name_label)
	_counts.append(count_label)
	add_child(panel)
	return panel


func _refresh() -> void:
	for index in SLOT_COUNT:
		_names[index].text = "—"
		_counts[index].text = ""
		_icons[index].texture = null
		_slot_item_ids[index] = &""
		_slots[index].tooltip_text = ""
	var occupied: Array[Dictionary] = []
	if _inventory != null:
		for raw_slot in _inventory.get_slots():
			var slot: Dictionary = raw_slot
			var item_id := StringName(slot.get("id", &""))
			var count := int(slot.get("count", 0))
			if item_id == &"" or count <= 0:
				continue
			occupied.append({"id": item_id, "count": count, "order": occupied.size()})
	occupied.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa := _priority(StringName(a["id"]))
		var pb := _priority(StringName(b["id"]))
		if pa == pb:
			return int(a["order"]) < int(b["order"])
		return pa < pb
	)
	var slot_index := 0
	for entry in occupied:
		if slot_index >= SLOT_COUNT:
			break
		var item_id := StringName(entry["id"])
		var def := _inventory.get_item_def(item_id) if _inventory != null else null
		var tags: Array = def.tags if def != null else []
		_names[slot_index].text = _pretty(item_id)
		_counts[slot_index].text = "x%d" % int(entry["count"])
		_icons[slot_index].texture = ItemIcons.icon_for(item_id, tags)
		_slots[slot_index].tooltip_text = _pretty(item_id)
		_slot_item_ids[slot_index] = item_id
		slot_index += 1
	_apply_selection()


func _priority(item_id: StringName) -> int:
	if _inventory == null:
		return 9
	var def := _inventory.get_item_def(item_id)
	if def == null:
		return 9
	if def.tags.has(&"tool") or def.tags.has(&"weapon"):
		return 0
	if def.tags.has(&"food"):
		return 1
	if def.tags.has(&"container"):
		return 2
	return 3


func _apply_selection() -> void:
	for index in _slot_styles.size():
		var style := _slot_styles[index]
		var selected := index == _selected_index
		style.border_color = Color(0.88, 0.54, 0.24, 1.0) if selected else Color(0.23, 0.28, 0.28, 0.9)
		style.set_border_width_all(2 if selected else 1)
		style.bg_color = Color(0.12, 0.10, 0.06, 0.88) if selected else Color(0.08, 0.10, 0.10, 0.78)


func _pretty(item_id: StringName) -> String:
	if _inventory != null:
		var def := _inventory.get_item_def(item_id)
		if def != null and def.display_name != "":
			return tr(def.display_name)
	var raw := String(item_id).replace("_", " ")
	if raw.is_empty():
		return raw
	return raw.substr(0, 1).to_upper() + raw.substr(1)
