class_name VitalRow
extends HBoxContainer
## Compact stat row for the always-on HUD: label, bar, value.

var _stats: StatSet
var _stat_id: StringName = &""
var _title: Label = Label.new()
var _bar: ProgressBar = ProgressBar.new()
var _value: Label = Label.new()


func _init() -> void:
	add_theme_constant_override("separation", 6)
	custom_minimum_size = Vector2(236, 18)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_title.custom_minimum_size = Vector2(58, 0)
	_title.add_theme_font_size_override("font_size", 12)
	_title.add_theme_color_override("font_color", Color(0.93, 0.91, 0.86, 1.0))

	_bar.custom_minimum_size = Vector2(112, 9)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.step = 0.0
	_bar.show_percentage = false

	_value.custom_minimum_size = Vector2(42, 0)
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value.add_theme_font_size_override("font_size", 12)
	_value.add_theme_color_override("font_color", Color(0.93, 0.91, 0.86, 1.0))

	add_child(_title)
	add_child(_bar)
	add_child(_value)


func bind_stat(stats: StatSet, stat_id: StringName, title: String, color: Color = Color(0.47, 0.78, 0.85, 1.0)) -> void:
	unbind()
	_stats = stats
	_stat_id = stat_id
	_title.text = tr(title)
	_title.add_theme_color_override("font_color", color)
	_value.add_theme_color_override("font_color", color)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2
	_bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1.0, 1.0, 1.0, 0.10)
	bg.corner_radius_top_left = 2
	bg.corner_radius_top_right = 2
	bg.corner_radius_bottom_left = 2
	bg.corner_radius_bottom_right = 2
	_bar.add_theme_stylebox_override("background", bg)
	if _stats != null and not _stats.stat_changed.is_connected(_on_stat_changed):
		_stats.stat_changed.connect(_on_stat_changed)
	_refresh()


func unbind() -> void:
	if _stats != null and _stats.stat_changed.is_connected(_on_stat_changed):
		_stats.stat_changed.disconnect(_on_stat_changed)
	_stats = null
	_stat_id = &""


func get_value_text() -> String:
	return _value.text


func get_title_text() -> String:
	return _title.text


func _exit_tree() -> void:
	unbind()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		unbind()


func _on_stat_changed(stat_id: StringName, _current: float, _maximum: float) -> void:
	if stat_id == _stat_id:
		_refresh()


func _refresh() -> void:
	if _stats == null or _stat_id == &"":
		_bar.value = 0.0
		_value.text = "--"
		return
	_bar.value = _stats.get_ratio(_stat_id)
	var current := _stats.get_value(_stat_id)
	var maximum := _stats.get_max(_stat_id)
	if is_equal_approx(current, roundf(current)) and is_equal_approx(maximum, roundf(maximum)):
		_value.text = "%d/%d" % [int(roundf(current)), int(roundf(maximum))]
	else:
		_value.text = "%.0f/%.0f" % [current, maximum]
