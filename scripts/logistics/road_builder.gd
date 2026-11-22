class_name RoadBuilder
extends Node3D
## Mouse-driven road placement on the RoadNetwork grid. Left click/drag places
## one stone-priced tile; right click or Esc exits build mode.

signal status_changed(text: String)
signal hint_requested(text: String)
signal active_changed(active: bool)

const CONTEXT_OWNER := &"road_builder"
const UI_CONTEXT := 1
const CELL_COST_STONE := 1
const INVALID_CELL := Vector2i(1 << 30, 1 << 30)

var road: RoadNetwork = null
var inventory: InventoryContainer = null

var _active := false
var _context_pushed := false
var _preview: MeshInstance3D = null
var _preview_material: StandardMaterial3D = null
var _place_cooldown := 0.0
var _status := "Road mode off"


func setup(p_road: RoadNetwork, p_inventory: InventoryContainer) -> void:
	road = p_road
	inventory = p_inventory
	_build_preview()


func is_active() -> bool:
	return _active


func get_status_text() -> String:
	return _status


func set_active(active: bool) -> void:
	if _active == active:
		return
	_active = active
	if _active:
		_build_preview()
		_push_context()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_place_cooldown = 0.15
		_status = "Road mode: click/drag to place (1 stone/tile); right-click/Esc to exit"
	else:
		_pop_context()
		if _preview != null:
			_preview.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_status = "Road mode off"
	status_changed.emit(_status)
	active_changed.emit(_active)


func toggle() -> void:
	set_active(not _active)


func _exit_tree() -> void:
	_pop_context()


func _process(delta: float) -> void:
	if not _active:
		return
	_place_cooldown = maxf(0.0, _place_cooldown - delta)
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered != null:
		_update_preview(INVALID_CELL)
		return
	var cell := _cell_under_mouse()
	_update_preview(cell)
	if _is_valid_cell(cell) and _place_cooldown <= 0.0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if _try_place(cell):
			_place_cooldown = 0.08


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed(&"ui_cancel"):
		set_active(false)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			set_active(false)
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var cell := _cell_under_mouse()
			if _is_valid_cell(cell):
				_try_place(cell)
			get_viewport().set_input_as_handled()


func _try_place(cell: Vector2i) -> bool:
	if road == null:
		return false
	if road.is_reserved(cell):
		hint_requested.emit("That cell is reserved for a station or machine.")
		return false
	if road.is_road(cell):
		return false
	if inventory == null or inventory.count_item(&"stone") < CELL_COST_STONE:
		hint_requested.emit("Need %d stone to build a road tile." % CELL_COST_STONE)
		return false
	inventory.remove_item(&"stone", CELL_COST_STONE)
	if not road.add_cell(cell):
		inventory.add_item(&"stone", CELL_COST_STONE)
		return false
	hint_requested.emit("Road placed. Tiles: %d. Stone left: %d." % [road.cell_count(), inventory.count_item(&"stone")])
	return true


func _cell_under_mouse() -> Vector2i:
	if road == null:
		return INVALID_CELL
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return INVALID_CELL
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	if hit is Vector3:
		var hit_pos: Vector3 = hit
		return road.cell_for(hit_pos)
	return INVALID_CELL


func _is_valid_cell(cell: Vector2i) -> bool:
	return cell != INVALID_CELL


func _update_preview(cell: Vector2i) -> void:
	if _preview == null:
		return
	if not _is_valid_cell(cell):
		_preview.visible = false
		return
	_preview.visible = true
	_preview.position = road.world_for(cell) + Vector3(0.0, 0.06, 0.0)
	var ok := not road.is_reserved(cell) and not road.is_road(cell) and inventory != null and inventory.count_item(&"stone") >= CELL_COST_STONE
	_preview_material.albedo_color = Color(0.25, 0.85, 0.35, 0.45) if ok else Color(0.90, 0.25, 0.20, 0.45)


func _build_preview() -> void:
	if _preview != null:
		return
	_preview = MeshInstance3D.new()
	_preview.name = "RoadPreview"
	var box := BoxMesh.new()
	box.size = Vector3(RoadNetwork.CELL_SIZE - 0.1, 0.05, RoadNetwork.CELL_SIZE - 0.1)
	_preview.mesh = box
	_preview_material = StandardMaterial3D.new()
	_preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_preview_material.albedo_color = Color(0.25, 0.85, 0.35, 0.45)
	_preview.material_override = _preview_material
	_preview.visible = false
	add_child(_preview)


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
