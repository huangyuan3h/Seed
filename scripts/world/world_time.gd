extends Node
## Local planet calendar derived from [GameClock] world time.
##
## One local day is 30 real minutes (24 in-game hours), so one in-game hour is
## 75 real seconds. The calendar does not own time; sleeping or time-scale
## changes must move [GameClock].world_seconds and then call [method refresh_now].

signal minute_changed(day: int, hour: int, minute: int)
signal phase_changed(phase: StringName)
signal day_changed(day: int)

const SECONDS_PER_GAME_HOUR := 75.0
const DAY_LENGTH_REAL_SECONDS := SECONDS_PER_GAME_HOUR * 24.0
const START_HOUR := 6.0
const NIGHT_START_HOUR := 19
const DAWN_START_HOUR := 5
const DAY_START_HOUR := 7
const DUSK_START_HOUR := 17

var _last_day := -1
var _last_hour := -1
var _last_minute := -1
var _last_phase: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_day = get_day()
	_last_hour = get_hour()
	_last_minute = get_minute()
	_last_phase = get_phase()


func _process(_delta: float) -> void:
	_refresh(false)


func refresh_now() -> void:
	_refresh(true)


func get_world_seconds() -> float:
	var clock := get_node_or_null("/root/GameClock")
	if clock == null:
		return 0.0
	return maxf(0.0, float(clock.get("world_seconds")))


func get_day() -> int:
	return day_for(get_world_seconds())


func get_hour() -> int:
	return hour_for(get_world_seconds())


func get_minute() -> int:
	return minute_for(get_world_seconds())


func get_phase() -> StringName:
	return phase_for_hour(get_hour())


func get_clock_text() -> String:
	return format_clock(get_world_seconds())


func get_day_text() -> String:
	return format_day(get_day())


func get_phase_text() -> String:
	return String(get_phase())


func is_night() -> bool:
	return get_phase() == &"night"


func seconds_until_night() -> float:
	return seconds_until_hour(NIGHT_START_HOUR)


func seconds_until_dawn() -> float:
	return seconds_until_hour(DAWN_START_HOUR)


## Advances the world clock by a number of in-game hours.
func sleep_hours(hours: float) -> float:
	var seconds := maxf(0.0, hours) * SECONDS_PER_GAME_HOUR
	advance_by(seconds)
	return seconds


## Sleeps until the next occurrence of [param target_hour]. Returns real seconds skipped.
func sleep_until(target_hour: int) -> float:
	var seconds := seconds_until_hour(target_hour)
	advance_by(seconds)
	return seconds


func advance_by(seconds: float) -> void:
	if seconds <= 0.0:
		refresh_now()
		return
	var clock := get_node_or_null("/root/GameClock")
	if clock != null:
		clock.set("world_seconds", get_world_seconds() + seconds)
	refresh_now()


func total_local_hours(world_seconds: float) -> float:
	return START_HOUR + maxf(0.0, world_seconds) / SECONDS_PER_GAME_HOUR


func day_for(world_seconds: float) -> int:
	return int(floor(total_local_hours(world_seconds) / 24.0)) + 1


func hour_for(world_seconds: float) -> int:
	return int(floor(fmod(total_local_hours(world_seconds), 24.0)))


func minute_for(world_seconds: float) -> int:
	return int(floor(fmod(total_local_hours(world_seconds) * 60.0, 60.0)))


func format_clock(world_seconds: float) -> String:
	return "%02d:%02d" % [hour_for(world_seconds), minute_for(world_seconds)]


func format_day(day: int) -> String:
	return "DAY %03d" % maxi(1, day)


func phase_for_hour(hour: int) -> StringName:
	var wrapped := posmod(hour, 24)
	if wrapped >= DAWN_START_HOUR and wrapped < DAY_START_HOUR:
		return &"dawn"
	if wrapped >= DAY_START_HOUR and wrapped < DUSK_START_HOUR:
		return &"day"
	if wrapped >= DUSK_START_HOUR and wrapped < NIGHT_START_HOUR:
		return &"dusk"
	return &"night"


func seconds_to_game_hours(real_seconds: float) -> float:
	return maxf(0.0, real_seconds) / SECONDS_PER_GAME_HOUR


func seconds_until_hour(target_hour: int) -> float:
	var current_hours := fmod(total_local_hours(get_world_seconds()), 24.0)
	var delta := fmod(float(target_hour) - current_hours + 24.0, 24.0)
	if delta <= 0.001:
		delta = 24.0
	return delta * SECONDS_PER_GAME_HOUR


func _refresh(force: bool) -> void:
	var day := get_day()
	var hour := get_hour()
	var minute := get_minute()
	var phase := get_phase()
	if not force and day == _last_day and hour == _last_hour and minute == _last_minute and phase == _last_phase:
		return
	if day != _last_day:
		day_changed.emit(day)
	if phase != _last_phase:
		phase_changed.emit(phase)
	if force or day != _last_day or hour != _last_hour or minute != _last_minute:
		minute_changed.emit(day, hour, minute)
	_last_day = day
	_last_hour = hour
	_last_minute = minute
	_last_phase = phase
