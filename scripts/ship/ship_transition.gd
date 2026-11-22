extends Interactable
class_name ShipTransition
## Blockout scene transition: ship interior <-> exterior crash site.

@export_file("*.tscn") var target_scene: String = ""
@export var transition_message: String = ""
@export var destination_key: String = ""
@export var destination_spawn: Vector3 = Vector3.ZERO
@export var mark_return_from_ship: bool = false


func _on_interact(_actor: Node) -> void:
	if transition_message != "":
		var ui := get_node_or_null("/root/UIRouter")
		if ui != null and ui.has_method("show_toast"):
			ui.call("show_toast", tr(transition_message), 1.2, &"info")
	var session := get_node_or_null("/root/SeedSession")
	if session != null:
		if destination_key != "":
			session.call("set_spawn", destination_key, destination_spawn)
		if mark_return_from_ship:
			session.set("return_from_ship", true)
			session.set("opening_complete", true)
	if target_scene != "" and ResourceLoader.exists(target_scene):
		get_tree().change_scene_to_file(target_scene)
