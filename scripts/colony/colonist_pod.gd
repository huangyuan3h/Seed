class_name ColonistPod
extends Interactable
## Locked colonist pod. Shows wake requirements and reports when the colony is ready.
## The actual wake sequence is a later milestone.

signal hint_requested(text: String)

@export var colonist_id: StringName = &"geneticist"
@export var colony_name: String = "Geneticist"
@export var required_power: float = 20.0
@export var required_food: int = 10
@export var requires_generator: bool = true
@export var requires_shelter: bool = true
@export var requires_medbay: bool = true
@export var food_item_ids: Array[StringName] = [&"wild_berry"]

var _flags: FlagStore = null
var _inventory: InventoryContainer = null
var _check_accum := 0.0
var _wake_hint_shown := false


func _ready() -> void:
	prompt_text = "Check Geneticist Pod"
	interaction_id = StringName("%s_pod" % colonist_id)
	interaction_priority = 7
	super._ready()


func bind(flags: FlagStore, inventory: InventoryContainer) -> void:
	_flags = flags
	_inventory = inventory


func _can_interact(_actor: Node) -> bool:
	return true


func _on_interact(_actor: Node) -> void:
	hint_requested.emit(requirements_summary())


func _process(delta: float) -> void:
	if _flags == null or _inventory == null:
		return
	_check_accum += delta
	if _check_accum < 0.5:
		return
	_check_accum = 0.0
	if can_wake():
		if not _wake_hint_shown:
			_wake_hint_shown = true
			hint_requested.emit(tr("All requirements met. We can try waking the geneticist."))
	else:
		_wake_hint_shown = false


func can_wake() -> bool:
	if _flags == null or _inventory == null:
		return false
	if requires_generator and not _flags.get_bool(&"thermal_generator_built", false):
		return false
	if _power() + 0.001 < required_power:
		return false
	if requires_shelter and not _flags.get_bool(&"shelter_built", false):
		return false
	if _food_count() < required_food:
		return false
	if requires_medbay and not _flags.get_bool(&"medbay_online", false):
		return false
	return true


func requirements_summary() -> String:
	if _flags == null or _inventory == null:
		return tr("Pod offline.")
	var missing: Array[String] = []
	if requires_generator and not _flags.get_bool(&"thermal_generator_built", false):
		missing.append(tr("thermal generator"))
	if _power() + 0.001 < required_power:
		missing.append("%s (%d/%d)" % [tr("power"), int(_power()), int(required_power)])
	if requires_shelter and not _flags.get_bool(&"shelter_built", false):
		missing.append(tr("shelter"))
	if _food_count() < required_food:
		missing.append("%s (%d/%d)" % [tr("food"), _food_count(), required_food])
	if requires_medbay and not _flags.get_bool(&"medbay_online", false):
		missing.append(tr("med bay"))
	if missing.is_empty():
		return tr("All requirements met. We can try waking the geneticist.")
	var joined := ""
	for i in missing.size():
		if i > 0:
			joined += ", "
		joined += missing[i]
	return "%s %s" % [tr("Geneticist pod. Missing:"), joined]


func _power() -> float:
	if _flags == null:
		return 0.0
	return float(_flags.get_flag(&"power_capacity", 0.0))


func _food_count() -> int:
	if _inventory == null:
		return 0
	var total := 0
	for item_id in food_item_ids:
		total += _inventory.count_item(item_id)
	return total
