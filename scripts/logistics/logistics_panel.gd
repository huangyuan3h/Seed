class_name LogisticsPanel
extends Control
## Small route editor: choose a truck, a pickup station, a dropoff station, and
## one item type. The first slice auto-creates demo routes; this panel lets the
## player change them.

signal closed
signal auto_routes_requested

const CONTEXT_OWNER := &"logistics_panel"
const UI_CONTEXT := 1
const ITEM_IDS := ["iron_ore", "coal", "iron_plate", "mechanical_part", "electrical_part", "copper"]

var _trucks: Array[SteamTruck] = []
var _stations: Array[LogisticsStation] = []
var _road: RoadNetwork = null
var _open := false
var _context_pushed := false

var _truck_option: OptionButton
var _pickup_option: OptionButton
var _dropoff_option: OptionButton
var _item_option: OptionButton
var _status_label: Label
var _route_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()


func _exit_tree() -> void:
	_pop_context()


func _unhandled_input(event: InputEvent) -> void:
	if not _open or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not _open:
		return
	var truck := _selected_truck()
	if truck != null:
		_status_label.text = truck.get_status_text()
		_route_label.text = truck.get_route_text()
	else:
		_status_label.text = "No truck selected."
		_route_label.text = ""


func bind(trucks: Array[SteamTruck], stations: Array[LogisticsStation], road: RoadNetwork) -> void:
	_trucks = trucks
	_stations = stations
	_road = road
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_open = true
	_push_context()
	_rebuild()
	_populate_from_truck(_selected_truck())


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pop_context()
	closed.emit()


func is_open() -> bool:
	return _open


func _selected_truck() -> SteamTruck:
	var index := _truck_option.selected
	if index < 0 or index >= _trucks.size():
		return null
	return _trucks[index]


func _selected_station(option: OptionButton) -> LogisticsStation:
	var index := option.selected
	if index < 0 or index >= _stations.size():
		return null
	return _stations[index]


func _rebuild() -> void:
	_truck_option.clear()
	for i in range(_trucks.size()):
		var truck := _trucks[i]
		_truck_option.add_item("%s: %s" % [truck.display_name, truck.get_route_text()])
		_truck_option.set_item_metadata(i, i)
	_pickup_option.clear()
	_dropoff_option.clear()
	for i in range(_stations.size()):
		var station := _stations[i]
		_pickup_option.add_item(station.display_name)
		_pickup_option.set_item_metadata(i, i)
		_dropoff_option.add_item(station.display_name)
		_dropoff_option.set_item_metadata(i, i)
	_item_option.clear()
	for i in range(ITEM_IDS.size()):
		_item_option.add_item(String(ITEM_IDS[i]).capitalize())
		_item_option.set_item_metadata(i, ITEM_IDS[i])
	if _trucks.size() > 0:
		_truck_option.select(0)


func _populate_from_truck(truck: SteamTruck) -> void:
	if truck == null:
		return
	if truck.pickup != null:
		var pi := _stations.find(truck.pickup)
		if pi >= 0:
			_pickup_option.select(pi)
	if truck.dropoff != null:
		var di := _stations.find(truck.dropoff)
		if di >= 0:
			_dropoff_option.select(di)
	var ii := ITEM_IDS.find(String(truck.item_id))
	if ii >= 0:
		_item_option.select(ii)


func _on_truck_selected(_index: int) -> void:
	_populate_from_truck(_selected_truck())


func _on_assign_pressed() -> void:
	var truck := _selected_truck()
	var pickup := _selected_station(_pickup_option)
	var dropoff := _selected_station(_dropoff_option)
	var item_index := _item_option.selected
	if truck == null or pickup == null or dropoff == null or item_index < 0:
		return
	var item_id := StringName(str(_item_option.get_item_metadata(item_index)))
	var selected_truck_index := _truck_option.selected
	truck.assign_route(pickup, dropoff, item_id, _road)
	_rebuild()
	if selected_truck_index >= 0 and selected_truck_index < _trucks.size():
		_truck_option.select(selected_truck_index)
	_populate_from_truck(_selected_truck())


func _push_context() -> void:
	if _context_pushed:
		return
	var ir := get_node_or_null("/root/InputRouter")
	if ir != null and ir.has_method("push_context"):
		ir.call("push_context", UI_CONTEXT, CONTEXT_OWNER)
		_context_pushed = true


func _pop_context() -> void:
	if not _context_pushed:
		return
	var ir := get_node_or_null("/root/InputRouter")
	if ir != null and ir.has_method("pop_context"):
		ir.call("pop_context", CONTEXT_OWNER)
	_context_pushed = false


func _build_ui() -> void:
	var theme_path := "res://addons/gu_core/ui/default_theme.tres"
	if ResourceLoader.exists(theme_path):
		theme = load(theme_path) as Theme

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "LogisticsPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -310.0
	panel.offset_right = 310.0
	panel.offset_top = -230.0
	panel.offset_bottom = 230.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "LOGISTICS"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	_truck_option = OptionButton.new()
	_truck_option.item_selected.connect(_on_truck_selected)
	vbox.add_child(_labeled_row("Truck", _truck_option))

	_pickup_option = OptionButton.new()
	vbox.add_child(_labeled_row("Pickup", _pickup_option))

	_dropoff_option = OptionButton.new()
	vbox.add_child(_labeled_row("Dropoff", _dropoff_option))

	_item_option = OptionButton.new()
	vbox.add_child(_labeled_row("Item", _item_option))

	_route_label = Label.new()
	_route_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	vbox.add_child(_route_label)

	_status_label = Label.new()
	_status_label.add_theme_color_override("font_color", Color(0.72, 0.80, 0.70))
	vbox.add_child(_status_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	vbox.add_child(buttons)

	var assign := Button.new()
	assign.text = "Assign route"
	assign.pressed.connect(_on_assign_pressed)
	buttons.add_child(assign)

	var auto := Button.new()
	auto.text = "Restore demo routes"
	auto.pressed.connect(func() -> void: auto_routes_requested.emit())
	buttons.add_child(auto)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(close)
	buttons.add_child(close_button)


func _labeled_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(90.0, 0.0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row
