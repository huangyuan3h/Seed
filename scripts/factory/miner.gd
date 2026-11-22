class_name Miner
extends FactoryMachine
## Powered miner. Sits on an ore node and produces one ore item into its output
## buffer; a LogisticsStation pulls the ore out.

var output_item: StringName = &"iron_ore"


func _init() -> void:
	machine_id = &"miner"
	display_name = "Miner"
	allowed_station = &"miner"
	power_draw = 8.0
	input_capacity = 0
	output_capacity = 20
	auto_start = true


func setup_miner(
	item_id: StringName,
	label: String,
	seconds: float,
	state: FactoryState,
	grid: PowerGrid
) -> void:
	output_item = item_id
	display_name = label
	var recipe := {
		"id": "mine_%s" % String(item_id),
		"display_name": "Mine %s" % String(item_id).capitalize(),
		"station": "miner",
		"inputs": {},
		"outputs": {String(item_id): 1},
		"seconds": maxf(0.5, seconds),
	}
	setup([recipe], state, grid)


func _station_color() -> Color:
	match String(output_item):
		"coal":
			return Color(0.18, 0.18, 0.20)
		"copper_ore":
			return Color(0.55, 0.35, 0.22)
		_:
			return Color(0.48, 0.30, 0.22)
