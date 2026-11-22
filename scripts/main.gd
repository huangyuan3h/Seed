extends Node3D
## Starter world: playable plane plus a content-driven quest, guide dialogue, HUD, and saves.

const TITLE_SCENE := preload("res://scenes/ui/title_screen.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/settings_panel.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const WRIST_SCENE := preload("res://scenes/ui/wrist_computer.tscn")

@onready var _player: GuPlayer = $Player
@onready var _camera_rig: CameraRig = $CameraPivot
@onready var _landscape: SeedLandscape = get_node_or_null("Landscape") as SeedLandscape
@onready var _environment: Node = get_node_or_null("SeedEnvironment")

var _flags := FlagStore.new()
var _quests := QuestTracker.new()
var _dialogue_box: DialogueBox = null
var _hud: SeedHud = null
var _guide: DialogueInteractable = null
var _hunger: HungerController = null
var _hotbar_controller: HotbarController = null
var _ai_hint_label: Label = null
var _eat_hint_label: Label = null
var _ai_hint_timer: Timer = null
var _prompt_panel: PanelContainer = null
var _prompt_label: Label = null
var _focused: Interactable = null
var _world_seed: int = 42
var _ticks: int = 0
var _spawn_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	_register_ui_screens()
	if _player != null:
		_spawn_position = _player.global_position
	if _camera_rig != null and _player != null:
		_camera_rig.set_target(_player)
	if _player != null:
		_style_player()
	if _player != null and _landscape != null:
		_player.set_context(_landscape, _environment)
	var name_label := _player.get_node_or_null("NameLabel") as Label3D if _player != null else null
	if name_label != null:
		name_label.visible = false
	_register_content()
	_setup_dialogue()
	_setup_guide()
	_setup_ship_entry()
	_setup_hud()
	_setup_survival_ui()
	_setup_hunger()
	_setup_hotbar_controller()
	_setup_colonists()
	_setup_build_sites()
	_setup_prompt()
	_connect_interactor()
	_quests.quest_completed.connect(_on_quest_completed)

	var flow := get_node_or_null("/root/GameFlow")
	if flow != null:
		flow.call("register_world", self)
		var session := get_node_or_null("/root/SeedSession")
		if session != null and bool(session.call("consume_return_from_ship")):
			start_new_world({
				"skip_ship_intro": true,
				"spawn": session.get("landing_spawn"),
			})
		else:
			flow.call("enter_title")


func _exit_tree() -> void:
	_quests.unbind()
	var save_svc := get_node_or_null("/root/SaveService")
	if save_svc != null and save_svc.has_method("unregister_saveable"):
		save_svc.call("unregister_saveable", "flags")
		save_svc.call("unregister_saveable", "quests")


func _process(_delta: float) -> void:
	var flow := get_node_or_null("/root/GameFlow")
	if flow != null and int(flow.call("get_state")) == 3:
		_ticks += 1
	_refresh_prompt()


func start_new_world(opts: Dictionary = {}) -> void:
	if not bool(opts.get("skip_ship_intro", false)):
		_begin_ship_intro()
		return
	_world_seed = int(opts.get("seed", 42))
	_ticks = 0
	_flags.clear()
	_quests.apply_state({"active": {}, "completed": []})
	for quest_def in GameContent.quests():
		if quest_def.auto_start:
			_quests.start_quest(quest_def.id)
	_reset_player()
	var spawn: Variant = opts.get("spawn")
	if spawn is Vector3 and _player != null:
		_player.global_position = spawn
		_spawn_position = spawn
	if _player != null and _player.get_inventory() != null:
		_player.get_inventory().clear()
	_give_starting_kit()
	if _camera_rig != null and _player != null:
		_camera_rig.set_target(_player)
	var ui := get_node_or_null("/root/UIRouter")
	if ui != null and ui.has_method("show_toast"):
		ui.call("show_toast", "New session started (seed %d)" % _world_seed, 2.2, &"info")


func _begin_ship_intro() -> void:
	var session := get_node_or_null("/root/SeedSession")
	if session != null:
		session.set("start_in_ship", true)
		session.set("opening_complete", false)
	var ui := get_node_or_null("/root/UIRouter")
	if ui != null:
		ui.call("clear_screens")
	get_tree().change_scene_to_file("res://scenes/ship/ship_preview.tscn")


func export_save_state() -> Dictionary:
	return {
		"world": {"seed": _world_seed},
		"session": {"ticks": _ticks},
		"player": {
			"position": [_player.global_position.x, _player.global_position.y, _player.global_position.z],
			"facing_yaw": _player.get_facing_yaw(),
			"run_mode": _player.get_run_mode(),
		},
	}


func apply_save_state(doc: Dictionary) -> void:
	var w: Dictionary = doc.get("world", {}) as Dictionary
	_world_seed = int(w.get("seed", 42))
	var s: Dictionary = doc.get("session", {}) as Dictionary
	_ticks = int(s.get("ticks", 0))
	var p: Dictionary = doc.get("player", {}) as Dictionary
	var pos: Array = p.get("position", []) as Array
	if _player != null and pos.size() == 3:
		_player.global_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
		_player.velocity = Vector3.ZERO
		_player.set_facing_yaw(float(p.get("facing_yaw", 0.0)))
		_player.set_run_mode(bool(p.get("run_mode", false)))


func _register_content() -> void:
	var quest_defs := GameContent.quests()
	for quest_def in quest_defs:
		_quests.register_quest(quest_def)
	_quests.bind(get_node_or_null("/root/EventBus"), _flags, _player.get_inventory())
	for quest_def in quest_defs:
		if quest_def.auto_start:
			_quests.start_quest(quest_def.id)
	for item_def in GameContent.items():
		ItemIcons.apply_to(item_def)
		_player.get_inventory().register_item(item_def)
	var save_svc := get_node_or_null("/root/SaveService")
	if save_svc != null and save_svc.has_method("register_saveable"):
		save_svc.call("register_saveable", "flags", _flags)
		save_svc.call("register_saveable", "quests", _quests)


func _setup_dialogue() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DialogueLayer"
	layer.layer = 40
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_dialogue_box = DialogueBox.new()
	_dialogue_box.name = "DialogueBox"
	layer.add_child(_dialogue_box)
	_dialogue_box.bind(_flags, _quests, _player.get_inventory(), get_node_or_null("/root/EventBus"))


func _setup_guide() -> void:
	var def := GameContent.dialogue(&"guide_intro")
	if def == null:
		return
	_guide = DialogueInteractable.new()
	_guide.name = "Guide"
	_guide.display_name = "Guide"
	_guide.prompt_text = "Talk to the Guide"
	_guide.interaction_id = "guide"
	_guide.interaction_priority = 5
	_guide.dialogue = def
	add_child(_guide)
	_guide.global_position = _spawn_position + Vector3(3.0, 0.0, -1.0)
	_style_guide(_guide)


func _style_player() -> void:
	var visual := _player.get_node_or_null("VisualRoot")
	if visual == null or visual.get_child_count() == 0:
		return
	var model := visual.get_child(0)
	var mesh := model.find_child("Human_Mesh", true, false) as MeshInstance3D
	if mesh != null:
		var base := mesh.get_active_material(0) as StandardMaterial3D
		var suit := StandardMaterial3D.new()
		if base != null:
			suit.albedo_texture = base.albedo_texture
		suit.albedo_color = Color(0.34, 0.44, 0.41)
		suit.roughness = 0.86
		mesh.material_override = suit
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	var pack := MeshInstance3D.new()
	var pack_mesh := BoxMesh.new()
	pack_mesh.size = Vector3(0.3, 0.4, 0.18)
	pack.mesh = pack_mesh
	var pack_mat := StandardMaterial3D.new()
	pack_mat.albedo_color = Color("#3f3a30")
	pack_mat.roughness = 0.95
	pack.material_override = pack_mat
	pack.position = Vector3(0.0, 1.05, -0.24)
	visual.add_child(pack)


func _style_guide(guide: DialogueInteractable) -> void:
	var body := guide.get_node_or_null("Visual") as MeshInstance3D
	if body != null:
		var cloak := StandardMaterial3D.new()
		cloak.albedo_color = Color("#35514e")
		cloak.roughness = 0.9
		body.material_override = cloak

	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("#b98d68")
	skin.roughness = 0.8
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.19
	head_mesh.height = 0.38
	head.mesh = head_mesh
	head.material_override = skin
	head.position = Vector3(0.0, 1.58, 0.0)
	guide.add_child(head)

	var pack := MeshInstance3D.new()
	var pack_mesh := BoxMesh.new()
	pack_mesh.size = Vector3(0.34, 0.5, 0.2)
	pack.mesh = pack_mesh
	var pack_mat := StandardMaterial3D.new()
	pack_mat.albedo_color = Color("#4a4034")
	pack_mat.roughness = 0.95
	pack.material_override = pack_mat
	pack.position = Vector3(0.0, 0.98, 0.3)
	guide.add_child(pack)

	var staff := MeshInstance3D.new()
	var staff_mesh := CylinderMesh.new()
	staff_mesh.top_radius = 0.035
	staff_mesh.bottom_radius = 0.045
	staff_mesh.height = 1.45
	staff.mesh = staff_mesh
	var staff_mat := StandardMaterial3D.new()
	staff_mat.albedo_color = Color("#6b5a3e")
	staff_mat.roughness = 0.95
	staff.material_override = staff_mat
	staff.position = Vector3(0.38, 0.72, 0.04)
	staff.rotation_degrees = Vector3(0, 0, -8)
	guide.add_child(staff)


func _setup_ship_entry() -> void:
	var entry := ShipTransition.new()
	entry.name = "ShipEntry"
	entry.interaction_id = "ship_entry"
	entry.prompt_text = "Enter the crashed ship"
	entry.target_scene = "res://scenes/ship/ship_preview.tscn"
	entry.transition_message = "Entering the crashed ship..."
	entry.destination_key = "ship_interior"
	entry.destination_spawn = Vector3(0.0, 0.1, -19.0)
	entry.interaction_priority = 6
	add_child(entry)
	entry.global_position = Vector3(-40.0, 1.2, -55.0)


func _setup_hud() -> void:
	var stats := _player.get_stats()
	if not stats.has_stat(&"hunger"):
		stats.define_stat(&"hunger", 100.0, 65.0)
	_hud = HUD_SCENE.instantiate() as SeedHud
	_hud.name = "SeedHud"
	add_child(_hud)
	_hud.bind_player_hud(
		stats,
		_player.get_inventory(),
		_quests,
		get_node_or_null("/root/WorldTime")
	)


func _setup_survival_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "SurvivalLayer"
	layer.layer = 36
	add_child(layer)

	_ai_hint_label = Label.new()
	_ai_hint_label.name = "AiHint"
	_ai_hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_ai_hint_label.offset_left = -360.0
	_ai_hint_label.offset_right = 360.0
	_ai_hint_label.offset_top = -182.0
	_ai_hint_label.offset_bottom = -140.0
	_ai_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ai_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ai_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ai_hint_label.add_theme_font_size_override("font_size", 18)
	_ai_hint_label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0, 1.0))
	_ai_hint_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_ai_hint_label.add_theme_constant_override("outline_size", 6)
	_ai_hint_label.visible = false
	layer.add_child(_ai_hint_label)

	_eat_hint_label = Label.new()
	_eat_hint_label.name = "EatHint"
	_eat_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_eat_hint_label.offset_left = 24.0
	_eat_hint_label.offset_top = -80.0
	_eat_hint_label.offset_right = 250.0
	_eat_hint_label.offset_bottom = -16.0
	_eat_hint_label.add_theme_font_size_override("font_size", 16)
	_eat_hint_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.72, 1.0))
	_eat_hint_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_eat_hint_label.add_theme_constant_override("outline_size", 5)
	_eat_hint_label.visible = false
	layer.add_child(_eat_hint_label)

	_ai_hint_timer = Timer.new()
	_ai_hint_timer.one_shot = true
	_ai_hint_timer.wait_time = 4.0
	_ai_hint_timer.timeout.connect(_hide_ai_hint)
	add_child(_ai_hint_timer)


func _setup_hunger() -> void:
	_hunger = HungerController.new()
	_hunger.name = "HungerController"
	add_child(_hunger)
	_hunger.hint_requested.connect(_show_ai_hint)
	_hunger.eat_hint_changed.connect(_on_eat_hint_changed)
	_hunger.bind(_player.get_stats(), _player.get_inventory())


func _setup_hotbar_controller() -> void:
	if _hud == null or _player == null:
		return
	_hotbar_controller = HotbarController.new()
	_hotbar_controller.name = "HotbarController"
	add_child(_hotbar_controller)
	_hotbar_controller.bind(
		_player,
		_player.get_inventory(),
		_hud.get_hotbar(),
		_hunger
	)
	_hotbar_controller.hint_requested.connect(_show_ai_hint)
	_hotbar_controller.selection_changed.connect(_on_hotbar_selection_changed)
	_on_hotbar_selection_changed(
		_hotbar_controller.get_selected_slot(),
		_hotbar_controller.get_selected_item_id()
	)


func _on_hotbar_selection_changed(_slot: int, _item_id: StringName) -> void:
	if _hud != null and _hotbar_controller != null:
		_hud.set_selected_text(_hotbar_controller.get_selected_hint())


func _give_starting_kit() -> void:
	if _player == null:
		return
	var inventory := _player.get_inventory()
	if inventory != null and inventory.count_item(&"emergency_knife") <= 0:
		inventory.add_item(&"emergency_knife", 1)


func _setup_colonists() -> void:
	var pod := get_node_or_null("GeneticistPod") as ColonistPod
	if pod == null:
		return
	pod.bind(_flags, _player.get_inventory())
	pod.hint_requested.connect(_show_ai_hint)


func _setup_build_sites() -> void:
	for node_name in ["ShelterSite", "ThermalGeneratorSite"]:
		var site := get_node_or_null(node_name) as BuildSite
		if site == null:
			continue
		site.bind(_player.get_inventory(), _flags)
		site.hint_requested.connect(_show_ai_hint)


func _show_ai_hint(text: String) -> void:
	if _ai_hint_label == null or text.strip_edges() == "":
		return
	_ai_hint_label.text = "[%s] %s" % [tr("Ship AI"), text]
	_ai_hint_label.visible = true
	_ai_hint_timer.start()


func _hide_ai_hint() -> void:
	if _ai_hint_label != null:
		_ai_hint_label.visible = false


func _on_eat_hint_changed(text: String) -> void:
	if _eat_hint_label == null:
		return
	_eat_hint_label.text = text
	_eat_hint_label.visible = text != ""


func _setup_prompt() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PromptLayer"
	layer.layer = 35
	add_child(layer)
	_prompt_panel = PanelContainer.new()
	_prompt_panel.name = "InteractionPrompt"
	_prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_panel.offset_left = -140.0
	_prompt_panel.offset_right = 140.0
	_prompt_panel.offset_top = -132.0
	_prompt_panel.offset_bottom = -100.0
	_prompt_panel.visible = false
	layer.add_child(_prompt_panel)
	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt_panel.add_child(_prompt_label)


func _connect_interactor() -> void:
	var interactor := _player.get_interactor()
	if interactor != null and not interactor.focus_changed.is_connected(_on_focus_changed):
		interactor.focus_changed.connect(_on_focus_changed)


func _on_focus_changed(target: Interactable) -> void:
	_focused = target


func _refresh_prompt() -> void:
	if _prompt_panel == null or _prompt_label == null:
		return
	var router := get_node_or_null("/root/InputRouter")
	var gameplay_ok := router == null or bool(router.call("is_gameplay_active"))
	var target := _focused
	if target == null or not is_instance_valid(target) or not gameplay_ok:
		_prompt_panel.visible = false
		return
	_prompt_label.text = "[E] %s" % tr(target.get_prompt_text())
	_prompt_panel.visible = true


func _on_quest_completed(quest_id: StringName) -> void:
	var flow := get_node_or_null("/root/GameFlow")
	var ui := get_node_or_null("/root/UIRouter")
	if flow == null or int(flow.call("get_state")) != 3 or ui == null:
		return
	var title := tr(str(_quests.get_quest_status(quest_id).get("title", String(quest_id))))
	ui.call("show_toast", "QUEST COMPLETE: %s" % title, 3.0, &"success")


func _reset_player() -> void:
	if _player == null:
		return
	_player.global_position = _spawn_position
	_player.velocity = Vector3.ZERO
	_player.set_facing_yaw(0.0)
	_player.set_run_mode(false)


func _register_ui_screens() -> void:
	var ui := get_node_or_null("/root/UIRouter")
	if ui == null:
		return
	ui.call("register_screen", &"title", TITLE_SCENE)
	ui.call("register_screen", &"pause", PAUSE_SCENE)
	ui.call("register_screen", &"settings", SETTINGS_SCENE)
	ui.call("register_screen", &"wrist", WRIST_SCENE)
