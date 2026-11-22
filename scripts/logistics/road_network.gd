class_name RoadNetwork
extends RefCounted
## Player-built grid road graph with 90-degree turns. Trucks can only path
## through placed road cells; station cells are treated as endpoints.

const CELL_SIZE := 2.0
const ROAD_WIDTH := 1.6
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

var _cells: Dictionary = {} ## Vector2i -> true
var _reserved: Dictionary = {} ## Vector2i -> true (stations/machines)
var _visible_edges: Dictionary = {} ## String -> true
var _visual_parent: Node3D = null
var _visual_root: Node3D = null
var _road_material: StandardMaterial3D = null


func setup_visual(parent: Node3D) -> void:
	_visual_parent = parent
	if _visual_parent == null:
		return
	_visual_root = Node3D.new()
	_visual_root.name = "Roads"
	_visual_parent.add_child(_visual_root)
	_road_material = StandardMaterial3D.new()
	_road_material.albedo_color = Color(0.24, 0.22, 0.20)
	_road_material.roughness = 0.95


func cell_for(position: Vector3) -> Vector2i:
	return Vector2i(roundi(position.x / CELL_SIZE), roundi(position.z / CELL_SIZE))


func world_for(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * CELL_SIZE, 0.02, float(cell.y) * CELL_SIZE)


func reserve_cell(cell: Vector2i) -> void:
	_reserved[cell] = true


func is_reserved(cell: Vector2i) -> bool:
	return _reserved.has(cell)


func is_road(cell: Vector2i) -> bool:
	return _cells.has(cell)


func add_cell(cell: Vector2i) -> bool:
	if _cells.has(cell) or _reserved.has(cell):
		return false
	_cells[cell] = true
	rebuild_visual()
	return true


func remove_cell(cell: Vector2i) -> bool:
	if not _cells.has(cell):
		return false
	_cells.erase(cell)
	rebuild_visual()
	return true


func cell_count() -> int:
	return _cells.size()


func add_road(from_position: Vector3, to_position: Vector3) -> Array[Vector3]:
	## Auto-build helper for tests/demo setup. Player roads use add_cell().
	var path_cells := _find_path_unrestricted(cell_for(from_position), cell_for(to_position))
	for cell in path_cells:
		if not _reserved.has(cell):
			_cells[cell] = true
	rebuild_visual()
	var out: Array[Vector3] = []
	for cell in path_cells:
		out.append(world_for(cell))
	return out


func find_path_world(from_position: Vector3, to_position: Vector3) -> Array[Vector3]:
	var path_cells := find_path_cells(cell_for(from_position), cell_for(to_position))
	var out: Array[Vector3] = []
	for cell in path_cells:
		out.append(world_for(cell))
	return out


func find_path_cells(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if start == goal:
		return [start]
	if not _has_adjacent_road(start) and not _cells.has(start):
		return []
	var queue: Array[Vector2i] = [start]
	var came: Dictionary = {start: start}
	var found := false
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == goal:
			found = true
			break
		for dir in DIRECTIONS:
			var next := current + dir
			if came.has(next):
				continue
			if not _cells.has(next) and next != goal:
				continue
			if not _in_bounds(next, start, goal):
				continue
			came[next] = current
			queue.append(next)
	if not found:
		return []
	var path: Array[Vector2i] = []
	var cursor := goal
	while cursor != start:
		path.push_front(cursor)
		cursor = came[cursor]
	path.push_front(start)
	return path


func rebuild_visual() -> void:
	if _visual_root == null:
		return
	for child in _visual_root.get_children():
		child.free()
	_visible_edges.clear()
	for raw_cell in _cells.keys():
		var cell: Vector2i = raw_cell
		_add_corner(cell)
		for dir in [Vector2i(1, 0), Vector2i(0, 1)]:
			var neighbor: Vector2i = cell + dir
			if _cells.has(neighbor):
				_add_segment(cell, neighbor)


func _has_adjacent_road(cell: Vector2i) -> bool:
	for dir in DIRECTIONS:
		if _cells.has(cell + dir):
			return true
	return false


func _find_path_unrestricted(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if start == goal:
		return [start]
	var queue: Array[Vector2i] = [start]
	var came: Dictionary = {start: start}
	var found := false
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == goal:
			found = true
			break
		for dir in DIRECTIONS:
			var next := current + dir
			if came.has(next) or not _in_bounds(next, start, goal):
				continue
			came[next] = current
			queue.append(next)
	if not found:
		return []
	var path: Array[Vector2i] = []
	var cursor := goal
	while cursor != start:
		path.push_front(cursor)
		cursor = came[cursor]
	path.push_front(start)
	return path


func _in_bounds(cell: Vector2i, start: Vector2i, goal: Vector2i) -> bool:
	var min_x := mini(start.x, goal.x) - 8
	var max_x := maxi(start.x, goal.x) + 8
	var min_z := mini(start.y, goal.y) - 8
	var max_z := maxi(start.y, goal.y) + 8
	return cell.x >= min_x and cell.x <= max_x and cell.y >= min_z and cell.y <= max_z


func _add_segment(a: Vector2i, b: Vector2i) -> void:
	var key := _edge_key(a, b)
	if _visible_edges.has(key):
		return
	_visible_edges[key] = true
	var mesh := MeshInstance3D.new()
	mesh.name = "RoadSegment"
	var box := BoxMesh.new()
	if a.x != b.x:
		box.size = Vector3(CELL_SIZE + 0.15, 0.04, ROAD_WIDTH)
	else:
		box.size = Vector3(ROAD_WIDTH, 0.04, CELL_SIZE + 0.15)
	mesh.mesh = box
	mesh.material_override = _road_material
	var mid := (world_for(a) + world_for(b)) * 0.5
	mid.y = 0.02
	mesh.position = mid
	_visual_root.add_child(mesh)


func _add_corner(cell: Vector2i) -> void:
	var key := "corner:%d:%d" % [cell.x, cell.y]
	if _visible_edges.has(key):
		return
	_visible_edges[key] = true
	var mesh := MeshInstance3D.new()
	mesh.name = "RoadCorner"
	var box := BoxMesh.new()
	box.size = Vector3(ROAD_WIDTH, 0.041, ROAD_WIDTH)
	mesh.mesh = box
	mesh.material_override = _road_material
	var pos := world_for(cell)
	pos.y = 0.021
	mesh.position = pos
	_visual_root.add_child(mesh)


func _edge_key(a: Vector2i, b: Vector2i) -> String:
	if a.x > b.x or (a.x == b.x and a.y > b.y):
		var tmp := a
		a = b
		b = tmp
	return "%d:%d|%d:%d" % [a.x, a.y, b.x, b.y]
