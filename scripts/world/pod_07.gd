extends DialogueInteractable
## Placeholder Pod 07 interactable for the opening anomaly.
## The real ship interior will replace the greybox visual later.

func _ready() -> void:
	display_name = "Pod 07"
	prompt_text = "Inspect Pod 07"
	interaction_id = "pod_07"
	interaction_priority = 6
	dialogue = GameContent.dialogue(&"pod_07")
	super._ready()
	var label := get_node_or_null("NameLabel") as Label3D
	if label != null:
		label.position = Vector3(0.0, 2.6, 0.0)
