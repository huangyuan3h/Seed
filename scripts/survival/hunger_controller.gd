class_name HungerController
extends Node
## Minimal early-game hunger loop: decays while gameplay is active, berries restore it,
## and the ship AI comments at thresholds. UI wiring lives in main.gd.

signal hint_requested(text: String)
signal eat_hint_changed(text: String)

const HUNGER := &"hunger"
const BERRY := &"wild_berry"
const EAT_ACTION := &"eat_food"

@export var max_hunger: float = 100.0
@export var start_hunger: float = 65.0
@export var decay_per_second: float = 0.05
@export var berry_restore: float = 12.0

var _stats: StatSet = null
var _inventory: InventoryContainer = null
var _router: Node = null
var _low_hint_shown := false
var _starving_hint_shown := false


func bind(stats: StatSet, inventory: InventoryContainer) -> void:
	_stats = stats
	_inventory = inventory
	if _stats != null and not _stats.has_stat(HUNGER):
		_stats.define_stat(HUNGER, max_hunger, start_hunger)
	if _stats != null and not _stats.stat_changed.is_connected(_on_stat_changed):
		_stats.stat_changed.connect(_on_stat_changed)
	if _inventory != null and not _inventory.inventory_changed.is_connected(_update_eat_hint):
		_inventory.inventory_changed.connect(_update_eat_hint)
	_router = get_node_or_null("/root/InputRouter")
	_register_action()
	_update_thresholds()
	_update_eat_hint()


func _exit_tree() -> void:
	if _stats != null and _stats.stat_changed.is_connected(_on_stat_changed):
		_stats.stat_changed.disconnect(_on_stat_changed)
	if _inventory != null and _inventory.inventory_changed.is_connected(_update_eat_hint):
		_inventory.inventory_changed.disconnect(_update_eat_hint)


func _process(delta: float) -> void:
	if _stats == null or not _gameplay_active() or get_tree().paused:
		return
	_stats.modify_value(HUNGER, -decay_per_second * delta)
	_update_thresholds()
	_update_eat_hint()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed(EAT_ACTION):
		return
	if not _gameplay_active():
		return
	if eat_berry():
		get_viewport().set_input_as_handled()


func get_hunger() -> float:
	return _stats.get_value(HUNGER) if _stats != null else 0.0


func eat_berry() -> bool:
	if _inventory == null or _stats == null:
		return false
	if not _inventory.remove_item(BERRY, 1):
		return false
	_stats.modify_value(HUNGER, berry_restore)
	if _stats.get_value(HUNGER) > 15.0:
		_starving_hint_shown = false
	if _stats.get_value(HUNGER) > 40.0:
		_low_hint_shown = false
	hint_requested.emit(tr("Good. That helps."))
	_update_eat_hint()
	return true


func _register_action() -> void:
	if _router != null and _router.has_method("register_action"):
		_router.call("register_action", EAT_ACTION, [KEY_H], "Eat")
		return
	var action_name := String(EAT_ACTION)
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_H
	if not InputMap.action_has_event(action_name, ev):
		InputMap.action_add_event(action_name, ev)


func _gameplay_active() -> bool:
	var flow := get_node_or_null("/root/GameFlow")
	if flow != null and int(flow.call("get_state")) != 3:
		return false
	if _router != null and _router.has_method("is_gameplay_active"):
		return bool(_router.call("is_gameplay_active"))
	return true


func _update_thresholds() -> void:
	if _stats == null:
		return
	var value := _stats.get_value(HUNGER)
	if value <= 15.0 and not _starving_hint_shown:
		_starving_hint_shown = true
		_low_hint_shown = true
		hint_requested.emit(tr("You're starving."))
	elif value <= 40.0 and not _low_hint_shown:
		_low_hint_shown = true
		hint_requested.emit(tr("You should eat something, Commander."))


func _update_eat_hint() -> void:
	if _inventory == null:
		eat_hint_changed.emit("")
		return
	var count := _inventory.count_item(BERRY)
	if count <= 0:
		eat_hint_changed.emit("")
		return
	eat_hint_changed.emit("[H] %s (%d)" % [tr("Eat Wild Berry"), count])


func _on_stat_changed(stat_id: StringName, _current: float, _maximum: float) -> void:
	if stat_id != HUNGER:
		return
	# Re-arm the warnings once the player has eaten back above a threshold.
	if _stats.get_value(HUNGER) > 40.0:
		_low_hint_shown = false
		_starving_hint_shown = false
	elif _stats.get_value(HUNGER) > 15.0:
		_starving_hint_shown = false
