class_name FactoryContent
extends RefCounted
## Seed-specific data access for the simplified factory.
## Reads the `recipes` and `tech` tables through the shared ContentDatabase.

const RECIPE_TABLE := "recipes"
const TECH_TABLE := "tech"


static func recipes() -> Array[Dictionary]:
	return GameContent.database().rows(RECIPE_TABLE)


static func recipe(id: StringName) -> Dictionary:
	return GameContent.database().find(RECIPE_TABLE, String(id))


static func techs() -> Array[Dictionary]:
	return GameContent.database().rows(TECH_TABLE)


static func tech(id: StringName) -> Dictionary:
	return GameContent.database().find(TECH_TABLE, String(id))


static func tech_as_recipe(row: Dictionary) -> Dictionary:
	var tech_id := StringName(str(row.get("id", "")))
	return {
		"id": tech_id,
		"display_name": str(row.get("display_name", String(tech_id))),
		"station": "research",
		"inputs": (row.get("costs", {}) as Dictionary).duplicate(true),
		"outputs": {},
		"seconds": float(row.get("seconds", 10.0)),
		"requires": (row.get("requires", []) as Array).duplicate(),
		"unlocks": (row.get("unlocks", []) as Array).duplicate(),
		"is_tech": true,
	}


static func register_items(inventory: InventoryContainer) -> void:
	if inventory == null:
		return
	for def in GameContent.items():
		inventory.register_item(def)
