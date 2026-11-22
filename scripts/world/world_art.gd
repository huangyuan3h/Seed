extends Node3D
## Deterministic set dressing for the landing site: grass, wildflowers, shrubs,
## boulders, pines and broadleaf trees, all batched through MultiMesh.
##
## Everything is generated in code so the repo stays free of large binary assets
## and the scene remains a readable graybox underneath.

const GRASS_COUNT := 26000
const FLOWER_COUNT := 300
const SHRUB_COUNT := 220
const ROCK_COUNT := 130
const TREE_COUNT := 220
const TREE_CLEAR_RADIUS := 27.0
const ROCK_CLEAR_RADIUS := 16.0
const SHRUB_CLEAR_RADIUS := 14.0
const SHIP_CLEAR_RADIUS := 20.0
const PLAY_RADIUS := 118.0

var _rng := RandomNumberGenerator.new()
var _landscape: SeedLandscape = null
var _foliage: ShaderMaterial = null
var _rock_material: StandardMaterial3D = null


func _ready() -> void:
	_rng.seed = 7331
	var parent := get_parent()
	if parent != null:
		_landscape = parent.get_node_or_null("Landscape") as SeedLandscape
	_foliage = ShaderMaterial.new()
	_foliage.shader = load("res://assets/shaders/foliage_sway.gdshader")
	_rock_material = StandardMaterial3D.new()
	_rock_material.albedo_color = Color(0.44, 0.43, 0.39, 1.0)
	_rock_material.roughness = 1.0
	_rock_material.vertex_color_use_as_albedo = true
	_spawn_grass()
	_spawn_flowers()
	_spawn_shrubs()
	_spawn_rocks()
	_spawn_trees()


func _ground(x: float, z: float) -> float:
	if _landscape != null:
		return _landscape.sample_height(x, z)
	return 0.0


func _slope(x: float, z: float) -> float:
	var e := 0.65
	var dx := _ground(x + e, z) - _ground(x - e, z)
	var dz := _ground(x, z + e) - _ground(x, z - e)
	return sqrt(dx * dx + dz * dz) / (2.0 * e)


func _ship_distance(x: float, z: float) -> float:
	return sqrt((x + 55.0) * (x + 55.0) + (z + 140.0) * (z + 140.0))


func _spawn_grass() -> void:
	var mesh := _make_grass_tuft()
	var xforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	var custom: Array[Color] = []
	for i in GRASS_COUNT:
		var r := 4.0 + pow(_rng.randf(), 0.82) * 88.0
		var ang := _rng.randf() * TAU
		var x := cos(ang) * r
		var z := sin(ang) * r
		var y := _ground(x, z)
		var s := _rng.randf_range(0.7, 1.45)
		var sy := _rng.randf_range(0.8, 1.5)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, sy, s))
		xforms.append(Transform3D(basis, Vector3(x, y - 0.02, z)))
		colours.append(Color(0.86, 0.95, 0.82).lerp(Color(1.08, 1.0, 0.72), _rng.randf() * 0.5))
		custom.append(Color(_rng.randf(), _rng.randf_range(0.7, 1.25), _rng.randf(), 1.0))
	_spawn_multimesh("GrassTufts", mesh, _foliage, xforms, [], custom, false, 0.0)


func _spawn_flowers() -> void:
	var mesh := _make_flower()
	var palette := [
		Color("#f2d46a").srgb_to_linear(),
		Color("#e8a88e").srgb_to_linear(),
		Color("#c8bce8").srgb_to_linear(),
		Color("#f2ecd8").srgb_to_linear(),
	]
	var xforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	var custom: Array[Color] = []
	for i in FLOWER_COUNT:
		var r := 8.0 + pow(_rng.randf(), 0.8) * 48.0
		var ang := _rng.randf() * TAU
		var x := cos(ang) * r
		var z := sin(ang) * r
		var y := _ground(x, z)
		var s := _rng.randf_range(0.7, 1.35)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s))
		xforms.append(Transform3D(basis, Vector3(x, y, z)))
		colours.append(palette[_rng.randi_range(0, palette.size() - 1)])
		custom.append(Color(_rng.randf(), _rng.randf_range(0.5, 0.9), _rng.randf(), 1.0))
	_spawn_multimesh("Wildflowers", mesh, _foliage, xforms, colours, custom, false, 0.0)


func _spawn_shrubs() -> void:
	var mesh := _make_shrub()
	var xforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	var custom: Array[Color] = []
	for i in SHRUB_COUNT:
		var r := SHRUB_CLEAR_RADIUS + pow(_rng.randf(), 0.8) * (PLAY_RADIUS - SHRUB_CLEAR_RADIUS)
		var ang := _rng.randf() * TAU
		var x := cos(ang) * r
		var z := sin(ang) * r
		if _slope(x, z) > 0.55:
			continue
		var y := _ground(x, z)
		var s := _rng.randf_range(0.65, 1.35)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.8, 1.15), s))
		xforms.append(Transform3D(basis, Vector3(x, y - 0.05, z)))
		colours.append(Color(0.82, 0.98, 0.80).lerp(Color(1.06, 0.98, 0.78), _rng.randf() * 0.5))
		custom.append(Color(_rng.randf(), _rng.randf_range(0.5, 0.9), _rng.randf(), 1.0))
	_spawn_multimesh("Shrubs", mesh, _foliage, xforms, [], custom, true, 0.0)


func _spawn_rocks() -> void:
	var mesh := _make_rock()
	var xforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	for i in ROCK_COUNT:
		var r := ROCK_CLEAR_RADIUS + pow(_rng.randf(), 0.8) * (PLAY_RADIUS - ROCK_CLEAR_RADIUS)
		var ang := _rng.randf() * TAU
		var x := cos(ang) * r
		var z := sin(ang) * r
		if _slope(x, z) > 0.7:
			continue
		var y := _ground(x, z)
		var s := _rng.randf_range(0.35, 1.35)
		if r > 70.0:
			s *= _rng.randf_range(1.0, 1.8)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.6, 1.0), s))
		xforms.append(Transform3D(basis, Vector3(x, y - s * 0.18, z)))
		colours.append(Color(0.88, 0.88, 0.86).lerp(Color(1.05, 1.0, 0.92), _rng.randf()))
	_spawn_multimesh("Boulders", mesh, _rock_material, xforms, colours, [], true, 0.0)


func _spawn_trees() -> void:
	var pine := _make_tree(true)
	var broad := _make_tree(false)
	var pine_x: Array[Transform3D] = []
	var pine_c: Array[Color] = []
	var pine_custom: Array[Color] = []
	var broad_x: Array[Transform3D] = []
	var broad_c: Array[Color] = []
	var broad_custom: Array[Color] = []
	var placed := 0
	var attempts := 0
	while placed < TREE_COUNT and attempts < TREE_COUNT * 8:
		attempts += 1
		var r := TREE_CLEAR_RADIUS + pow(_rng.randf(), 0.7) * (PLAY_RADIUS - TREE_CLEAR_RADIUS)
		var ang := _rng.randf() * TAU
		var x := cos(ang) * r
		var z := sin(ang) * r
		if _ship_distance(x, z) < SHIP_CLEAR_RADIUS:
			continue
		if _slope(x, z) > 0.5:
			continue
		var y := _ground(x, z)
		var s := _rng.randf_range(0.75, 1.15)
		if r > 70.0:
			s *= _rng.randf_range(0.9, 1.2)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.9, 1.15), s))
		var xf := Transform3D(basis, Vector3(x, y - 0.08, z))
		var tint := Color(0.84, 0.96, 0.82).lerp(Color(1.05, 1.0, 0.82), _rng.randf() * 0.6)
		var cust := Color(_rng.randf(), _rng.randf_range(0.35, 0.75), _rng.randf(), 1.0)
		if _rng.randf() < 0.56:
			pine_x.append(xf)
			pine_c.append(tint)
			pine_custom.append(cust)
		else:
			broad_x.append(xf)
			broad_c.append(tint)
			broad_custom.append(cust)
		placed += 1
	_spawn_multimesh("PineTrees", pine, _foliage, pine_x, [], pine_custom, true, 0.0)
	_spawn_multimesh("BroadleafTrees", broad, _foliage, broad_x, [], broad_custom, true, 0.0)


func _spawn_multimesh(
	node_name: String,
	mesh: Mesh,
	material: Material,
	xforms: Array[Transform3D],
	colours: Array[Color],
	custom: Array[Color],
	shadows: bool,
	fade: float
) -> void:
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colours.is_empty()
	mm.use_custom_data = not custom.is_empty()
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, colours[i])
		if mm.use_custom_data:
			mm.set_instance_custom_data(i, custom[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 160.0 if fade <= 0.0 else fade
	add_child(mmi)


# --- Procedural meshes -------------------------------------------------------

func _make_grass_tuft() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dark := Color("#263d16").srgb_to_linear()
	var light := Color("#4d6628").srgb_to_linear()
	for i in 5:
		var origin := Vector3(_rng.randf_range(-0.14, 0.14), 0.0, _rng.randf_range(-0.14, 0.14))
		var h := _rng.randf_range(0.24, 0.54)
		var r := _rng.randf_range(0.030, 0.055)
		var ang := _rng.randf() * TAU
		var lean := Vector3(cos(ang), 0.0, sin(ang)) * h * _rng.randf_range(0.12, 0.34)
		_add_blade(st, origin, h, lean, r, dark, light)
	return st.commit()


func _add_blade(st: SurfaceTool, origin: Vector3, height: float, lean: Vector3, radius: float, c0: Color, c1: Color) -> void:
	var tip := origin + Vector3(lean.x, height, lean.z)
	for i in 3:
		var a0 := TAU * float(i) / 3.0
		var a1 := TAU * float(i + 1) / 3.0
		var p0 := origin + Vector3(cos(a0) * radius, 0.0, sin(a0) * radius)
		var p1 := origin + Vector3(cos(a1) * radius, 0.0, sin(a1) * radius)
		_add_tri(st, p0, p1, tip, c0, c1, Vector3.UP, 0.7)


func _make_flower() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := Color("#3c5a2a").srgb_to_linear()
	var petal := Color("#f0e4b0").srgb_to_linear()
	var base := Vector3.ZERO
	var top := Vector3(0.0, 0.28, 0.0)
	_add_tri(st, base + Vector3(-0.02, 0, 0), base + Vector3(0.02, 0, 0), top, stem, stem, Vector3.UP, 0.28)
	var c := Vector3(0.0, 0.30, 0.0)
	var r := 0.075
	var p := [
		Vector3(r, 0, 0), Vector3(0, 0, r), Vector3(-r, 0, 0), Vector3(0, 0, -r),
		Vector3(0, r * 0.8, 0), Vector3(0, -r * 0.8, 0),
	]
	var faces := [
		[0, 1, 4], [1, 2, 4], [2, 3, 4], [3, 0, 4],
		[1, 0, 5], [2, 1, 5], [3, 2, 5], [0, 3, 5],
	]
	for f in faces:
		_add_flat_tri(st, c + p[f[0]], c + p[f[1]], c + p[f[2]], petal, petal, 0.3)
	return st.commit()


func _make_shrub() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var green := Color("#2c4420").srgb_to_linear()
	var light := Color("#425b2c").srgb_to_linear()
	_add_sphere(st, Vector3(0.0, 0.42, 0.0), 0.62, 7, 4, green, light, 1.2)
	_add_sphere(st, Vector3(-0.38, 0.32, 0.12), 0.44, 6, 3, green, light, 1.2)
	_add_sphere(st, Vector3(0.34, 0.30, -0.18), 0.40, 6, 3, green, light, 1.2)
	return st.commit()


func _make_rock() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dark := Color("#4c4a44").srgb_to_linear()
	var light := Color("#8a877c").srgb_to_linear()
	_add_sphere(st, Vector3(0.0, 0.55, 0.0), 1.0, 7, 4, dark, light, 1.4, 0.62)
	return st.commit()


func _make_tree(pine: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bark := Color("#3f2f22").srgb_to_linear()
	var bark_light := Color("#5c4530").srgb_to_linear()
	var leaf := Color("#2b4422").srgb_to_linear()
	var leaf_light := Color("#456030").srgb_to_linear()
	var height := 7.0
	if pine:
		_add_cylinder(st, 0.0, 2.9, 0.19, 0.10, 6, bark, bark_light)
		_add_cone(st, Vector3(0.0, 2.45, 0.0), 1.35, 2.7, 7, leaf, leaf_light)
		_add_cone(st, Vector3(0.0, 3.85, 0.0), 1.05, 2.3, 7, leaf, leaf_light)
		_add_cone(st, Vector3(0.0, 5.05, 0.0), 0.72, 1.9, 7, leaf, leaf_light)
		height = 7.0
	else:
		_add_cylinder(st, 0.0, 3.6, 0.22, 0.12, 6, bark, bark_light)
		_add_sphere(st, Vector3(0.0, 4.35, 0.0), 1.55, 7, 4, leaf, leaf_light, height)
		_add_sphere(st, Vector3(-0.85, 3.70, 0.20), 1.05, 6, 3, leaf, leaf_light, height)
		_add_sphere(st, Vector3(0.75, 3.85, -0.30), 1.15, 6, 3, leaf, leaf_light, height)
		_add_sphere(st, Vector3(0.10, 5.15, 0.15), 0.95, 6, 3, leaf, leaf_light, height)
		height = 6.2
	return st.commit()


# --- Mesh primitives ---------------------------------------------------------

func _add_cylinder(st: SurfaceTool, y0: float, y1: float, r0: float, r1: float, segs: int, c0: Color, c1: Color) -> void:
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var p0 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
		var p1 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
		var p2 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
		var p3 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
		_add_quad(st, p0, p1, p2, p3, c0, c1, 12.0)


func _add_cone(st: SurfaceTool, base: Vector3, radius: float, height: float, segs: int, c0: Color, c1: Color) -> void:
	var tip := base + Vector3(0.0, height, 0.0)
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var p0 := base + Vector3(cos(a0) * radius, 0.0, sin(a0) * radius)
		var p1 := base + Vector3(cos(a1) * radius, 0.0, sin(a1) * radius)
		_add_tri(st, p0, p1, tip, c0, c1, Vector3.UP, 7.0)


func _add_sphere(
	st: SurfaceTool,
	centre: Vector3,
	radius: float,
	segs: int,
	rings: int,
	c0: Color,
	c1: Color,
	uv_height: float,
	flatten: float = 1.0
) -> void:
	var verts: Array = []
	for ring in rings + 1:
		var phi := PI * float(ring) / float(rings)
		var row: Array[Vector3] = []
		for seg in segs:
			var theta := TAU * float(seg) / float(segs)
			var dir := Vector3(sin(phi) * cos(theta), cos(phi) * flatten, sin(phi) * sin(theta))
			var hash := _hash3(dir.x, dir.y, dir.z)
			var rr := radius * (0.82 + hash * 0.36)
			row.append(centre + dir * rr)
		verts.append(row)
	for ring in rings:
		var row0: Array = verts[ring]
		var row1: Array = verts[ring + 1]
		for seg in segs:
			var nseg := (seg + 1) % segs
			_add_quad(st, row0[seg], row1[seg], row1[nseg], row0[nseg], c0, c1, uv_height)


func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, c0: Color, c1: Color, uv_height: float) -> void:
	_add_flat_tri(st, a, b, c, c0, c1, uv_height)
	_add_flat_tri(st, a, c, d, c0, c1, uv_height)


func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, c0: Color, c1: Color, up: Vector3, uv_height: float) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.y < 0.0:
		normal = -normal
	# Foliage reads better when it catches overhead light instead of going dark
	# every time the sun climbs. Blend the face normal toward the supplied up.
	if up.length_squared() > 0.001:
		normal = normal.lerp(up.normalized(), 0.55).normalized()
	for p in [a, b, c]:
		var w := clampf(p.y / maxf(uv_height, 0.001), 0.0, 1.0)
		st.set_normal(normal)
		st.set_color(c0.lerp(c1, w))
		st.set_uv(Vector2(0.5, w))
		st.add_vertex(p)


func _add_flat_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, c0: Color, c1: Color, uv_height: float) -> void:
	var cross := (b - a).cross(c - a)
	if cross.length_squared() < 0.00000001:
		return
	var normal := cross.normalized()
	if normal.y < 0.0:
		normal = -normal
	var shade := c0.lerp(c1, 0.45)
	shade = shade.lerp(Color(1, 1, 1), _hash3(a.x, a.y, a.z) * 0.10)
	for p in [a, b, c]:
		var w := clampf(p.y / maxf(uv_height, 0.001), 0.0, 1.0)
		st.set_normal(normal)
		st.set_color(shade)
		st.set_uv(Vector2(0.5, w))
		st.add_vertex(p)


func _hash3(x: float, y: float, z: float) -> float:
	var v := sin(x * 127.1 + y * 311.7 + z * 74.7) * 43758.5453
	return v - floor(v)
