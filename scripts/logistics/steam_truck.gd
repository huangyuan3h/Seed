class_name SteamTruck
extends Node3D
## First logistics vehicle: a coal/wood-fired flatbed that carries one item
## type between a pickup station and a dropoff station.

signal state_changed

const CAPACITY := 12
const SPEED := 4.0
const COAL_SECONDS := 60.0
const WOOD_SECONDS := 15.0

@export var truck_id: StringName = &"truck"
@export var display_name: String = "Steam Truck"
@export var auto_tick: bool = true

var pickup: LogisticsStation = null
var dropoff: LogisticsStation = null
var item_id: StringName = &""
var road: RoadNetwork = null
var cargo: Dictionary = {} ## String item id -> count

var _path: Array[Vector3] = []
var _path_index: int = 0
var _state: StringName = &"idle"
var _wait: float = 0.0
var _fuel_left: float = 0.0
var _status: String = "Idle"

var _visual: Node3D = null
var _status_label: Label3D = null
var _cargo_mesh: MeshInstance3D = null


func _ready() -> void:
	_build_visual()
	_refresh_visual()


func _process(delta: float) -> void:
	if auto_tick:
		tick(delta)


func assign_route(
	p_pickup: LogisticsStation,
	p_dropoff: LogisticsStation,
	p_item: StringName,
	p_road: RoadNetwork
) -> bool:
	if p_pickup == null or p_dropoff == null or p_item == &"":
		return false
	pickup = p_pickup
	dropoff = p_dropoff
	item_id = p_item
	road = p_road
	cargo.clear()
	_path.clear()
	_path_index = 0
	_wait = 0.0
	_state = &"to_pickup"
	if road != null:
		_path = road.find_path_world(_node_world(pickup), _node_world(dropoff))
	_path = _sanitize_path(_path)
	_set_self_world(_node_world(pickup) + Vector3(0.0, 0.45, 0.0))
	_set_status("To pickup")
	state_changed.emit()
	return true


func tick(delta: float) -> void:
	if delta <= 0.0 or pickup == null or dropoff == null or item_id == &"":
		return
	if _fuel_left > 0.0:
		_fuel_left = maxf(0.0, _fuel_left - delta)
	match _state:
		&"to_pickup":
			_move_along(delta)
			if _arrived():
				_state = &"loading"
				_wait = 0.4
				_set_status("Loading")
		&"loading":
			_wait = maxf(0.0, _wait - delta)
			if _wait <= 0.0:
				_try_load()
		&"waiting_cargo":
			_try_load()
		&"no_fuel":
			if _at_station(pickup):
				_try_load()
			else:
				_set_status("Out of fuel")
		&"to_dropoff":
			_move_along(delta)
			if _arrived():
				_state = &"unloading"
				_wait = 0.4
				_set_status("Unloading")
		&"unloading":
			_wait = maxf(0.0, _wait - delta)
			if _wait <= 0.0:
				_try_unload()
		_:
			_set_status("Idle")


func get_status_text() -> String:
	return _status


func get_route_text() -> String:
	if pickup == null or dropoff == null or item_id == &"":
		return "No route"
	return "%s -> %s  (%s)" % [pickup.display_name, dropoff.display_name, String(item_id)]


func get_cargo_count() -> int:
	var total := 0
	for key in cargo:
		total += int(cargo[key])
	return total


func get_fuel_seconds() -> float:
	return _fuel_left


func has_route() -> bool:
	return pickup != null and dropoff != null and item_id != &""


func _try_load() -> void:
	if not _ensure_fuel():
		_state = &"no_fuel"
		_set_status("No fuel at pickup")
		return
	var available := pickup.get_output_count(item_id)
	if available <= 0:
		_state = &"waiting_cargo"
		_set_status("Waiting for %s" % String(item_id))
		return
	var taken := pickup.take_output(item_id, mini(CAPACITY, available))
	if taken <= 0:
		_state = &"waiting_cargo"
		return
	cargo[String(item_id)] = int(cargo.get(String(item_id), 0)) + taken
	if road != null:
		_path = _sanitize_path(road.find_path_world(_node_world(pickup), _node_world(dropoff)))
	else:
		_path.clear()
	_path_index = 0
	_state = &"to_dropoff" if not _path.is_empty() else &"unloading"
	_wait = 0.4
	_set_status("Carrying %d %s" % [taken, String(item_id)])
	state_changed.emit()


func _try_unload() -> void:
	var key := String(item_id)
	var amount := int(cargo.get(key, 0))
	if amount <= 0:
		cargo.clear()
		_state = &"to_pickup"
		if road != null:
			_path = _sanitize_path(road.find_path_world(_node_world(dropoff), _node_world(pickup)))
		else:
			_path.clear()
		_path_index = 0
		_set_status("To pickup")
		return
	var added := dropoff.add_input(item_id, amount)
	if added <= 0:
		_state = &"unloading"
		_wait = 0.5
		_set_status("Dropoff full")
		return
	amount -= added
	if amount <= 0:
		cargo.erase(key)
		_state = &"to_pickup"
		if road != null:
			_path = _sanitize_path(road.find_path_world(_node_world(dropoff), _node_world(pickup)))
		else:
			_path.clear()
		_path_index = 0
		_set_status("To pickup")
	else:
		cargo[key] = amount
		_state = &"unloading"
		_wait = 0.5
		_set_status("Unloading %d left" % amount)
	state_changed.emit()


func _ensure_fuel() -> bool:
	if _fuel_left > 0.0:
		return true
	if pickup == null:
		return false
	if pickup.get_fuel_count(&"coal") > 0:
		if pickup.take_fuel(&"coal", 1) > 0:
			_fuel_left = COAL_SECONDS
			return true
	if pickup.get_fuel_count(&"wood") > 0:
		if pickup.take_fuel(&"wood", 1) > 0:
			_fuel_left = WOOD_SECONDS
			return true
	return false


func _move_along(delta: float) -> void:
	if _path.is_empty() or _path_index >= _path.size():
		return
	var target := _path[_path_index]
	var speed := SPEED * (0.5 if _fuel_left <= 0.0 else 1.0)
	var here := _self_world()
	var next_pos := here.move_toward(target, speed * delta)
	_set_self_world(next_pos)
	if next_pos.distance_to(target) <= 0.12:
		_path_index += 1


func _arrived() -> bool:
	return _path.is_empty() or _path_index >= _path.size()


func _at_station(station: LogisticsStation) -> bool:
	if station == null:
		return false
	var a := _self_world()
	var b := _node_world(station)
	return Vector2(a.x - b.x, a.z - b.z).length() <= 0.9


func _node_world(node: Node3D) -> Vector3:
	if node == null:
		return Vector3.ZERO
	return node.global_position if node.is_inside_tree() else node.position


func _self_world() -> Vector3:
	return global_position if is_inside_tree() else position


func _set_self_world(world: Vector3) -> void:
	if is_inside_tree():
		global_position = world
	else:
		position = world


func _sanitize_path(points: Array[Vector3]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for point in points:
		var p := point
		p.y = 0.45
		out.append(p)
	return out


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
	_visual.name = "TruckVisual"
	add_child(_visual)

	var body := MeshInstance3D.new()
	body.name = "Body"
	var box := BoxMesh.new()
	box.size = Vector3(1.35, 0.45, 0.75)
	body.mesh = box
	body.position = Vector3(0.0, 0.05, 0.0)
	body.material_override = _make_material(Color(0.34, 0.27, 0.20))
	_visual.add_child(body)

	var cargo := MeshInstance3D.new()
	cargo.name = "Cargo"
	var cargo_box := BoxMesh.new()
	cargo_box.size = Vector3(0.75, 0.35, 0.62)
	cargo.mesh = cargo_box
	cargo.position = Vector3(-0.22, 0.42, 0.0)
	cargo.material_override = _make_material(Color(0.55, 0.42, 0.22))
	_visual.add_child(cargo)
	_cargo_mesh = cargo

	var chimney := MeshInstance3D.new()
	chimney.name = "Chimney"
	var pipe := CylinderMesh.new()
	pipe.top_radius = 0.08
	pipe.bottom_radius = 0.10
	pipe.height = 0.48
	chimney.mesh = pipe
	chimney.position = Vector3(0.48, 0.48, 0.0)
	chimney.material_override = _make_material(Color(0.18, 0.17, 0.16))
	_visual.add_child(chimney)

	for z in [-0.34, 0.34]:
		for x in [-0.42, 0.42]:
			var wheel := MeshInstance3D.new()
			wheel.name = "Wheel"
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.16
			cyl.bottom_radius = 0.16
			cyl.height = 0.12
			wheel.mesh = cyl
			wheel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
			wheel.position = Vector3(x, -0.18, z)
			wheel.material_override = _make_material(Color(0.10, 0.10, 0.10))
			_visual.add_child(wheel)

	_status_label = Label3D.new()
	_status_label.name = "StatusLabel"
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 22
	_status_label.outline_size = 5
	_status_label.position = Vector3(0.0, 0.95, 0.0)
	_visual.add_child(_status_label)
	_refresh_visual()


func _refresh_visual() -> void:
	if _status_label == null:
		return
	_status_label.text = "%s\n%s" % [display_name, _status]
	if _cargo_mesh != null:
		_cargo_mesh.visible = get_cargo_count() > 0


func _make_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mat.metallic = 0.1
	return mat
