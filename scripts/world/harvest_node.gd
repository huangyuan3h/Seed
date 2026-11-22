extends Interactable
## Generic harvestable node for wood, fiber, and similar early resources.

@export var item_id: StringName = &"wood"
@export var amount: int = 3
@export var respawn_seconds: float = 40.0
@export var harvest_prompt: String = "Collect Wood"
@export var interaction_key: StringName = &"resource_node"
## Optional tool gate, e.g. ["axe"] for a tree. Empty means hands are enough.
@export var required_tool_tags: Array[StringName] = []
## Hotbar action that matches this node (gather / chop / mine).
@export var preferred_action: StringName = &"gather"

var _depleted := false
var _timer: Timer


func _ready() -> void:
	prompt_text = harvest_prompt
	interaction_id = interaction_key
	interaction_priority = 2
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = respawn_seconds
	_timer.timeout.connect(_respawn)
	add_child(_timer)
	super._ready()


func _can_interact(actor: Node) -> bool:
	return not _depleted and actor != null and actor.has_method("get_inventory")


func _on_interact(actor: Node) -> void:
	var inventory := actor.call("get_inventory") as InventoryContainer
	if inventory == null:
		return
	var leftover := inventory.add_item(item_id, amount)
	if leftover >= amount:
		return
	_depleted = true
	var visual := get_node_or_null("Visual/Harvest") as Node3D
	if visual != null:
		visual.visible = false
	_timer.start()


func _respawn() -> void:
	_depleted = false
	var visual := get_node_or_null("Visual/Harvest") as Node3D
	if visual != null:
		visual.visible = true
