extends DialogueInteractable
class_name ShipPod07Dialogue
## Pod 07 uses the content-driven dialogue tree instead of a one-line toast.


func _ready() -> void:
	dialogue = GameContent.dialogue(&"pod_07")
	display_name = "Pod 07"
	prompt_text = "Inspect Pod 07"
	interaction_priority = 5
	super._ready()


func _ensure_visual() -> void:
	# The pod model itself is the visual; do not spawn the dialogue NPC capsule.
	pass
