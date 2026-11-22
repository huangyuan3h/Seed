class_name ThermalGenerator
extends Interactable
## Chapter-1 bootstrap generator. Burns wood or coal and supplies 20 power.

signal state_changed
signal hint_requested(text: String)

const POWER_OUTPUT := 20.0

@export var fuel_seconds: Dictionary = {"wood": 5.0, "coal": 30.0}
@export var auto_tick: bool = true

var _fuel: Dictionary = {} ## String item id -> count
var _burn_item: String = ""
var _burn_left: float = 0.0
var _grid: PowerGrid = null
var _status: String = "No fuel"

var _visual: Node3D = null
var _status_label: Label3D = null


func _ready() -> void:
	prompt_text = "Add Fuel"
	interaction_id = "thermal_generator_machine"
	interaction_priority = 3
	_build_visual()
	super._ready()
	_refresh_visual()


func _exit_tree() -> void:
	if _grid != null:
		_grid.remove_generator(self)


func _process(delta: float) -> void:
	if auto_tick:
		tick(delta)


func _on_interact(actor: Node) -> void:
	if actor == null or not actor.has_method("get_inventory"):
		hint_requested.emit("The generator needs wood or coal.")
		return
	var inventory := actor.call("get_inventory") as InventoryContainer
	if inventory == null:
		hint_requested.emit("The generator needs wood or coal.")
		return
	for raw_id in ["coal", "wood"]:
		var item_id := StringName(raw_id)
		var available := inventory.count_item(item_id)
		if available > 0:
			var amount := mini(5, available)
			inventory.remove_item(item_id, amount)
			add_fuel(item_id, amount)
			hint_requested.emit("Added %d %s." % [amount, raw_id])
			return
	hint_requested.emit("Need coal or wood for the generator.")


func setup(grid: PowerGrid) -> void:
	if _grid != null:
		_grid.remove_generator(self)
	_grid = grid
	if _grid != null:
		_grid.add_generator(self)
	_refresh_supply()


func add_fuel(item_id: StringName, amount: int = 1) -> int:
	var key := String(item_id)
	if amount <= 0 or not fuel_seconds.has(key):
		return 0
	_fuel[key] = int(_fuel.get(key, 0)) + amount
	state_changed.emit()
	_refresh_visual()
	return amount


func get_fuel_count(item_id: StringName) -> int:
	return int(_fuel.get(String(item_id), 0))


func get_total_fuel() -> int:
	var total := 0
	for key in _fuel:
		total += int(_fuel[key])
	return total


func get_status_text() -> String:
	return _status


func get_power_supply() -> float:
	return POWER_OUTPUT if _burn_left > 0.0 else 0.0


func tick(delta: float) -> void:
	if _burn_left <= 0.0:
		_consume_next_fuel()
	if _burn_left <= 0.0:
		_set_status("No fuel")
		_refresh_supply()
		return
	_burn_left = maxf(0.0, _burn_left - delta)
	if _burn_left <= 0.0:
		_burn_item = ""
		_consume_next_fuel()
		if _burn_left <= 0.0:
			_set_status("No fuel")
		else:
			_set_status("Burning %s (%.0fs)" % [_burn_item.capitalize(), _burn_left])
	else:
		_set_status("Burning %s (%.0fs)" % [_burn_item.capitalize(), _burn_left])
	_refresh_supply()


func _consume_next_fuel() -> void:
	for key in ["coal", "wood"]:
		if int(_fuel.get(key, 0)) > 0:
			_fuel[key] = int(_fuel[key]) - 1
			_burn_item = key
			_burn_left = maxf(0.1, float(fuel_seconds.get(key, 5.0)))
			if int(_fuel[key]) <= 0:
				_fuel.erase(key)
			state_changed.emit()
			_refresh_visual()
			return


func _refresh_supply() -> void:
	if _grid != null:
		_grid.refresh()


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
	_visual.name = "GeneratorVisual"
	add_child(_visual)

	var body := MeshInstance3D.new()
	body.name = "Body"
	var box := BoxMesh.new()
	box.size = Vector3(1.4, 1.0, 1.4)
	body.mesh = box
	body.position = Vector3(0.0, 0.5, 0.0)
	body.material_override = _make_material(Color(0.78, 0.62, 0.18))
	_visual.add_child(body)

	var chimney := MeshInstance3D.new()
	chimney.name = "Chimney"
	var pipe := CylinderMesh.new()
	pipe.top_radius = 0.14
	pipe.bottom_radius = 0.18
	pipe.height = 1.2
	chimney.mesh = pipe
	chimney.position = Vector3(0.42, 1.55, 0.0)
	chimney.material_override = _make_material(Color(0.35, 0.33, 0.30))
	_visual.add_child(chimney)

	_status_label = Label3D.new()
	_status_label.name = "StatusLabel"
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 28
	_status_label.outline_size = 6
	_status_label.position = Vector3(0.0, 2.25, 0.0)
	_visual.add_child(_status_label)
	_refresh_visual()


func _make_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mat.metallic = 0.1
	return mat


func _refresh_visual() -> void:
	if _status_label == null:
		return
	_status_label.text = "Thermal Generator\n%s" % _status
