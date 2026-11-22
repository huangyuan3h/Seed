extends Control
## Wrist computer: PACK / ARCHIVE / COLONY. Opening it pauses gameplay and the
## world clock; closing restores both when the game is still in PLAYING.

const THEME_PATH := "res://addons/gu_core/ui/default_theme.tres"
const TAB_PACK := &"pack"
const TAB_ARCHIVE := &"archive"
const TAB_COLONY := &"colony"

var _active_tab: StringName = TAB_PACK
var _inventory: InventoryContainer
var _selected_item: StringName = &""

var _title: Label
var _paused_label: Label
var _pack_panel: VBoxContainer
var _archive_panel: VBoxContainer
var _colony_panel: VBoxContainer
var _pack_grid: GridContainer
var _pack_capacity: Label
var _pack_detail: Label
var _pack_detail_icon: TextureRect
var _archive_status: Label
var _archive_rows: VBoxContainer
var _colony_summary: Label
var _tab_buttons: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if ResourceLoader.exists(THEME_PATH):
		theme = load(THEME_PATH)
	_build()
	_ensure_inventory()
	_refresh_all()


func on_ui_enter(params: Dictionary = {}) -> void:
	_pause_gameplay(true)
	var requested := StringName(str(params.get("tab", "pack")))
	if requested in [TAB_PACK, TAB_ARCHIVE, TAB_COLONY]:
		_select_tab(requested)
	_ensure_inventory()
	_refresh_all()


func on_ui_exit() -> void:
	_pause_gameplay(false)
	if _inventory != null and _inventory.inventory_changed.is_connected(_on_inventory_changed):
		_inventory.inventory_changed.disconnect(_on_inventory_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_inventory"):
		_select_tab(TAB_PACK)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_archive"):
		_select_tab(TAB_ARCHIVE)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_wrist"):
		_cycle_tab()
		get_viewport().set_input_as_handled()


func get_active_tab() -> StringName:
	return _active_tab


func get_title_text() -> String:
	return _title.text if _title != null else ""


func get_pack_detail_text() -> String:
	return _pack_detail.text if _pack_detail != null else ""


func get_archive_count() -> int:
	return _archive_rows.get_child_count() if _archive_rows != null else 0


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.03, 0.03, 0.74)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(920, 520)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.075, 0.97)
	style.border_color = Color(0.30, 0.38, 0.38, 0.95)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	_title = _label("", 20, Color(0.47, 0.78, 0.85, 1.0))
	header.add_child(_title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_paused_label = _label(tr("WRIST_TIME_PAUSED"), 11, Color(0.88, 0.54, 0.24, 1.0))
	header.add_child(_paused_label)

	var close := Button.new()
	close.text = tr("WRIST_CLOSE")
	close.custom_minimum_size = Vector2(92, 30)
	close.pressed.connect(_close)
	header.add_child(close)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	root.add_child(tabs)
	for entry in [
		[TAB_PACK, "WRIST_TAB_PACK"],
		[TAB_ARCHIVE, "WRIST_TAB_ARCHIVE"],
		[TAB_COLONY, "WRIST_TAB_COLONY"],
	]:
		var button := Button.new()
		button.text = tr(entry[1])
		button.custom_minimum_size = Vector2(128, 32)
		button.pressed.connect(_select_tab.bind(entry[0]))
		tabs.add_child(button)
		_tab_buttons[entry[0]] = button

	var separator := HSeparator.new()
	root.add_child(separator)

	var content := Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)

	_pack_panel = _build_pack_panel()
	_archive_panel = _build_archive_panel()
	_colony_panel = _build_colony_panel()
	for child in [_pack_panel, _archive_panel, _colony_panel]:
		child.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.add_child(child)

	var footer := _label(tr("WRIST_FOOTER"), 11, Color(0.55, 0.62, 0.62, 1.0))
	root.add_child(footer)
	_select_tab(TAB_PACK)


func _build_pack_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 8)

	_pack_capacity = _label("", 12, Color(0.88, 0.54, 0.24, 1.0))
	panel.add_child(_pack_capacity)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)
	left.add_child(_label(tr("WRIST_EQUIPMENT"), 12, Color(0.47, 0.78, 0.85, 1.0)))
	var equipment := _label(tr("WRIST_EQUIPMENT_EMPTY"), 12, Color(0.70, 0.74, 0.74, 1.0))
	left.add_child(equipment)

	_pack_grid = GridContainer.new()
	_pack_grid.columns = 4
	_pack_grid.add_theme_constant_override("h_separation", 6)
	_pack_grid.add_theme_constant_override("v_separation", 6)
	left.add_child(_pack_grid)

	var detail_box := VBoxContainer.new()
	detail_box.custom_minimum_size = Vector2(280, 0)
	detail_box.add_theme_constant_override("separation", 6)
	body.add_child(detail_box)
	detail_box.add_child(_label(tr("WRIST_ITEM_DETAIL"), 12, Color(0.47, 0.78, 0.85, 1.0)))
	_pack_detail_icon = TextureRect.new()
	_pack_detail_icon.custom_minimum_size = Vector2(52, 52)
	_pack_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pack_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pack_detail_icon.visible = false
	detail_box.add_child(_pack_detail_icon)
	_pack_detail = _label(tr("WRIST_SELECT_ITEM"), 12, Color(0.86, 0.86, 0.82, 1.0))
	_pack_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pack_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(_pack_detail)
	detail_box.add_child(_label(tr("WRIST_ACTIONS_PENDING"), 11, Color(0.55, 0.62, 0.62, 1.0)))

	return panel


func _build_archive_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 8)
	_archive_status = _label(tr("WRIST_ARCHIVE_EMPTY"), 16, Color(0.88, 0.54, 0.24, 1.0))
	panel.add_child(_archive_status)
	var remote := _label(tr("WRIST_ARCHIVE_REMOTE"), 12, Color(0.70, 0.74, 0.74, 1.0))
	remote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(remote)
	panel.add_child(HSeparator.new())
	panel.add_child(_label(tr("WRIST_ARCHIVE_FRAGMENTS"), 12, Color(0.47, 0.78, 0.85, 1.0)))
	_archive_rows = VBoxContainer.new()
	_archive_rows.add_theme_constant_override("separation", 3)
	_archive_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(_archive_rows)
	return panel


func _build_colony_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 8)
	panel.add_child(_label(tr("WRIST_COLONY_OFFLINE"), 16, Color(0.88, 0.54, 0.24, 1.0)))
	_colony_summary = _label("", 13, Color(0.86, 0.86, 0.82, 1.0))
	_colony_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_colony_summary)
	return panel


func _ensure_inventory() -> void:
	var flow: Node = get_node_or_null("/root/GameFlow")
	var world_variant: Variant = flow.call("get_world") if flow != null else null
	var world: Node = null
	if world_variant != null and is_instance_valid(world_variant):
		world = world_variant as Node
	var player: Node = world.get_node_or_null("Player") if world != null else null
	var inv: InventoryContainer = null
	if player != null and is_instance_valid(player) and player.has_method("get_inventory"):
		inv = player.call("get_inventory") as InventoryContainer
	if inv == _inventory:
		return
	if _inventory != null and _inventory.inventory_changed.is_connected(_on_inventory_changed):
		_inventory.inventory_changed.disconnect(_on_inventory_changed)
	_inventory = inv
	if _inventory != null and not _inventory.inventory_changed.is_connected(_on_inventory_changed):
		_inventory.inventory_changed.connect(_on_inventory_changed)


func _refresh_all() -> void:
	_refresh_pack()
	_refresh_archive()
	_refresh_colony()
	_refresh_tabs()


func _refresh_tabs() -> void:
	_title.text = tr("WRIST_TITLE_" + String(_active_tab).to_upper())
	for tab in _tab_buttons:
		var button := _tab_buttons[tab] as Button
		if button != null:
			button.modulate = Color(1, 1, 1, 1) if tab == _active_tab else Color(0.62, 0.66, 0.66, 1)
	_pack_panel.visible = _active_tab == TAB_PACK
	_archive_panel.visible = _active_tab == TAB_ARCHIVE
	_colony_panel.visible = _active_tab == TAB_COLONY


func _refresh_pack() -> void:
	for child in _pack_grid.get_children():
		_pack_grid.remove_child(child)
		child.queue_free()
	var used := 0
	var slots: Array = []
	if _inventory != null:
		slots = _inventory.get_slots()
		for raw_slot in slots:
			var slot: Dictionary = raw_slot
			if StringName(slot.get("id", &"")) != &"" and int(slot.get("count", 0)) > 0:
				used += 1
	if _pack_capacity != null:
		var max_slots := _inventory.max_slots if _inventory != null and _inventory.max_slots > 0 else 16
		_pack_capacity.text = "%s  %d/%d" % [tr("WRIST_CAPACITY"), used, max_slots]
	for raw_slot in slots:
		var slot: Dictionary = raw_slot
		var item_id := StringName(slot.get("id", &""))
		var count := int(slot.get("count", 0))
		if item_id == &"" or count <= 0:
			continue
		_pack_grid.add_child(_make_item_button(item_id, count))
	var capacity := _inventory.max_slots if _inventory != null and _inventory.max_slots > 0 else 16
	var empty_slots := capacity - used
	for index in maxi(0, empty_slots):
		var empty := Button.new()
		empty.text = tr("WRIST_EMPTY_SLOT")
		empty.disabled = true
		empty.custom_minimum_size = Vector2(138, 54)
		_pack_grid.add_child(empty)
	if not _selected_item.is_empty() and (_inventory == null or _inventory.count_item(_selected_item) <= 0):
		_selected_item = &""
	_refresh_detail()


func _make_item_button(item_id: StringName, count: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(138, 54)
	button.tooltip_text = _pretty(item_id)
	button.pressed.connect(_select_item.bind(item_id))
	if item_id == _selected_item:
		button.modulate = Color(0.47, 0.78, 0.85, 1.0)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6.0
	row.offset_top = 4.0
	row.offset_right = -6.0
	row.offset_bottom = -4.0
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tags: Array = []
	if _inventory != null:
		var def := _inventory.get_item_def(item_id)
		if def != null:
			tags = def.tags
	icon.texture = ItemIcons.icon_for(item_id, tags)
	row.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 0)
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_box)

	var name_label := Label.new()
	name_label.text = _pretty(item_id)
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.93, 0.91, 0.86, 1.0))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(name_label)

	var count_label := Label.new()
	count_label.text = "x%d" % count
	count_label.add_theme_font_size_override("font_size", 10)
	count_label.add_theme_color_override("font_color", Color(0.47, 0.78, 0.85, 1.0))
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(count_label)

	return button


func _select_item(item_id: StringName) -> void:
	_selected_item = item_id
	_refresh_pack()


func _refresh_detail() -> void:
	if _pack_detail == null:
		return
	if _selected_item.is_empty() or _inventory == null:
		_pack_detail.text = tr("WRIST_SELECT_ITEM")
		if _pack_detail_icon != null:
			_pack_detail_icon.visible = false
			_pack_detail_icon.texture = null
		return
	var def := _inventory.get_item_def(_selected_item)
	var tags: Array = def.tags if def != null else []
	if _pack_detail_icon != null:
		_pack_detail_icon.texture = ItemIcons.icon_for(_selected_item, tags)
		_pack_detail_icon.visible = true
	var count := _inventory.count_item(_selected_item)
	var lines := PackedStringArray()
	lines.append(_pretty(_selected_item))
	lines.append("%s: %d" % [tr("WRIST_COUNT"), count])
	if def != null:
		var tag_text := ""
		for tag in def.tags:
			if tag_text != "":
				tag_text += ", "
			tag_text += String(tag)
		lines.append("%s: %s" % [tr("WRIST_TAGS"), tag_text])
		if def.max_stack > 1:
			lines.append("%s: %d" % [tr("WRIST_MAX_STACK"), def.max_stack])
	_pack_detail.text = "\n".join(lines)


func get_visible_icon_count() -> int:
	var count := 0
	if _pack_grid == null:
		return count
	for child in _pack_grid.get_children():
		for nested in child.find_children("*", "TextureRect", true, false):
			var icon := nested as TextureRect
			if icon != null and icon.texture != null:
				count += 1
	return count


func _refresh_archive() -> void:
	if _archive_rows == null or _archive_status == null:
		return
	for child in _archive_rows.get_children():
		_archive_rows.remove_child(child)
		child.queue_free()
	var techs: Array = GameContent.database().rows("tech")
	if techs.is_empty():
		_archive_status.text = tr("WRIST_ARCHIVE_EMPTY")
		return
	_archive_status.text = "%s // %d" % [tr("WRIST_ARCHIVE_FRAGMENTS"), techs.size()]
	for tech in techs:
		var row: Dictionary = tech
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		var name_label := _label(tr(str(row.get("display_name", row.get("id", "")))), 13, Color(0.86, 0.86, 0.82, 1.0))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		line.add_child(_label(_cost_text(row.get("costs", {})), 12, Color(0.88, 0.54, 0.24, 1.0)))
		var requires: Array = row.get("requires", []) as Array
		var state_text := tr("WRIST_AVAILABLE") if requires.is_empty() else "%s %s" % [tr("WRIST_REQUIRES"), _tech_name(str(requires[0]))]
		line.add_child(_label(state_text, 11, Color(0.55, 0.62, 0.62, 1.0)))
		_archive_rows.add_child(line)


func _cost_text(costs: Variant) -> String:
	if not costs is Dictionary:
		return ""
	var parts := PackedStringArray()
	for item_id in (costs as Dictionary):
		parts.append("%s %d" % [_pretty(StringName(item_id)), int((costs as Dictionary)[item_id])])
	return "  ".join(parts)


func _tech_name(tech_id: String) -> String:
	var row := GameContent.database().find("tech", tech_id)
	if not row.is_empty():
		return tr(str(row.get("display_name", tech_id)))
	return tech_id.capitalize()


func _refresh_colony() -> void:
	if _colony_summary == null:
		return
	var time := get_node_or_null("/root/WorldTime")
	var day := str(time.call("get_day_text")) if time != null else "DAY ---"
	var clock := str(time.call("get_clock_text")) if time != null else "--:--"
	var capacity := 16
	if _inventory != null and _inventory.max_slots > 0:
		capacity = _inventory.max_slots
	_colony_summary.text = "%s  %s\n%s: %s\n%s: %d\n%s: --" % [
		day,
		clock,
		tr("WRIST_POWER"),
		tr("WRIST_OFFLINE"),
		tr("WRIST_CARRY"),
		capacity,
		tr("WRIST_TECH"),
	]


func _select_tab(tab: StringName) -> void:
	if not tab in [TAB_PACK, TAB_ARCHIVE, TAB_COLONY]:
		return
	_active_tab = tab
	_refresh_all()


func _cycle_tab() -> void:
	var tabs := [TAB_PACK, TAB_ARCHIVE, TAB_COLONY]
	var index := tabs.find(_active_tab)
	_select_tab(tabs[(index + 1) % tabs.size()])


func _pause_gameplay(paused: bool) -> void:
	var flow := get_node_or_null("/root/GameFlow")
	var clock := get_node_or_null("/root/GameClock")
	if paused:
		if flow == null or int(flow.call("get_state")) != 3:
			return
		get_tree().paused = true
		if clock != null:
			clock.call("set_gameplay_running", false)
		return
	if flow != null and int(flow.call("get_state")) == 3:
		get_tree().paused = false
		if clock != null:
			clock.call("set_gameplay_running", true)


func _close() -> void:
	var ui := get_node_or_null("/root/UIRouter")
	if ui != null and StringName(ui.call("top_screen_id")) == &"wrist":
		ui.call("pop_screen")


func _on_inventory_changed() -> void:
	_refresh_pack()
	_refresh_colony()


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _pretty(item_id: StringName) -> String:
	if _inventory != null:
		var def := _inventory.get_item_def(item_id)
		if def != null and def.display_name != "":
			return tr(def.display_name)
	var raw := String(item_id).replace("_", " ")
	if raw.is_empty():
		return raw
	return raw.substr(0, 1).to_upper() + raw.substr(1)
