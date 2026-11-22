extends CharacterBody3D
class_name ShipPreviewPlayer
## Minimal walk-around controller for the ship blockout preview.
## Not gameplay code: the real game uses GuPlayer. This keeps the preview
## runnable without changing `scenes/main.tscn`.

@export var speed: float = 4.0
@export var gravity: float = 18.0
@export var camera_path: NodePath = ^"../CameraPivot"
@export var start_yaw: float = 0.0
@export var session_key: String = ""

var _camera_rig: Node3D = null
var _interactor: Interactor = null
var _prompt: Label = null


func _ready() -> void:
	_ensure_input_map()
	_camera_rig = get_node_or_null(camera_path) as Node3D
	_prompt = get_node_or_null("../UI/InteractPrompt") as Label
	_setup_interactor()
	_apply_session_spawn()
	call_deferred("_bind_camera")


func _setup_interactor() -> void:
	_interactor = Interactor.new()
	_interactor.name = "Interactor"
	_interactor.position = Vector3(0.0, 1.0, 0.0)
	_interactor.interact_range = 2.8
	add_child(_interactor)
	_interactor.set_actor(self)
	_interactor.focus_changed.connect(_on_focus_changed)
	if _prompt != null:
		_prompt.visible = false


func _apply_session_spawn() -> void:
	if session_key == "":
		return
	var session := get_node_or_null("/root/SeedSession")
	if session != null and session.has_method("consume_spawn"):
		global_position = session.call("consume_spawn", session_key, global_position)


func _on_focus_changed(target: Interactable) -> void:
	if _prompt == null:
		return
	_prompt.visible = target != null
	if target != null:
		_prompt.text = "[E] %s" % tr(target.get_prompt_text())


func _bind_camera() -> void:
	if _camera_rig == null:
		return
	if _camera_rig.has_method("set_target"):
		_camera_rig.call("set_target", self)
	if _camera_rig.has_method("set_yaw"):
		_camera_rig.call("set_yaw", start_yaw)


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if _camera_rig != null and _camera_rig.has_method("world_move"):
		input = _camera_rig.call("world_move", input)

	var direction := Vector3(input.x, 0.0, input.y)
	if direction.length() > 1.0:
		direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _ensure_input_map() -> void:
	var bindings := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
