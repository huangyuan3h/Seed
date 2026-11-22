extends Interactable
class_name ShipInteractable
## Blockout inspection point. Shows a short diegetic message through UIRouter.
## Replace with DialogueInteractable when the ship has a dialogue box.

@export_multiline var message: String = ""
@export var message_key: String = ""
@export var event_id: StringName = &"ship_inspect"


func _on_interact(_actor: Node) -> void:
	var text := tr(message_key) if message_key != "" else tr(message)
	if text != "":
		var ui := get_node_or_null("/root/UIRouter")
		if ui != null and ui.has_method("show_toast"):
			ui.call("show_toast", text, 4.0, &"info")
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_method("emit_event"):
		bus.call("emit_event", event_id, {"interaction_id": interaction_id})
