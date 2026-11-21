extends Interactable
## Minimal harvestable berry bush for the early hunger loop.

@export var item_id: StringName = &"wild_berry"
@export var amount: int = 3
@export var respawn_seconds: float = 30.0

var _depleted := false
var _timer: Timer


func _ready() -> void:
	prompt_text = "Harvest Berries"
	interaction_id = "berry_bush"
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
	var berries := get_node_or_null("Visual/Berries") as Node3D
	if berries != null:
		berries.visible = false
	_timer.start()


func _respawn() -> void:
	_depleted = false
	var berries := get_node_or_null("Visual/Berries") as Node3D
	if berries != null:
		berries.visible = true
