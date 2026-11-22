class_name SeedHud
extends CanvasLayer
## Always-on HUD: local time, vitals, objective, hotbar, pinned resources.
##
## The wrist computer is a separate UIRouter screen; this HUD only handles the
## gameplay layer and the keys that open it.

const WRIST_SCREEN_ID := &"wrist"
const THEME_PATH := "res://addons/gu_core/ui/default_theme.tres"

var _time: Node
var _stats: StatSet
var _inventory: InventoryContainer
var _tracker: QuestTracker

var _clock_label: Label
var _day_label: Label
var _phase_label: Label
var _countdown_label: Label
var _status_label: Label
var _vitals: VBoxContainer
var _objective: QuestHud
var _hotbar: Hotbar
var _selected_label: Label
var _resources: ResourceStrip
var _vital_rows: Dictionary = {}


func _init() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(THEME_PATH):
		root.theme = load(THEME_PATH)
	add_child(root)
	_build_top_bar(root)
	_build_vitals(root)
	_build_objective(root)
	_build_bottom(root)


func _enter_tree() -> void:
	_register_actions()


func _exit_tree() -> void:
	_disconnect_time()
	if _inventory != null and _inventory.inventory_changed.is_connected(_on_inventory_changed):
		_inventory.inventory_changed.disconnect(_on_inventory_changed)


func bind_player_hud(stats: StatSet, inv: InventoryContainer, tracker: QuestTracker, time: Node = null) -> void:
	_stats = stats
	_inventory = inv
	_tracker = tracker
	_time = time if time != null else get_node_or_null("/root/WorldTime")
	_rebuild_vitals()
	if _objective != null:
		_objective.bind_tracker(_tracker)
	if _inventory != null:
		if not _inventory.inventory_changed.is_connected(_on_inventory_changed):
			_inventory.inventory_changed.connect(_on_inventory_changed)
		_hotbar.bind_inventory(_inventory)
		_resources.bind_inventory(_inventory)
	_disconnect_time()
	if _time != null:
		if not _time.is_connected("minute_changed", _on_time_changed):
			_time.connect("minute_changed", _on_time_changed)
		if not _time.is_connected("phase_changed", _on_phase_changed):
			_time.connect("phase_changed", _on_phase_changed)
	_refresh_clock()
	_refresh_countdown()


func get_clock_text() -> String:
	return _clock_label.text if _clock_label != null else ""


func get_day_text() -> String:
	return _day_label.text if _day_label != null else ""


func get_phase_text() -> String:
	return _phase_label.text if _phase_label != null else ""


func get_vital_text(stat_id: StringName) -> String:
	var row := _vital_rows.get(stat_id) as VitalRow
	return row.get_value_text() if row != null else ""


func get_hotbar() -> Hotbar:
	return _hotbar


func get_resources() -> ResourceStrip:
	return _resources


func set_selected_text(text: String) -> void:
	if _selected_label != null:
		_selected_label.text = text
		_selected_label.visible = text != ""


func get_selected_text() -> String:
	return _selected_label.text if _selected_label != null else ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not event.is_action_pressed("toggle_inventory") \
			and not event.is_action_pressed("toggle_archive") \
			and not event.is_action_pressed("toggle_wrist"):
		return
	var router := get_node_or_null("/root/InputRouter")
	if router != null and not bool(router.call("is_gameplay_active")):
		return
	var ui := get_node_or_null("/root/UIRouter")
	if ui == null or bool(ui.call("is_open")):
		return
	var tab := &"pack"
	if event.is_action_pressed("toggle_archive"):
		tab = &"archive"
	_open_wrist(tab)
	get_viewport().set_input_as_handled()


func _open_wrist(tab: StringName) -> void:
	var flow := get_node_or_null("/root/GameFlow")
	if flow != null and int(flow.call("get_state")) != 3:
		return
	var ui := get_node_or_null("/root/UIRouter")
	if ui == null or not bool(ui.call("has_registered", WRIST_SCREEN_ID)):
		return
	ui.call("push_screen", WRIST_SCREEN_ID, {"tab": tab}, 1)


func _register_actions() -> void:
	var router := get_node_or_null("/root/InputRouter")
	if router == null or not router.has_method("register_action"):
		return
	router.call("register_action", &"toggle_inventory", [KEY_I], "Inventory")
	router.call("register_action", &"toggle_archive", [KEY_T], "Archive")
	router.call("register_action", &"toggle_wrist", [KEY_TAB], "Wrist Computer")


func _build_top_bar(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.name = "TopBar"
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 16.0
	panel.offset_top = 16.0
	panel.offset_right = -16.0
	panel.offset_bottom = 56.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.08, 0.78)
	style.border_color = Color(0.23, 0.28, 0.28, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	_day_label = _make_label("", 15, Color(0.47, 0.78, 0.85, 1.0))
	_clock_label = _make_label("", 15, Color(0.93, 0.91, 0.86, 1.0))
	_phase_label = _make_label("", 12, Color(0.88, 0.54, 0.24, 1.0))
	_countdown_label = _make_label("", 11, Color(0.88, 0.54, 0.24, 1.0))
	row.add_child(_day_label)
	row.add_child(_clock_label)
	row.add_child(_phase_label)
	row.add_child(_countdown_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	_status_label = _make_label("", 11, Color(0.47, 0.78, 0.85, 1.0))
	row.add_child(_status_label)


func _build_vitals(root: Control) -> void:
	_vitals = VBoxContainer.new()
	_vitals.name = "Vitals"
	_vitals.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_vitals.offset_left = 18.0
	_vitals.offset_top = 66.0
	_vitals.offset_right = 270.0
	_vitals.offset_bottom = 170.0
	_vitals.add_theme_constant_override("separation", 4)
	_vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_vitals)


func _build_objective(root: Control) -> void:
	_objective = QuestHud.new()
	_objective.name = "Objective"
	_objective.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_objective.offset_left = -300.0
	_objective.offset_top = 66.0
	_objective.offset_right = -16.0
	_objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_objective)


func _build_bottom(root: Control) -> void:
	var bar := VBoxContainer.new()
	bar.name = "HotbarRoot"
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.offset_left = -180.0
	bar.offset_top = -100.0
	bar.offset_right = 180.0
	bar.offset_bottom = -16.0
	bar.add_theme_constant_override("separation", 2)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)

	_selected_label = _make_label("", 11, Color(0.88, 0.54, 0.24, 1.0))
	_selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selected_label.visible = false
	bar.add_child(_selected_label)

	_hotbar = Hotbar.new()
	_hotbar.name = "Hotbar"
	_hotbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hotbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(_hotbar)

	_resources = ResourceStrip.new()
	_resources.name = "PinnedResources"
	_resources.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_resources.offset_left = -324.0
	_resources.offset_top = -50.0
	_resources.offset_right = -16.0
	_resources.offset_bottom = -16.0
	_resources.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_resources)


func _rebuild_vitals() -> void:
	for child in _vitals.get_children():
		_vitals.remove_child(child)
		child.queue_free()
	_vital_rows.clear()
	if _stats == null:
		return
	_add_vital(&"hp", "HUD_HP", Color(0.71, 0.28, 0.25, 1.0))
	_add_vital(&"hunger", "Hunger", Color(0.88, 0.54, 0.24, 1.0))
	_add_vital(&"stamina", "Stamina", Color(0.47, 0.78, 0.85, 1.0))


func _add_vital(stat_id: StringName, title_key: String, color: Color) -> void:
	if _stats == null or not _stats.has_stat(stat_id):
		return
	var row := VitalRow.new()
	_vitals.add_child(row)
	row.bind_stat(_stats, stat_id, title_key, color)
	_vital_rows[stat_id] = row


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_time_changed(_day: int, _hour: int, _minute: int) -> void:
	_refresh_clock()
	_refresh_countdown()


func _on_phase_changed(_phase: StringName) -> void:
	_refresh_clock()
	_refresh_countdown()


func _on_inventory_changed() -> void:
	# ResourceStrip and Hotbar subscribe directly; kept for future HUD aggregates.
	pass


func _refresh_clock() -> void:
	if _time == null:
		return
	_day_label.text = str(_time.call("get_day_text"))
	_clock_label.text = str(_time.call("get_clock_text"))
	var phase := str(_time.call("get_phase"))
	_phase_label.text = tr("HUD_PHASE_" + phase.to_upper())
	if _status_label != null:
		_status_label.text = tr("HUD_AI_ONLINE")


func _refresh_countdown() -> void:
	if _time == null or _countdown_label == null:
		return
	var phase := str(_time.call("get_phase"))
	if phase == "night":
		var to_dawn := float(_time.call("seconds_to_game_hours", _time.call("seconds_until_dawn")))
		_countdown_label.text = "%s %s" % [tr("HUD_DAWN_IN"), _format_eta(to_dawn)]
		_countdown_label.visible = true
	else:
		var to_night := float(_time.call("seconds_to_game_hours", _time.call("seconds_until_night")))
		_countdown_label.text = "%s %s" % [tr("HUD_NIGHT_IN"), _format_eta(to_night)]
		_countdown_label.visible = to_night <= 3.0


func _format_eta(hours: float) -> String:
	var total_minutes := maxi(0, int(ceil(hours * 60.0)))
	return "%02d:%02d" % [int(total_minutes / 60), total_minutes % 60]


func _disconnect_time() -> void:
	if _time == null:
		return
	if _time.is_connected("minute_changed", _on_time_changed):
		_time.disconnect("minute_changed", _on_time_changed)
	if _time.is_connected("phase_changed", _on_phase_changed):
		_time.disconnect("phase_changed", _on_phase_changed)
