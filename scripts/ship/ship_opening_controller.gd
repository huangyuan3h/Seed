extends Node
class_name ShipOpeningController
## Drives the first ship beat: wake -> suit -> Pod 07 dialogue -> D3 airlock.
## The dialogue tree is the real content table (`pod_07`), not a toast.

@onready var _pod: ShipPod07Dialogue = get_node_or_null("ShipInterior/CryoBay/Pod07Dialogue")
@onready var _suit: ShipInteractable = get_node_or_null("ShipInterior/CryoBay/SuitRackInteract")
@onready var _airlock: ShipTransition = get_node_or_null("ShipInterior/SpineCorridor/AirlockInteract")
@onready var _objective: Label = get_node_or_null("UI/Objective")

var _flags := FlagStore.new()
var _quests := QuestTracker.new()
var _inventory := InventoryContainer.new(16, 99)
var _dialogue_box: DialogueBox = null
var _opening_complete := false


func _ready() -> void:
	var session := get_node_or_null("/root/SeedSession")
	if session != null:
		_opening_complete = bool(session.get("opening_complete"))
	for item_def in GameContent.items():
		_inventory.register_item(item_def)
	_setup_dialogue_box()
	if _pod != null:
		_pod.dialogue = GameContent.dialogue(&"pod_07")
		_pod.interacted.connect(_on_pod_interacted)
	if _suit != null:
		_suit.interacted.connect(_on_suit_interacted)
	if _airlock != null:
		_airlock.enabled = _opening_complete
	if _opening_complete:
		_set_objective("Explore the ship. The D3 airlock leads outside.")
		if _pod != null:
			_pod.enabled = true
	else:
		if _pod != null:
			_pod.enabled = false
		_set_objective("EDEN // WAKE — put on the power suit.")
		call_deferred("_show_wake")


func _setup_dialogue_box() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DialogueLayer"
	layer.layer = 40
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_dialogue_box = DialogueBox.new()
	_dialogue_box.name = "DialogueBox"
	layer.add_child(_dialogue_box)
	_dialogue_box.bind(_flags, _quests, _inventory, get_node_or_null("/root/EventBus"))
	_dialogue_box.dialogue_ended.connect(_on_dialogue_ended)


func _show_wake() -> void:
	var ui := get_node_or_null("/root/UIRouter")
	if ui != null and ui.has_method("show_toast"):
		ui.call("show_toast", "EDEN // WAKE", 2.0, &"info")


func _on_suit_interacted(_actor: Node) -> void:
	if _flags.get_bool(&"suit_equipped"):
		return
	_flags.set_flag(&"suit_equipped", true)
	if _pod != null:
		_pod.enabled = true
	_set_objective("Inspect Pod 07.")
	var ui := get_node_or_null("/root/UIRouter")
	if ui != null and ui.has_method("show_toast"):
		ui.call("show_toast", "Power suit online. Battery 62%.", 2.6, &"info")


func _on_pod_interacted(_actor: Node) -> void:
	# The dialogue tree sets `pod_07_inspected`; see _on_dialogue_ended.
	pass


func _on_dialogue_ended(dialogue_id: StringName) -> void:
	if dialogue_id != &"pod_07":
		return
	if not _flags.get_bool(&"pod_07_inspected"):
		return
	if not _flags.get_bool(&"suit_equipped"):
		_set_objective("Put on the power suit, then leave through the airlock.")
		return
	if _airlock != null:
		_airlock.enabled = true
	_set_objective("Leave through the D3 airlock.")
	var ui := get_node_or_null("/root/UIRouter")
	if ui != null and ui.has_method("show_toast"):
		ui.call("show_toast", "Airlock ready. The crash site is outside.", 2.6, &"info")


func _set_objective(text: String) -> void:
	if _objective != null:
		_objective.text = text
