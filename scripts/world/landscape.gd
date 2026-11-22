extends Node3D
class_name SeedLandscape
## Deterministic low-poly terrain for the landing site.
##
## The centre stays perfectly flat so the graybox interactions keep their
## authored Y. Outside the flat ring the ground rises into soft, walkable hills
## and a distant rim. `sample_height()` lets GuPlayer follow the surface without
## a physics collider.

const GRID := 128
const SIZE := 300.0
const FLAT_RADIUS := 24.0

var _heights := PackedFloat32Array()
var _built := false
var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()

@onready var _terrain: MeshInstance3D = $Terrain


func _ready() -> void:
	_ensure_built()


## Bilinear height lookup that matches the rendered grid.
func sample_height(x: float, z: float) -> float:
	_ensure_built()
	if _heights.is_empty():
		return 0.0
	var half := SIZE * 0.5
	var step := SIZE / float(GRID)
	var gx := clampf((x + half) / step, 0.0, float(GRID))
	var gz := clampf((z + half) / step, 0.0, float(GRID))
	var ix := mini(int(floor(gx)), GRID - 1)
	var iz := mini(int(floor(gz)), GRID - 1)
	var fx := gx - float(ix)
	var fz := gz - float(iz)
	var i00 := iz * (GRID + 1) + ix
	var i10 := i00 + 1
	var i01 := i00 + (GRID + 1)
	var i11 := i01 + 1
	var h0 := lerpf(_heights[i00], _heights[i10], fx)
	var h1 := lerpf(_heights[i01], _heights[i11], fx)
	return lerpf(h0, h1, fz)


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_noise.seed = 2338
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.018
	_noise.fractal_octaves = 4
	_noise.fractal_gain = 0.48
	_detail.seed = 2339
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_detail.frequency = 0.075
	_detail.fractal_octaves = 3
	_build_heights()
	_build_mesh()


func _build_heights() -> void:
	var n := GRID + 1
	_heights.resize(n * n)
	var half := SIZE * 0.5
	var step := SIZE / float(GRID)
	for iz in n:
		var z := -half + float(iz) * step
		for ix in n:
			var x := -half + float(ix) * step
			_heights[iz * n + ix] = _height_at(x, z)


func _height_at(x: float, z: float) -> float:
	var r := sqrt(x * x + z * z)
	var rise := smoothstep(FLAT_RADIUS, 58.0, r)
	var rim := smoothstep(62.0, 138.0, r)
	var broad := _noise.get_noise_2d(x, z) * 0.5 + 0.5
	var fine := _detail.get_noise_2d(x, z) * 0.5 + 0.5
	var h := rise * (1.6 + 2.4 * broad)
	h += rim * (7.0 + 6.0 * fine + 5.0 * broad)
	# Flatten an impact shelf under the distant wreck so the ring stays below
	# the HUD line and the hull sits in the ground instead of on a hill.
	var ship_d := Vector2(x + 55.0, z + 140.0).length()
	var shelf := 1.0 - smoothstep(24.0, 70.0, ship_d)
	h = lerpf(h, 3.0, shelf)
	# Keep the playable disc dead flat; a tiny apron blends it outward.
	return maxf(h, 0.0)


func _build_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := SIZE * 0.5
	var step := SIZE / float(GRID)
	var n := GRID + 1
	for iz in GRID:
		var z0 := -half + float(iz) * step
		var z1 := z0 + step
		for ix in GRID:
			var x0 := -half + float(ix) * step
			var x1 := x0 + step
			var h00 := _heights[iz * n + ix]
			var h10 := _heights[iz * n + ix + 1]
			var h01 := _heights[(iz + 1) * n + ix]
			var h11 := _heights[(iz + 1) * n + ix + 1]
			var p00 := Vector3(x0, h00, z0)
			var p10 := Vector3(x1, h10, z0)
			var p01 := Vector3(x0, h01, z1)
			var p11 := Vector3(x1, h11, z1)
			_add_triangle(st, p00, p01, p11)
			_add_triangle(st, p00, p11, p10)
	var mesh := st.commit()
	_terrain.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/shaders/seed_ground.gdshader")
	material.set_shader_parameter("grass_colour", Color("#4c6b39").srgb_to_linear())
	material.set_shader_parameter("dry_colour", Color("#8a7a4a").srgb_to_linear())
	material.set_shader_parameter("dirt_colour", Color("#5a4a34").srgb_to_linear())
	material.set_shader_parameter("rock_colour", Color("#6e6c62").srgb_to_linear())
	_terrain.material_override = material
	_terrain.visibility_range_end = 420.0


func _add_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.y < 0.0:
		normal = -normal
	var centre := (a + b + c) / 3.0
	var col := _face_colour(centre, normal)
	for p in [a, b, c]:
		st.set_normal(normal)
		st.set_color(col)
		st.add_vertex(p)


func _face_colour(centre: Vector3, normal: Vector3) -> Color:
	var r := Vector2(centre.x, centre.z).length()
	var broad := _noise.get_noise_2d(centre.x, centre.z) * 0.5 + 0.5
	var fine := _detail.get_noise_2d(centre.x * 1.7, centre.z * 1.7) * 0.5 + 0.5
	var slope := 1.0 - clampf(normal.y, 0.0, 1.0)

	var grass := Color("#4c6b39").srgb_to_linear().lerp(Color("#5a6b3c").srgb_to_linear(), broad)
	grass = grass.lerp(Color("#8a7a4a").srgb_to_linear(), smoothstep(0.55, 0.82, fine) * 0.35)
	grass = grass.lerp(Color("#6e6a58").srgb_to_linear(), smoothstep(0.18, 0.52, slope) * 0.75)
	var pad := 1.0 - smoothstep(5.0, 15.0, r)
	grass = grass.lerp(Color("#5a4a34").srgb_to_linear(), pad * 0.55)
	var ship_d := Vector2(centre.x + 55.0, centre.z + 140.0).length()
	var scar := 1.0 - smoothstep(16.0, 62.0, ship_d)
	grass = grass.lerp(Color("#4a4038").srgb_to_linear(), scar * 0.6)
	return grass
