extends Node
## Small cross-scene session state for the opening / ship blockout.
## Scene changes in Godot replace the current world; this keeps only the few
## values that must survive a change (ship → landing, airlock → breach).

var landing_spawn: Vector3 = Vector3(-30.0, 2.0, -45.0)
var return_from_ship: bool = false
var opening_complete: bool = false
var start_in_ship: bool = false

var _spawns: Dictionary = {}


func set_spawn(key: String, position: Vector3) -> void:
	if key != "":
		_spawns[key] = position


func consume_spawn(key: String, fallback: Vector3) -> Vector3:
	if key != "" and _spawns.has(key):
		var value: Vector3 = _spawns[key]
		_spawns.erase(key)
		return value
	return fallback


func clear_spawn(key: String) -> void:
	_spawns.erase(key)


func consume_return_from_ship() -> bool:
	var value := return_from_ship
	return_from_ship = false
	return value


func reset() -> void:
	landing_spawn = Vector3(-30.0, 2.0, -45.0)
	return_from_ship = false
	opening_complete = false
	start_in_ship = false
	_spawns.clear()
