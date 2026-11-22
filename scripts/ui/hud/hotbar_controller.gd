class_name HotbarController
extends Node
## Hotbar selection and item use. Replaces the old 1–4 action verbs with
## tool-driven actions: 1–6 select, F uses the selected item/tool.

signal hint_requested(text: String)
signal selection_changed(slot: int, item_id: StringName)

const SLOT_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]
const LEGACY_ACTIONS := [
	&"action_gather",
	&"action_mine",
	&"action_chop",
	&"action_build",
	&"action_repeat",
]
const TOOL_ACTION_TAGS := {
	&"axe": &"chop",
	&"pickaxe": &"mine",
	&"knife": &"gather",
	&"cut": &"gather",
	&"hammer": &"build",
	&"build": &"build",
	&"weapon": &"strike",
}

var _player: GuPlayer
var _inventory: InventoryContainer
var _hotbar: Hotbar
var _hunger: HungerController
var _selected_slot := 0
var _selected_item: StringName = &""


func _enter_tree() -> void:
	_register_actions()


func _exit_tree() -> void:
	if _inventory != null and _inventory.inventory_changed.is_connected(_on_inventory_changed):
		_inventory.inventory_changed.disconnect(_on_inventory_changed)


func bind(
	player: GuPlayer,
	inventory: InventoryContainer,
	hotbar: Hotbar,
	hunger: HungerController = null
) -> void:
	_player = player
	_inventory = inventory
	_hotbar = hotbar
	_hunger = hunger
	if _inventory != null and not _inventory.inventory_changed.is_connected(_on_inventory_changed):
		_inventory.inventory_changed.connect(_on_inventory_changed)
	_register_actions()
	_sync_selection(true)


func select_slot(index: int) -> void:
	if _hotbar == null:
		return
	_selected_slot = clampi(index, 0, Hotbar.SLOT_COUNT - 1)
	_hotbar.set_selected(_selected_slot)
	_selected_item = _hotbar.get_slot_item_id(_selected_slot)
	selection_changed.emit(_selected_slot, _selected_item)


func get_selected_slot() -> int:
	return _selected_slot


func get_selected_item_id() -> StringName:
	return _selected_item


func get_action_for_item(item_id: StringName) -> StringName:
	if _inventory == null or item_id == &"":
		return &""
	var def := _inventory.get_item_def(item_id)
	if def == null:
		return &""
	for tag in def.tags:
		if TOOL_ACTION_TAGS.has(tag):
			return TOOL_ACTION_TAGS[tag] as StringName
	return &""


func get_selected_action_id() -> StringName:
	return get_action_for_item(_selected_item)


func get_selected_hint() -> String:
	if _selected_item == &"":
		return tr("HUD_EMPTY_HAND")
	var item_name := _pretty(_selected_item)
	var def := _inventory.get_item_def(_selected_item) if _inventory != null else null
	if def != null and def.tags.has(&"food"):
		return "%s  ·  F %s" % [item_name, tr("Eat")]
	var action := get_action_for_item(_selected_item)
	if action != &"":
		return "%s  ·  F %s" % [item_name, _action_verb_label(action)]
	return item_name


func use_selected() -> bool:
	if _selected_item == &"":
		hint_requested.emit(tr("HUD_NO_ITEM_SELECTED"))
		return false
	var def := _inventory.get_item_def(_selected_item) if _inventory != null else null
	if def != null and def.tags.has(&"food"):
		return _use_food(_selected_item)
	var action := get_action_for_item(_selected_item)
	if action == &"":
		hint_requested.emit("%s %s." % [tr("HUD_NO_ACTION_FOR"), _pretty(_selected_item)])
		return false
	var target := _focused_tool_target()
	if target != null:
		var raw_preferred: Variant = target.get("preferred_action")
		if raw_preferred != null:
			var preferred := StringName(str(raw_preferred))
			if preferred != &"" and preferred != action:
				hint_requested.emit("%s %s" % [tr("Need:"), _action_tool_label(preferred)])
				return false
		if not _tool_matches_target(target, def):
			return false
		return bool(target.call("interact", _player))
	if _player != null and _player.has_method("perform_action"):
		return bool(_player.call("perform_action", action))
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var router := get_node_or_null("/root/InputRouter")
	if router != null and not bool(router.call("is_gameplay_active")):
		return
	for index in SLOT_KEYS.size():
		if event.is_action_pressed("hotbar_%d" % (index + 1)):
			select_slot(index)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("use_selected"):
		use_selected()
		get_viewport().set_input_as_handled()


func _register_actions() -> void:
	var router := get_node_or_null("/root/InputRouter")
	if router == null or not router.has_method("register_action"):
		return
	for index in SLOT_KEYS.size():
		router.call("register_action", StringName("hotbar_%d" % (index + 1)), [SLOT_KEYS[index]], "Hotbar %d" % (index + 1))
	router.call("register_action", &"use_selected", [KEY_F], "Use Selected")
	if router.has_signal("bindings_changed") and not router.is_connected("bindings_changed", _on_bindings_changed):
		router.connect("bindings_changed", _on_bindings_changed)
	_clear_legacy_events()


func _on_bindings_changed(_action: StringName) -> void:
	_clear_legacy_events()


func _clear_legacy_events() -> void:
	# The shared player maps 1–4 to gather/mine/chop/build and F to repeat.
	# Those keys are now hotbar/use, so release the legacy events.
	for action: StringName in LEGACY_ACTIONS:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)


func _use_food(item_id: StringName) -> bool:
	if _hunger != null and item_id == &"wild_berry":
		return _hunger.eat_berry()
	hint_requested.emit("%s %s." % [tr("HUD_NO_ACTION_FOR"), _pretty(item_id)])
	return false


func _focused_tool_target() -> Node:
	if _player == null:
		return null
	var interactor := _player.get_interactor()
	if interactor == null:
		return null
	var target := interactor.get_focused()
	if target == null or not is_instance_valid(target):
		return null
	if target.get("required_tool_tags") != null:
		return target
	return null


func _tool_matches_target(target: Node, tool_def: ItemDef) -> bool:
	var raw_required: Variant = target.get("required_tool_tags")
	if raw_required == null:
		return true
	var required: Array = raw_required as Array
	if required.is_empty():
		return true
	if tool_def != null:
		for raw_tag in required:
			var tag := StringName(str(raw_tag))
			if tool_def.tags.has(tag):
				return true
	hint_requested.emit("%s %s" % [tr("Need:"), String(required[0]).capitalize()])
	return false


func _action_verb_label(action: StringName) -> String:
	match action:
		&"gather":
			return tr("Gather")
		&"chop":
			return tr("Chop")
		&"mine":
			return tr("Mine")
		&"build":
			return tr("Build")
		&"strike":
			return tr("Strike")
	return String(action).capitalize()


func _action_tool_label(action: StringName) -> String:
	match action:
		&"gather":
			return tr("Knife")
		&"chop":
			return tr("Axe")
		&"mine":
			return tr("Pickaxe")
		&"build":
			return tr("Hammer")
		&"strike":
			return tr("Weapon")
	return String(action).capitalize()


func _on_inventory_changed() -> void:
	_sync_selection(false)


func _sync_selection(force: bool) -> void:
	if _hotbar == null:
		return
	var ids := _hotbar.get_slot_item_ids()
	if not force and _selected_item != &"":
		var found := ids.find(_selected_item)
		if found >= 0:
			select_slot(found)
			return
	var first := -1
	for index in ids.size():
		if ids[index] != &"":
			first = index
			break
	select_slot(first if first >= 0 else 0)


func _pretty(item_id: StringName) -> String:
	if _inventory != null:
		var def := _inventory.get_item_def(item_id)
		if def != null and def.display_name != "":
			return tr(def.display_name)
	return String(item_id).replace("_", " ").capitalize()
