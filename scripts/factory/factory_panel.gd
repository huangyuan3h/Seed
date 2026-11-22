class_name FactoryPanel
extends Control
## Minimal hand-feeding UI for a FactoryMachine: choose a recipe, insert inputs,
## collect outputs, and watch research progress.

signal closed

const CONTEXT_OWNER := &"factory_panel"
const UI_CONTEXT := 1

var _machine: FactoryMachine = null
var _inventory: InventoryContainer = null
var _state: FactoryState = null
var _open := false
var _context_pushed := false
var _refresh_queued := false

var _title_label: Label
var _status_label: Label
var _recipe_label: Label
var _recipe_option: OptionButton
var _inputs_title: Label
var _inputs_box: VBoxContainer
var _outputs_title: Label
var _outputs_box: VBoxContainer
var _progress: ProgressBar
var _close_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()


func _exit_tree() -> void:
	_pop_context()


func _unhandled_input(event: InputEvent) -> void:
	if not _open or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not _open or _machine == null:
		return
	_status_label.text = _machine.get_status_text()
	_progress.value = _machine.get_progress_ratio() * 100.0


func bind(machine: FactoryMachine, inventory: InventoryContainer, state: FactoryState) -> void:
	if _machine != null and _machine.state_changed.is_connected(_queue_refresh):
		_machine.state_changed.disconnect(_queue_refresh)
	_machine = machine
	_inventory = inventory
	_state = state
	if _machine != null:
		_machine.state_changed.connect(_queue_refresh)
		mouse_filter = Control.MOUSE_FILTER_STOP
		visible = true
		_open = true
		_push_context()
		_queue_refresh()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pop_context()
	closed.emit()


func is_open() -> bool:
	return _open


func _push_context() -> void:
	if _context_pushed:
		return
	var ir := get_node_or_null("/root/InputRouter")
	if ir != null and ir.has_method("push_context"):
		ir.call("push_context", UI_CONTEXT, CONTEXT_OWNER)
		_context_pushed = true


func _pop_context() -> void:
	if not _context_pushed:
		return
	var ir := get_node_or_null("/root/InputRouter")
	if ir != null and ir.has_method("pop_context"):
		ir.call("pop_context", CONTEXT_OWNER)
	_context_pushed = false


func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_do_refresh")


func _do_refresh() -> void:
	_refresh_queued = false
	if _machine == null:
		return
	_title_label.text = _machine.display_name
	_status_label.text = _machine.get_status_text()
	_progress.value = _machine.get_progress_ratio() * 100.0
	_rebuild_recipe_options()
	_rebuild_inputs()
	_rebuild_outputs()


func _rebuild_recipe_options() -> void:
	_recipe_option.set_block_signals(true)
	_recipe_option.clear()
	var rows := _machine.get_available_recipes()
	for row in rows:
		var id := StringName(str(row.get("id", "")))
		var label := str(row.get("display_name", String(id)))
		var index := _recipe_option.item_count
		_recipe_option.add_item(label)
		_recipe_option.set_item_metadata(index, String(id))
	var selected_id := _machine.get_selected_recipe_id()
	var selected_index := -1
	for i in range(_recipe_option.item_count):
		if StringName(str(_recipe_option.get_item_metadata(i))) == selected_id:
			selected_index = i
			break
	if selected_index >= 0:
		_recipe_option.select(selected_index)
	_recipe_option.disabled = rows.is_empty()
	_recipe_option.set_block_signals(false)
	if rows.is_empty():
		_recipe_label.text = "Technology" if _is_research() else "Recipe"
	else:
		_recipe_label.text = "Technology" if _is_research() else "Recipe"


func _rebuild_inputs() -> void:
	_clear_children(_inputs_box)
	var row := _machine.get_selected_recipe()
	_inputs_title.text = "Inputs"
	if row.is_empty():
		var empty := Label.new()
		empty.text = "No recipe selected."
		_inputs_box.add_child(empty)
		return
	for raw_id in (row.get("inputs", {}) as Dictionary):
		var item_id := StringName(str(raw_id))
		var need := int((row["inputs"] as Dictionary)[raw_id])
		var have := _machine.get_input_count(item_id)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = "%s  %d/%d" % [_item_name(item_id), have, need]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(label)

		var insert_one := Button.new()
		insert_one.text = "Insert 1"
		insert_one.pressed.connect(_on_insert.bind(item_id, 1))
		line.add_child(insert_one)

		var insert_ten := Button.new()
		insert_ten.text = "Insert 10"
		insert_ten.pressed.connect(_on_insert.bind(item_id, 10))
		line.add_child(insert_ten)

		var take_one := Button.new()
		take_one.text = "Take 1"
		take_one.pressed.connect(_on_take_input.bind(item_id, 1))
		line.add_child(take_one)

		_inputs_box.add_child(line)


func _rebuild_outputs() -> void:
	_clear_children(_outputs_box)
	var row := _machine.get_selected_recipe()
	_outputs_title.text = "Outputs"
	if row.is_empty():
		var empty := Label.new()
		empty.text = "—"
		_outputs_box.add_child(empty)
		return
	if _is_research():
		var unlocks := row.get("unlocks", []) as Array
		var names: Array[String] = []
		for raw in unlocks:
			names.append(str(raw))
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "Unlocks: %s" % (", ".join(names) if not names.is_empty() else "—")
		_outputs_box.add_child(label)
		return
	var outputs := row.get("outputs", {}) as Dictionary
	if outputs.is_empty():
		var label := Label.new()
		label.text = "—"
		_outputs_box.add_child(label)
		return
	for raw_id in outputs:
		var item_id := StringName(str(raw_id))
		var have := _machine.get_output_count(item_id)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		var label := Label.new()
		label.text = "%s  x%d" % [_item_name(item_id), have]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(label)
		var take := Button.new()
		take.text = "Take All"
		take.disabled = have <= 0
		take.pressed.connect(_on_take_output.bind(item_id))
		line.add_child(take)
		_outputs_box.add_child(line)


func _on_insert(item_id: StringName, amount: int) -> void:
	if _inventory == null:
		return
	var available := _inventory.count_item(item_id)
	if available <= 0:
		return
	var took := _machine.insert_item(item_id, mini(amount, available))
	if took > 0:
		_inventory.remove_item(item_id, took)
	_queue_refresh()


func _on_take_input(item_id: StringName, amount: int) -> void:
	var took := _machine.remove_input(item_id, amount)
	if took > 0 and _inventory != null:
		_inventory.add_item(item_id, took)
	_queue_refresh()


func _on_take_output(item_id: StringName) -> void:
	var took := _machine.take_output(item_id, _machine.get_output_count(item_id))
	if took > 0 and _inventory != null:
		_inventory.add_item(item_id, took)
	_queue_refresh()


func _on_recipe_selected(index: int) -> void:
	if _machine == null or index < 0:
		return
	var id := StringName(str(_recipe_option.get_item_metadata(index)))
	_machine.select_recipe(id)
	_queue_refresh()


func _is_research() -> bool:
	return String(_machine.allowed_station) == "research"


func _item_name(item_id: StringName) -> String:
	if _inventory != null:
		var def := _inventory.get_item_def(item_id)
		if def != null and def.display_name != "":
			return def.display_name
	return String(item_id).capitalize()


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _build_ui() -> void:
	var theme_path := "res://addons/gu_core/ui/default_theme.tres"
	if ResourceLoader.exists(theme_path):
		theme = load(theme_path) as Theme

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "FactoryPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -310.0
	panel.offset_right = 310.0
	panel.offset_top = -250.0
	panel.offset_bottom = 250.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_title_label)

	_status_label = Label.new()
	_status_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	vbox.add_child(_status_label)

	var recipe_line := HBoxContainer.new()
	recipe_line.add_theme_constant_override("separation", 10)
	vbox.add_child(recipe_line)

	_recipe_label = Label.new()
	_recipe_label.text = "Recipe"
	recipe_line.add_child(_recipe_label)

	_recipe_option = OptionButton.new()
	_recipe_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_recipe_option.item_selected.connect(_on_recipe_selected)
	recipe_line.add_child(_recipe_option)

	_inputs_title = Label.new()
	_inputs_title.text = "Inputs"
	vbox.add_child(_inputs_title)

	_inputs_box = VBoxContainer.new()
	_inputs_box.add_theme_constant_override("separation", 4)
	vbox.add_child(_inputs_box)

	_outputs_title = Label.new()
	_outputs_title.text = "Outputs"
	vbox.add_child(_outputs_title)

	_outputs_box = VBoxContainer.new()
	_outputs_box.add_theme_constant_override("separation", 4)
	vbox.add_child(_outputs_box)

	_progress = ProgressBar.new()
	_progress.min_value = 0.0
	_progress.max_value = 100.0
	_progress.value = 0.0
	vbox.add_child(_progress)

	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.pressed.connect(close)
	vbox.add_child(_close_button)
