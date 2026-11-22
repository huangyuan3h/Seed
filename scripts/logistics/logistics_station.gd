class_name LogisticsStation
extends Interactable
## Transfer buffer between a machine and a truck. Pulls finished goods from a
## producer machine, pushes inputs into a consumer machine, and holds truck fuel.

signal state_changed
signal hint_requested(text: String)

const TRANSFER_PER_SECOND := 8.0
const FUEL_CAPACITY := 40

@export var station_id: StringName = &"station"
@export var display_name: String = "Logistics Station"
@export var capacity: int = 40
@export var power_draw: float = 0.25
@export var auto_tick: bool = true

var input: Dictionary = {} ## String item id -> count
var output: Dictionary = {} ## String item id -> count
var fuel: Dictionary = {} ## String item id -> count
var producer: FactoryMachine = null
var consumer: FactoryMachine = null
var road: RoadNetwork = null
var cell: Vector2i = Vector2i.ZERO

var _grid: PowerGrid = null
var _transfer_accum: float = 0.0
var _status: String = "Idle"
var _visual: Node3D = null
var _status_label: Label3D = null


func _ready() -> void:
	prompt_text = "Add Fuel"
	interaction_id = StringName("logistics_%s" % String(station_id))
	interaction_priority = 3
	_build_visual()
	super._ready()
	_refresh_visual()


func _exit_tree() -> void:
	if _grid != null:
		_grid.remove_consumer(self)


func _process(delta: float) -> void:
	if auto_tick:
		tick(delta)


func _on_interact(actor: Node) -> void:
	if actor == null or not actor.has_method("get_inventory"):
		hint_requested.emit("Station needs coal or wood for trucks.")
		return
	var inventory := actor.call("get_inventory") as InventoryContainer
	if inventory == null:
		return
	for raw_id in ["coal", "wood"]:
		var item_id := StringName(raw_id)
		var available := inventory.count_item(item_id)
		if available > 0:
			var amount := mini(5, available)
			inventory.remove_item(item_id, amount)
			add_fuel(item_id, amount)
			hint_requested.emit("Added %d %s to %s." % [amount, raw_id, display_name])
			return
	hint_requested.emit("Need coal or wood for the truck fuel buffer.")


func setup(id: StringName, station_name: String, p_road: RoadNetwork, grid: PowerGrid) -> void:
	station_id = id
	display_name = station_name
	road = p_road
	_grid = grid
	if road != null:
		var world_pos := global_position if is_inside_tree() else position
		cell = road.cell_for(world_pos)
	if _grid != null and not _grid_is_registered():
		_grid.add_consumer(self)
	_refresh_visual()


func bind_producer(machine: FactoryMachine) -> void:
	producer = machine
	_refresh_visual()


func bind_consumer(machine: FactoryMachine) -> void:
	consumer = machine
	_refresh_visual()


func get_power_demand() -> float:
	return maxf(0.0, power_draw)


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	_transfer_accum += delta * TRANSFER_PER_SECOND
	var budget := int(_transfer_accum)
	if budget <= 0:
		_refresh_status()
		return
	_transfer_accum -= float(budget)
	if producer != null:
		budget = _pull_from_producer(budget)
	if consumer != null and budget > 0:
		_push_to_consumer(budget)
	_refresh_status()


func add_fuel(item_id: StringName, amount: int = 1) -> int:
	var key := String(item_id)
	if amount <= 0 or (key != "coal" and key != "wood"):
		return 0
	var space := FUEL_CAPACITY - _total(fuel)
	var take := mini(amount, space)
	if take <= 0:
		return 0
	fuel[key] = int(fuel.get(key, 0)) + take
	_emit_changed()
	return take


func take_fuel(item_id: StringName, amount: int = 1) -> int:
	var key := String(item_id)
	var have := int(fuel.get(key, 0))
	var take := mini(have, maxi(0, amount))
	if take <= 0:
		return 0
	if have - take <= 0:
		fuel.erase(key)
	else:
		fuel[key] = have - take
	_emit_changed()
	return take


func get_fuel_count(item_id: StringName) -> int:
	return int(fuel.get(String(item_id), 0))


func add_input(item_id: StringName, amount: int) -> int:
	return _add_to(input, item_id, amount)


func take_input(item_id: StringName, amount: int) -> int:
	return _take_from(input, item_id, amount)


func add_output(item_id: StringName, amount: int) -> int:
	return _add_to(output, item_id, amount)


func take_output(item_id: StringName, amount: int) -> int:
	return _take_from(output, item_id, amount)


func get_input_count(item_id: StringName) -> int:
	return int(input.get(String(item_id), 0))


func get_output_count(item_id: StringName) -> int:
	return int(output.get(String(item_id), 0))


func get_status_text() -> String:
	return _status


func get_summary() -> String:
	return "In %d  Out %d  Fuel %d" % [_total(input), _total(output), _total(fuel)]


func _pull_from_producer(budget: int) -> int:
	if producer == null:
		return budget
	for raw_id in producer.get_outputs():
		if budget <= 0:
			break
		var space := capacity - _total(output)
		if space <= 0:
			break
		var key := String(raw_id)
		var available := producer.get_output_count(StringName(key))
		var take := mini(mini(available, budget), space)
		if take <= 0:
			continue
		var taken := producer.take_output(StringName(key), take)
		if taken <= 0:
			continue
		output[key] = int(output.get(key, 0)) + taken
		budget -= taken
		_emit_changed()
	return budget


func _push_to_consumer(budget: int) -> void:
	if consumer == null:
		return
	for raw_id in input.keys():
		if budget <= 0:
			break
		var key := String(raw_id)
		var available := int(input[key])
		var amount := mini(available, budget)
		if amount <= 0:
			continue
		var inserted := consumer.insert_item(StringName(key), amount)
		if inserted <= 0:
			continue
		var left := available - inserted
		if left <= 0:
			input.erase(key)
		else:
			input[key] = left
		budget -= inserted
		_emit_changed()


func _add_to(buffer: Dictionary, item_id: StringName, amount: int) -> int:
	var key := String(item_id)
	if amount <= 0:
		return 0
	var space := capacity - _total(buffer)
	var take := mini(amount, space)
	if take <= 0:
		return 0
	buffer[key] = int(buffer.get(key, 0)) + take
	_emit_changed()
	return take


func _take_from(buffer: Dictionary, item_id: StringName, amount: int) -> int:
	var key := String(item_id)
	var have := int(buffer.get(key, 0))
	var take := mini(have, maxi(0, amount))
	if take <= 0:
		return 0
	if have - take <= 0:
		buffer.erase(key)
	else:
		buffer[key] = have - take
	_emit_changed()
	return take


func _total(buffer: Dictionary) -> int:
	var total := 0
	for key in buffer:
		total += int(buffer[key])
	return total


func _grid_is_registered() -> bool:
	if _grid == null:
		return false
	return _grid.has_consumer(self)


func _emit_changed() -> void:
	_refresh_status()
	state_changed.emit()


func _refresh_status() -> void:
	_status = get_summary()
	_refresh_visual()


func _build_visual() -> void:
	if _visual != null:
		return
	_visual = Node3D.new()
	_visual.name = "StationVisual"
	add_child(_visual)

	var platform := MeshInstance3D.new()
	platform.name = "Platform"
	var box := BoxMesh.new()
	box.size = Vector3(2.0, 0.24, 2.0)
	platform.mesh = box
	platform.position = Vector3(0.0, 0.12, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.27, 0.33, 0.40)
	mat.roughness = 0.85
	platform.material_override = mat
	_visual.add_child(platform)

	var post := MeshInstance3D.new()
	post.name = "Post"
	var post_box := BoxMesh.new()
	post_box.size = Vector3(0.12, 1.2, 0.12)
	post.mesh = post_box
	post.position = Vector3(0.8, 0.6, 0.8)
	post.material_override = mat
	_visual.add_child(post)

	_status_label = Label3D.new()
	_status_label.name = "StatusLabel"
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 24
	_status_label.outline_size = 5
	_status_label.position = Vector3(0.0, 1.45, 0.0)
	_visual.add_child(_status_label)
	_refresh_visual()


func _refresh_visual() -> void:
	if _status_label == null:
		return
	_status_label.text = "%s\n%s" % [display_name, _status]
