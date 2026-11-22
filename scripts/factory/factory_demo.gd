class_name FactoryDemo
extends Node3D
## Self-contained F1 factory lab: hand-fed smelter → workbench → research bench.
## It adds machines near the player without touching main.tscn, so the art /
## landscape stream can keep working in parallel.

const STARTER_ITEMS := {
	"iron_ore": 50,
	"coal": 30,
	"copper_ore": 10,
	"wood": 10,
	"stone": 10,
}

@export var enable_logistics := false

var _player: GuPlayer = null
var _inventory: InventoryContainer = null
var _state: FactoryState = null
var _grid: PowerGrid = null
var _panel: FactoryPanel = null
var _site: Node3D = null
var _power_label: Label = null

var _generator: ThermalGenerator = null
var _generator_2: ThermalGenerator = null
var _smelter: FactoryMachine = null
var _workbench: FactoryMachine = null
var _research: ResearchBench = null

var _road: RoadNetwork = null
var _stations: Array[LogisticsStation] = []
var _trucks: Array[SteamTruck] = []
var _logistics_panel: LogisticsPanel = null
var _road_builder: RoadBuilder = null
var _road_label: Label = null
var _road_button: Button = null
var _iron_station: LogisticsStation = null
var _coal_station: LogisticsStation = null
var _smelter_station: LogisticsStation = null
var _workbench_station: LogisticsStation = null
var _research_station: LogisticsStation = null


func _ready() -> void:
	_player = _find_player()
	if _player == null:
		push_warning("FactoryDemo: no GuPlayer found; factory lab disabled.")
		return
	_inventory = _player.get_inventory()
	FactoryContent.register_items(_inventory)
	var flags := get_parent().get("_flags") as FlagStore
	_state = FactoryState.new(flags)
	if enable_logistics:
		_state.unlock(&"basic_automation")
	_grid = PowerGrid.new()
	_site = Node3D.new()
	_site.name = "FactorySite"
	add_child(_site)
	_spawn_machines()
	if enable_logistics:
		_setup_logistics()
	_spawn_starter_items()
	_spawn_ui()
	if enable_logistics:
		_assign_demo_routes()
		_toast("F2 logistics lab ready. Build roads with the Build Road button; trucks will start automatically.", 4.5)
	else:
		_toast("Factory lab ready. Add coal to the generator, then feed the smelter.", 4.0)


func _process(_delta: float) -> void:
	if _power_label != null and _grid != null:
		_power_label.text = "Power  supply %.0f / demand %.0f  (%d%%)" % [
			_grid.supply,
			_grid.demand,
			int(round(_grid.satisfaction * 100.0)),
		]
	if _road_label != null and _road != null:
		var stone := _inventory.count_item(&"stone") if _inventory != null else 0
		var mode := "ON" if _road_builder != null and _road_builder.is_active() else "off"
		_road_label.text = "Roads: %d tiles | Stone: %d | Build mode: %s" % [_road.cell_count(), stone, mode]


func _find_player() -> GuPlayer:
	var parent := get_parent()
	if parent != null:
		var direct := parent.get_node_or_null("Player") as GuPlayer
		if direct != null:
			return direct
	for node in get_tree().get_nodes_in_group("player"):
		if node is GuPlayer:
			return node as GuPlayer
	return null


func _spawn_machines() -> void:
	_generator = ThermalGenerator.new()
	_generator.name = "ThermalGenerator"
	_generator.position = Vector3(5.0, 0.0, 4.0)
	_site.add_child(_generator)
	_generator.setup(_grid)
	_generator.hint_requested.connect(_toast)

	_smelter = FactoryMachine.new()
	_smelter.name = "Smelter"
	_smelter.machine_id = &"smelter"
	_smelter.display_name = "Smelter"
	_smelter.allowed_station = &"smelter"
	_smelter.power_draw = 5.0
	_smelter.input_capacity = 60
	_smelter.output_capacity = 60
	_smelter.position = Vector3(7.0, 0.0, 4.0)
	_site.add_child(_smelter)
	_smelter.setup(FactoryContent.recipes(), _state, _grid)
	_smelter.interaction_requested.connect(_on_machine_interaction)

	_workbench = FactoryMachine.new()
	_workbench.name = "Workbench"
	_workbench.machine_id = &"workbench"
	_workbench.display_name = "Workbench"
	_workbench.allowed_station = &"workbench"
	_workbench.power_draw = 3.0
	_workbench.input_capacity = 40
	_workbench.output_capacity = 40
	_workbench.position = Vector3(9.0, 0.0, 4.0)
	_site.add_child(_workbench)
	_workbench.setup(FactoryContent.recipes(), _state, _grid)
	_workbench.interaction_requested.connect(_on_machine_interaction)

	_research = ResearchBench.new()
	_research.name = "ResearchBench"
	_research.position = Vector3(11.0, 0.0, 4.0)
	_site.add_child(_research)
	_research.setup_research(FactoryContent.techs(), _state, _grid)
	_research.interaction_requested.connect(_on_machine_interaction)
	_research.tech_unlocked.connect(_on_tech_unlocked)


func _setup_logistics() -> void:
	_road = RoadNetwork.new()
	_road.setup_visual(_site)

	_generator_2 = ThermalGenerator.new()
	_generator_2.name = "ThermalGenerator2"
	_generator_2.position = Vector3(3.0, 0.0, 4.0)
	_site.add_child(_generator_2)
	_generator_2.setup(_grid)
	_generator_2.hint_requested.connect(_toast)
	_generator.add_fuel(&"coal", 40)
	_generator_2.add_fuel(&"coal", 40)

	var iron_node := OreNode.new()
	iron_node.name = "IronOreNode"
	iron_node.item_id = &"iron_ore"
	iron_node.display_name = "Iron Ore"
	iron_node.position = Vector3(2.0, 0.0, 10.0)
	_site.add_child(iron_node)

	var coal_node := OreNode.new()
	coal_node.name = "CoalNode"
	coal_node.item_id = &"coal"
	coal_node.display_name = "Coal"
	coal_node.position = Vector3(2.0, 0.0, 12.0)
	_site.add_child(coal_node)

	var iron_miner := Miner.new()
	iron_miner.name = "IronMiner"
	iron_miner.output_item = &"iron_ore"
	iron_miner.position = Vector3(2.0, 0.9, 10.0)
	_site.add_child(iron_miner)
	iron_miner.setup_miner(&"iron_ore", "Iron Miner", 2.0, _state, _grid)

	var coal_miner := Miner.new()
	coal_miner.name = "CoalMiner"
	coal_miner.output_item = &"coal"
	coal_miner.position = Vector3(2.0, 0.9, 12.0)
	_site.add_child(coal_miner)
	coal_miner.setup_miner(&"coal", "Coal Miner", 2.5, _state, _grid)

	_iron_station = _make_station(&"iron_station", "Iron Mine", Vector3(4.0, 0.0, 10.0))
	_iron_station.bind_producer(iron_miner)
	_coal_station = _make_station(&"coal_station", "Coal Mine", Vector3(4.0, 0.0, 12.0))
	_coal_station.bind_producer(coal_miner)
	_smelter_station = _make_station(&"smelter_station", "Smelter", Vector3(7.0, 0.0, 6.0))
	_smelter_station.bind_producer(_smelter)
	_smelter_station.bind_consumer(_smelter)
	_workbench_station = _make_station(&"workbench_station", "Workbench", Vector3(9.0, 0.0, 6.0))
	_workbench_station.bind_producer(_workbench)
	_workbench_station.bind_consumer(_workbench)
	_research_station = _make_station(&"research_station", "Research", Vector3(11.0, 0.0, 6.0))
	_research_station.bind_consumer(_research)

	for station in [_iron_station, _coal_station, _smelter_station, _workbench_station, _research_station]:
		station.add_fuel(&"coal", 20)
		_road.reserve_cell(station.cell)

	for occupied in [_generator, _generator_2, _smelter, _workbench, _research, iron_node, coal_node, iron_miner, coal_miner]:
		if occupied is Node3D:
			_road.reserve_cell(_road.cell_for((occupied as Node3D).global_position))

	if _inventory != null:
		_inventory.add_item(&"stone", 220)

	_road_builder = RoadBuilder.new()
	_road_builder.name = "RoadBuilder"
	add_child(_road_builder)
	_road_builder.setup(_road, _inventory)
	_road_builder.hint_requested.connect(_toast)
	_road_builder.active_changed.connect(_on_road_mode_changed)

	var truck_names := ["Iron Hauler", "Coal Hauler", "Plate Hauler", "Parts Hauler"]
	for i in range(truck_names.size()):
		var truck := SteamTruck.new()
		truck.name = "Truck%d" % (i + 1)
		truck.truck_id = StringName("truck_%d" % (i + 1))
		truck.display_name = truck_names[i]
		_site.add_child(truck)
		_trucks.append(truck)


func build_demo_roads() -> void:
	## Test/author helper: auto-build the four demo routes. Not called in play.
	if _road == null:
		return
	_road.add_road(_iron_station.global_position, _smelter_station.global_position)
	_road.add_road(_coal_station.global_position, _smelter_station.global_position)
	_road.add_road(_smelter_station.global_position, _workbench_station.global_position)
	_road.add_road(_workbench_station.global_position, _research_station.global_position)


func _make_station(id: StringName, label: String, position: Vector3) -> LogisticsStation:
	var station := LogisticsStation.new()
	station.name = String(id).capitalize()
	station.position = position
	_site.add_child(station)
	station.setup(id, label, _road, _grid)
	station.hint_requested.connect(_toast)
	_stations.append(station)
	return station


func _assign_demo_routes() -> void:
	if _trucks.size() < 4:
		return
	_trucks[0].assign_route(_iron_station, _smelter_station, &"iron_ore", _road)
	_trucks[1].assign_route(_coal_station, _smelter_station, &"coal", _road)
	_trucks[2].assign_route(_smelter_station, _workbench_station, &"iron_plate", _road)
	_trucks[3].assign_route(_workbench_station, _research_station, &"mechanical_part", _road)
	_toast("Demo routes: iron -> smelter, coal -> smelter, plates -> workbench, parts -> research.", 4.0)


func _spawn_starter_items() -> void:
	if _inventory == null:
		return
	for raw_id in STARTER_ITEMS:
		_inventory.add_item(StringName(str(raw_id)), int(STARTER_ITEMS[raw_id]))


func _spawn_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FactoryLayer"
	layer.layer = 30
	add_child(layer)

	var help_panel := PanelContainer.new()
	help_panel.name = "FactoryHelp"
	help_panel.position = Vector2(16.0, 16.0)
	help_panel.custom_minimum_size = Vector2(430.0, 0.0)
	layer.add_child(help_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	help_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "F2 LOGISTICS LAB" if enable_logistics else "F1 FACTORY LAB"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var steps := Label.new()
	steps.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if enable_logistics:
		steps.text = "E: add fuel / inspect station\nTrucks: iron -> smelter, coal -> smelter, plates -> workbench, parts -> research\nOpen Logistics to change a route. Research needs 15 parts for Copper Working."
	else:
		steps.text = "E: use machine\n1. Generator: add wood/coal\n2. Smelter: iron ore + coal -> iron plate\n3. Workbench: 2 iron plates -> 1 mechanical part\n4. Research bench: 10 parts -> Basic Automation"
	vbox.add_child(steps)

	_power_label = Label.new()
	_power_label.text = "Power  supply 0 / demand 0  (0%)"
	vbox.add_child(_power_label)

	var refill := Button.new()
	refill.text = "Refill starter materials"
	refill.pressed.connect(_refill_materials)
	vbox.add_child(refill)

	if enable_logistics:
		var logistics_button := Button.new()
		logistics_button.text = "Logistics"
		logistics_button.pressed.connect(_open_logistics)
		vbox.add_child(logistics_button)

	_panel = FactoryPanel.new()
	_panel.name = "FactoryPanel"
	layer.add_child(_panel)

	if enable_logistics:
		_logistics_panel = LogisticsPanel.new()
		_logistics_panel.name = "LogisticsPanel"
		layer.add_child(_logistics_panel)
		_logistics_panel.auto_routes_requested.connect(_assign_demo_routes)


func _open_logistics() -> void:
	if _logistics_panel == null:
		return
	_logistics_panel.bind(_trucks, _stations, _road)


func _on_machine_interaction(machine: FactoryMachine, actor: Node) -> void:
	var inventory := _inventory
	if actor != null and actor.has_method("get_inventory"):
		inventory = actor.call("get_inventory") as InventoryContainer
	if inventory == null:
		return
	_panel.bind(machine, inventory, _state)


func _on_tech_unlocked(tech_id: StringName) -> void:
	var row := FactoryContent.tech(tech_id)
	var label := str(row.get("display_name", String(tech_id)))
	_toast("Technology unlocked: %s" % label, 4.0)


func _refill_materials() -> void:
	if _inventory == null:
		return
	for raw_id in STARTER_ITEMS:
		_inventory.add_item(StringName(str(raw_id)), int(STARTER_ITEMS[raw_id]))
	_toast("Starter materials refilled.", 2.0)


func _toast(text: String, duration: float = 2.5) -> void:
	if text.strip_edges() == "":
		return
	var ui := get_node_or_null("/root/UIRouter")
	if ui != null and ui.has_method("show_toast"):
		ui.call("show_toast", text, duration, &"info")
	else:
		print(text)
