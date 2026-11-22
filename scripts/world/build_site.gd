class_name BuildSite
extends Interactable
## Generic early build site. Consumes items and sets colony flags when built.

signal hint_requested(text: String)
signal built(site_id: StringName)

@export var site_id: StringName = &"shelter"
@export var build_prompt: String = "Build Shelter"
@export var required_items: Dictionary = {"wood": 5, "fiber": 3}
@export var flags_to_set: Dictionary = {"shelter_built": true}
@export var success_text: String = "Built."
## Optional tool gate for F-use, e.g. ["hammer"]. Empty means any tool works.
@export var required_tool_tags: Array[StringName] = []
## Hotbar action that matches this site.
@export var preferred_action: StringName = &"build"

var _inventory: InventoryContainer = null
var _flags: FlagStore = null
var _built := false


func _ready() -> void:
	prompt_text = build_prompt
	interaction_id = StringName("%s_site" % site_id)
	interaction_priority = 4
	super._ready()
	_refresh_visual()


func bind(inventory: InventoryContainer, flags: FlagStore) -> void:
	_inventory = inventory
	_flags = flags
	_built = _flags_are_set()
	_refresh_visual()


func _can_interact(_actor: Node) -> bool:
	return not _built


func _on_interact(_actor: Node) -> void:
	if _built:
		return
	if _inventory == null or _flags == null:
		hint_requested.emit(tr("Site offline."))
		return
	if not can_build():
		hint_requested.emit(requirements_summary())
		return
	for raw_id in required_items:
		var item_id := StringName(str(raw_id))
		_inventory.remove_item(item_id, int(required_items[raw_id]))
	for raw_flag in flags_to_set:
		_flags.set_flag(StringName(str(raw_flag)), flags_to_set[raw_flag])
	_built = true
	_refresh_visual()
	hint_requested.emit(tr(success_text))
	built.emit(site_id)


func can_build() -> bool:
	if _built or _inventory == null:
		return false
	for raw_id in required_items:
		var item_id := StringName(str(raw_id))
		if not _inventory.has_item(item_id, int(required_items[raw_id])):
			return false
	return true


func requirements_summary() -> String:
	var parts: Array[String] = []
	for raw_id in required_items:
		var item_id := StringName(str(raw_id))
		var need := int(required_items[raw_id])
		var have := _inventory.count_item(item_id) if _inventory != null else 0
		parts.append("%s (%d/%d)" % [tr(String(item_id)), have, need])
	var joined := ""
	for i in parts.size():
		if i > 0:
			joined += ", "
		joined += parts[i]
	return "%s %s" % [tr("Need:"), joined]


func _flags_are_set() -> bool:
	if _flags == null or flags_to_set.is_empty():
		return false
	for raw_flag in flags_to_set:
		var expected: Variant = flags_to_set[raw_flag]
		if _flags.get_flag(StringName(str(raw_flag)), null) != expected:
			return false
	return true


func _refresh_visual() -> void:
	var unbuilt := get_node_or_null("Unbuilt") as Node3D
	var built_visual := get_node_or_null("Built") as Node3D
	if unbuilt != null:
		unbuilt.visible = not _built
	if built_visual != null:
		built_visual.visible = _built
