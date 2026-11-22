extends Node3D
## Distant silhouette of the seed ship, half-buried in the valley. The player
## should read it before they can reach it: a landmark, not a level.

@onready var _beacon: OmniLight3D = $BeaconLight
@onready var _beacon_mesh: MeshInstance3D = $Beacon

var _time := 0.0


func _ready() -> void:
	var parent := get_parent()
	var landscape: SeedLandscape = null
	if parent != null:
		landscape = parent.get_node_or_null("Landscape") as SeedLandscape
	if landscape != null:
		global_position.y = landscape.sample_height(global_position.x, global_position.z) - 3.0


func _process(delta: float) -> void:
	_time += delta
	var pulse := 0.6 + 0.4 * sin(_time * 1.7)
	_beacon.light_energy = 1.4 * pulse
	if _beacon_mesh.material_override is StandardMaterial3D:
		var mat := _beacon_mesh.material_override as StandardMaterial3D
		mat.emission_energy_multiplier = 1.2 + pulse
