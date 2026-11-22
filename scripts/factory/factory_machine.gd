class_name FactoryMachine
extends Interactable
## Generic hand-fed factory machine: input buffer, selected recipe, power draw,
## timed production, output buffer. Subclasses can hook _apply_completion().

signal state_changed
signal recipe_completed(recipe_id: StringName)
signal interaction_requested(machine: FactoryMachine, actor: Node)

@export var machine_id: StringName = &"machine"
@export var display_name: String = "Machine"
@export var allowed_station: StringName = &"smelter"
@export var power_draw: float = 0.0
@export var input_capacity: int = 20
@export var output_capacity: int = 20
@export var auto_start: bool = true
@export var auto_tick: bool = true

var _recipes: Array[Dictionary] = []
var _selected_recipe_id: StringName = &""
var _inputs: Dictionary = {} ## String item id -> count
var _outputs: Dictionary = {} ## String item id -> count
var _progress: float = 0.0
var _running: bool = false
var _status: String = "Idle"
var _factory_state: FactoryState = null
var _power_grid: PowerGrid = null

var _visual: Node3D = null
var _status_label: Label3D = null


func _ready() -> void:
	prompt_text = "Use %s" % display_name
	interaction_id = StringName("factory_%s" % String(machine_id))
	interaction_priority = 3
	_build_visual()
	super._ready()
	_refresh_visual()


func _exit_tree() -> void:
	if _power_grid != null:
		_power_grid.remove_consumer(self)


func _process(delta: float) -> void:
	if auto_tick:
		tick(delta)


func _on_interact(actor: Node) -> void:
	interaction_requested.emit(self, actor)


func setup(recipes: Array[Dictionary], state: FactoryState, grid: PowerGrid) -> void:
	if _power_grid != null:
		_power_grid.remove_consumer(self)
	_factory_state = state
	_power_grid = grid
	_recipes.clear()
	for row in recipes:
		if StringName(str(row.get("station", ""))) == allowed_station:
			_recipes.append(row.duplicate(true))
	if _power_grid != null:
		_power_grid.add_consumer(self)
	if _selected_recipe_id == &"" and not _recipes.is_empty():
		for candidate in _recipes:
			if _recipe_allowed(candidate):
				_selected_recipe_id = StringName(str(candidate.get("id", "")))
				break
		if _selected_recipe_id == &"":
			_selected_recipe_id = StringName(str(_recipes[0].get("id", "")))
	_set_status(_idle_status())
	state_changed.emit()
	_refresh_visual()


func get_power_demand() -> float:
	return maxf(0.0, power_draw)


func get_available_recipes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row in _recipes:
		if _recipe_allowed(row):
			out.append(row.duplicate(true))
	return out


func get_all_recipes() -> Array[Dictionary]:
	return _recipes.duplicate(true)


func get_selected_recipe_id() -> StringName:
	return _selected_recipe_id


func get_selected_recipe() -> Dictionary:
	return _find_recipe(_selected_recipe_id)


func select_recipe(recipe_id: StringName) -> bool:
	if _running:
		return false
	var row := _find_recipe(recipe_id)
	if row.is_empty() or not _recipe_allowed(row):
		return false
	_selected_recipe_id = recipe_id
	_progress = 0.0
	_set_status(_idle_status())
	state_changed.emit()
	_refresh_visual()
	return true


func insert_item(item_id: StringName, amount: int) -> int:
	if amount <= 0:
		return 0
	var key := String(item_id)
	if not _accepted_inputs().has(key):
		return 0
	var space := input_capacity - _total_inputs()
	if space <= 0:
		return 0
	var take := mini(amount, space)
	_inputs[key] = int(_inputs.get(key, 0)) + take
	_set_status(_idle_status())
	state_changed.emit()
	_refresh_visual()
	return take


func remove_input(item_id: StringName, amount: int) -> int:
	var key := String(item_id)
	var have := int(_inputs.get(key, 0))
	if have <= 0 or amount <= 0:
		return 0
	var take := mini(have, amount)
	var left := have - take
	if left <= 0:
		_inputs.erase(key)
	else:
		_inputs[key] = left
	state_changed.emit()
	_refresh_visual()
	return take


func take_output(item_id: StringName, amount: int) -> int:
	var key := String(item_id)
	var have := int(_outputs.get(key, 0))
	if have <= 0 or amount <= 0:
		return 0
	var take := mini(have, amount)
	var left := have - take
	if left <= 0:
		_outputs.erase(key)
	else:
		_outputs[key] = left
	state_changed.emit()
	_refresh_visual()
	return take


func get_input_count(item_id: StringName) -> int:
	return int(_inputs.get(String(item_id), 0))


func get_output_count(item_id: StringName) -> int:
	return int(_outputs.get(String(item_id), 0))


func get_inputs() -> Dictionary:
	return _inputs.duplicate(true)


func get_outputs() -> Dictionary:
	return _outputs.duplicate(true)


func get_status_text() -> String:
	return _status


func get_progress_ratio() -> float:
	var row := get_selected_recipe()
	if row.is_empty():
		return 0.0
	var seconds := maxf(0.001, float(row.get("seconds", 1.0)))
	return clampf(_progress / seconds, 0.0, 1.0)


func is_running() -> bool:
	return _running


func can_start() -> bool:
	if _running:
		return false
	var row := get_selected_recipe()
	if row.is_empty() or not _recipe_allowed(row):
		return false
	if not _has_inputs(row):
		return false
	if not _has_output_space(row):
		return false
	if _power_grid != null and _power_grid.get_satisfaction() <= 0.0:
		return false
	return true


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	if not _running:
		if auto_start and can_start():
			_start_recipe()
		else:
			_set_status(_idle_status())
		return

	var satisfaction := 1.0
	if _power_grid != null:
		satisfaction = _power_grid.get_satisfaction()
	if satisfaction <= 0.0:
		_set_status("No power")
		return

	var row := get_selected_recipe()
	if row.is_empty():
		_running = false
		_set_status("No recipe")
		return
	var seconds := maxf(0.001, float(row.get("seconds", 1.0)))
	_progress += delta * satisfaction
	if _progress >= seconds:
		_complete_recipe(row)
	else:
		_status = "Running %d%%" % int(round(get_progress_ratio() * 100.0))
		_refresh_visual()


func _start_recipe() -> bool:
	var row := get_selected_recipe()
	if row.is_empty() or not can_start():
		return false
	for raw_id in (row.get("inputs", {}) as Dictionary):
		var key := String(raw_id)
		var need := int((row["inputs"] as Dictionary)[raw_id])
		_inputs[key] = maxi(0, int(_inputs.get(key, 0)) - need)
		if int(_inputs[key]) <= 0:
			_inputs.erase(key)
	_running = true
	_progress = 0.0
	_set_status("Running 0%")
	state_changed.emit()
	_refresh_visual()
	return true


func _complete_recipe(row: Dictionary) -> void:
	for raw_id in (row.get("outputs", {}) as Dictionary):
		var key := String(raw_id)
		var amount := int((row["outputs"] as Dictionary)[raw_id])
		_outputs[key] = int(_outputs.get(key, 0)) + amount
	_running = false
	_progress = 0.0
	_apply_completion(row)
	_set_status("Done")
	recipe_completed.emit(StringName(str(row.get("id", ""))))
	state_changed.emit()
	_refresh_visual()
	if auto_start and can_start():
		_start_recipe()


func _apply_completion(_row: Dictionary) -> void:
	pass


func _recipe_allowed(row: Dictionary) -> bool:
	var tech_id := StringName(str(row.get("id", "")))
	if bool(row.get("is_tech", false)) and _factory_state != null:
		if _factory_state.is_unlocked(tech_id):
			return false
	var required_tech := StringName(str(row.get("requires_tech", "")))
	if required_tech != &"" and _factory_state != null:
		if not _factory_state.is_unlocked(required_tech):
			return false
	for raw_req in row.get("requires", []) as Array:
		var req := StringName(str(raw_req))
		if req != &"" and _factory_state != null and not _factory_state.is_unlocked(req):
			return false
	return true


func _accepted_inputs() -> Dictionary:
	var out: Dictionary = {}
	var rows: Array[Dictionary] = []
	if _selected_recipe_id != &"":
		var row := get_selected_recipe()
		if not row.is_empty():
			rows.append(row)
	if rows.is_empty():
		rows = get_available_recipes()
	for row in rows:
		for raw_id in (row.get("inputs", {}) as Dictionary):
			out[String(raw_id)] = true
	return out


func _has_inputs(row: Dictionary) -> bool:
	for raw_id in (row.get("inputs", {}) as Dictionary):
		var key := String(raw_id)
		var need := int((row["inputs"] as Dictionary)[raw_id])
		if int(_inputs.get(key, 0)) < need:
			return false
	return true


func _has_output_space(row: Dictionary) -> bool:
	var need := 0
	for raw_id in (row.get("outputs", {}) as Dictionary):
		need += int((row["outputs"] as Dictionary)[raw_id])
	return need <= 0 or _total_outputs() + need <= output_capacity


func _total_inputs() -> int:
	var total := 0
	for key in _inputs:
		total += int(_inputs[key])
	return total


func _total_outputs() -> int:
	var total := 0
	for key in _outputs:
		total += int(_outputs[key])
	return total


func _find_recipe(recipe_id: StringName) -> Dictionary:
	for row in _recipes:
		if StringName(str(row.get("id", ""))) == recipe_id:
			return row
	return {}


func _idle_status() -> String:
	var row := get_selected_recipe()
	if row.is_empty():
		return "Idle"
	if not _has_inputs(row):
		return "Need %s" % _first_missing_input(row)
	if not _has_output_space(row):
		return "Output full"
	if _power_grid != null and _power_grid.get_satisfaction() <= 0.0:
		return "No power"
	return "Ready"


func _first_missing_input(row: Dictionary) -> String:
	for raw_id in (row.get("inputs", {}) as Dictionary):
		var key := String(raw_id)
		var need := int((row["inputs"] as Dictionary)[raw_id])
		if int(_inputs.get(key, 0)) < need:
			return key
	return "inputs"


func _set_status(text: String) -> void:
	if text == _status:
		return
	_status = text
	_refresh_visual()
	state_changed.emit()


func _build_visual() -> void:
	if _visual != null:
		return
	_visual = Node3D.new()
	_visual.name = "FactoryVisual"
	add_child(_visual)

	var mesh := MeshInstance3D.new()
	mesh.name = "Body"
	var box := BoxMesh.new()
	box.size = Vector3(1.2, 1.0, 1.2)
	mesh.mesh = box
	mesh.position = Vector3(0.0, 0.5, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _station_color()
	mat.roughness = 0.75
	mat.metallic = 0.15
	mesh.material_override = mat
	_visual.add_child(mesh)

	_status_label = Label3D.new()
	_status_label.name = "StatusLabel"
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 28
	_status_label.outline_size = 6
	_status_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_status_label.position = Vector3(0.0, 1.6, 0.0)
	_visual.add_child(_status_label)
	_refresh_visual()


func _refresh_visual() -> void:
	if _status_label == null:
		return
	_status_label.text = "%s\n%s" % [display_name, _status]


func _station_color() -> Color:
	match String(allowed_station):
		"smelter":
			return Color(0.72, 0.38, 0.22)
		"workbench":
			return Color(0.32, 0.46, 0.66)
		"research":
			return Color(0.24, 0.62, 0.58)
		_:
			return Color(0.55, 0.55, 0.58)
