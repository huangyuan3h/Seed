class_name ResearchBench
extends FactoryMachine
## Research bench: tech rows are converted into recipes whose inputs are the
## research costs. Completing one unlocks the tech in FactoryState.

signal tech_unlocked(tech_id: StringName)


func _init() -> void:
	machine_id = &"research_bench"
	display_name = "Research Bench"
	allowed_station = &"research"
	power_draw = 2.0
	input_capacity = 80
	output_capacity = 0
	auto_start = true


func setup_research(tech_rows: Array[Dictionary], state: FactoryState, grid: PowerGrid) -> void:
	var research_recipes: Array[Dictionary] = []
	for row in tech_rows:
		research_recipes.append(FactoryContent.tech_as_recipe(row))
	setup(research_recipes, state, grid)


func _apply_completion(row: Dictionary) -> void:
	if not bool(row.get("is_tech", false)):
		return
	if _factory_state == null:
		return
	var tech_id := StringName(str(row.get("id", "")))
	if _factory_state.unlock(tech_id):
		tech_unlocked.emit(tech_id)
		var next_rows := get_available_recipes()
		if not next_rows.is_empty():
			select_recipe(StringName(str(next_rows[0].get("id", ""))))
