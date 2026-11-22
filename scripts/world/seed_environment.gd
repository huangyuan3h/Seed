extends Node3D
## Dawn-to-night lighting for the landing site.
##
## The sun, moon, fog and procedural sky are driven by Seed's WorldTime clock so
## the HUD's `DAY 001 06:00 DAWN` line matches what the player sees.

const SUNRISE_HOUR := 6.0
const SUNSET_HOUR := 18.0

const DAY_TOP := Color("#4a7187")
const DAY_HORIZON := Color("#bec9bf")
const DUSK_HORIZON := Color("#d9b48a")
const NIGHT_TOP := Color("#0b1424")
const NIGHT_HORIZON := Color("#1b2a3a")
const NIGHT_GROUND := Color("#0a1410")
const DUSK_TOP := Color("#35525f")
const DAY_GROUND := Color("#3b5033")
const SUN_HIGH := Color("#ffe6c4")
const SUN_LOW := Color("#ff9a5a")
const FOG_DAY := Color("#b0b8ac")
const FOG_NIGHT := Color("#1b2630")
const FOG_DUSK := Color("#c9a883")

@onready var _sun: DirectionalLight3D = $SunLight
@onready var _moon: DirectionalLight3D = $MoonLight
@onready var _world_environment: WorldEnvironment = $WorldEnvironment

var _sky_mat: ShaderMaterial = null
var _night := 0.0


func _ready() -> void:
	var env := _world_environment.environment
	if env != null and env.sky != null and env.sky.sky_material is ShaderMaterial:
		_sky_mat = env.sky.sky_material as ShaderMaterial
	_update_lighting()


func _process(_delta: float) -> void:
	_update_lighting()


## Consumed by GuPlayer's headlight and audio context.
func get_night_factor() -> float:
	return _night


func get_weather_params() -> Dictionary:
	return {"wetness": 0.0, "snow_cover": 0.0, "rain": 0.0}


func _update_lighting() -> void:
	var hours := _local_hours()
	var solar := fmod(hours - SUNRISE_HOUR + 24.0, 24.0) / 24.0 * TAU
	var elev := sin(solar) * 0.95 + 0.28
	var azimuth := cos(solar) * 0.95
	var dir := Vector3(sin(azimuth) * cos(elev), sin(elev), cos(azimuth) * cos(elev)).normalized()

	var sun_amount := smoothstep(-0.02, 0.15, elev)
	_night = 1.0 - smoothstep(-0.15, 0.05, elev)
	var sunset := clampf(1.0 - elev / 0.45, 0.0, 1.0) * (1.0 - _night * 0.7)

	_sun.look_at_from_position(dir * 100.0, Vector3.ZERO, Vector3.UP)
	_sun.light_energy = 1.4 * sun_amount
	_sun.light_color = SUN_LOW.lerp(SUN_HIGH, smoothstep(0.03, 0.7, elev))
	_sun.visible = _sun.light_energy > 0.01

	_moon.look_at_from_position(-dir * 100.0, Vector3.UP * 0.0, Vector3.UP)
	_moon.light_energy = 0.16 * _night
	_moon.visible = _moon.light_energy > 0.01

	var env := _world_environment.environment
	env.ambient_light_energy = 0.16 + 0.62 * sun_amount
	env.fog_light_color = FOG_NIGHT.lerp(FOG_DUSK, sunset).lerp(FOG_DAY, sun_amount * 0.8)

	if _sky_mat != null:
		_sky_mat.set_shader_parameter("sun_dir", dir)
		_sky_mat.set_shader_parameter("moon_dir", -dir)
		_sky_mat.set_shader_parameter("day_factor", sun_amount)
		_sky_mat.set_shader_parameter("night_factor", _night)
		_sky_mat.set_shader_parameter("sunset_factor", sunset)
		var top := DAY_TOP.lerp(DUSK_TOP, sunset).lerp(NIGHT_TOP, _night)
		var horizon := DAY_HORIZON.lerp(DUSK_HORIZON, sunset).lerp(NIGHT_HORIZON, _night)
		var ground := DAY_GROUND.lerp(NIGHT_GROUND, _night)
		_sky_mat.set_shader_parameter("sky_top_col", top)
		_sky_mat.set_shader_parameter("sky_horizon_col", horizon)
		_sky_mat.set_shader_parameter("ground_col", ground)


func _local_hours() -> float:
	var wt := get_node_or_null("/root/WorldTime")
	if wt != null and wt.has_method("total_local_hours") and wt.has_method("get_world_seconds"):
		return fmod(float(wt.call("total_local_hours", wt.call("get_world_seconds"))), 24.0)
	return 6.0
