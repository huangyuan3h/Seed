class_name FactoryState
extends RefCounted
## Tracks unlocked factory technologies. Optionally mirrors unlocks into a FlagStore.

signal tech_unlocked(tech_id: StringName)

var flags: FlagStore = null
var _unlocked: Dictionary = {} ## String -> true


func _init(p_flags: FlagStore = null) -> void:
	flags = p_flags


func is_unlocked(tech_id: StringName) -> bool:
	return bool(_unlocked.get(String(tech_id), false))


func unlock(tech_id: StringName) -> bool:
	if tech_id == &"" or is_unlocked(tech_id):
		return false
	_unlocked[String(tech_id)] = true
	if flags != null:
		flags.set_flag(StringName("tech_%s" % String(tech_id)), true)
	tech_unlocked.emit(tech_id)
	return true


func can_research(tech_row: Dictionary) -> bool:
	var tech_id := StringName(str(tech_row.get("id", "")))
	if tech_id == &"" or is_unlocked(tech_id):
		return false
	for raw_req in tech_row.get("requires", []) as Array:
		var req := StringName(str(raw_req))
		if req != &"" and not is_unlocked(req):
			return false
	return true


func list_unlocked() -> Array[StringName]:
	var out: Array[StringName] = []
	for key: String in _unlocked.keys():
		out.append(StringName(key))
	out.sort()
	return out


func export_state() -> Dictionary:
	return {"unlocked": _unlocked.keys()}


func apply_state(doc: Dictionary) -> void:
	_unlocked.clear()
	for raw in doc.get("unlocked", []) as Array:
		var tech_id := StringName(str(raw))
		if tech_id != &"":
			_unlocked[String(tech_id)] = true
