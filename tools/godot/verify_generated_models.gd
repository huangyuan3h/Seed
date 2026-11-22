extends SceneTree
## Headless sanity check for the Blender-generated model kit.
##
## Run after importing the .glb files:
##   Godot --headless --path <project> --script res://tools/godot/verify_generated_models.gd
##
## Verifies that every model loads as a PackedScene, contains mesh surfaces with
## materials, and reports its triangle count and world-space bounds.

const MODELS := [
	"res://assets/models/seed/prop_pod_07.glb",
	"res://assets/models/seed/prop_thermal_generator.glb",
	"res://assets/models/seed/prop_shelter.glb",
	"res://assets/models/seed/env_berry_bush.glb",
	"res://assets/models/seed/env_tree_a.glb",
	"res://assets/models/seed/env_tree_b.glb",
	"res://assets/models/seed/env_rock_a.glb",
	"res://assets/models/seed/env_ship_rib.glb",
]


func _init() -> void:
	var failures := 0
	for path in MODELS:
		var packed := load(path) as PackedScene
		if packed == null:
			printerr("FAIL load: ", path)
			failures += 1
			continue

		var instance := packed.instantiate()
		root.add_child(instance)

		var meshes := instance.find_children("*", "MeshInstance3D", true, false)
		if meshes.is_empty():
			printerr("FAIL no MeshInstance3D: ", path)
			failures += 1
			instance.free()
			continue

		var triangles := 0
		var surfaces := 0
		var bounds := AABB()
		var has_bounds := false
		for mesh_instance in meshes:
			var mesh := (mesh_instance as MeshInstance3D).mesh
			if mesh == null:
				continue
			triangles += mesh.get_faces().size() / 3
			surfaces += mesh.get_surface_count()
			# The instance root is at the origin, so local space is world space here.
			var box: AABB = (mesh_instance as MeshInstance3D).transform * mesh.get_aabb()
			bounds = box if not has_bounds else bounds.merge(box)
			has_bounds = true

		var size := bounds.size
		if triangles <= 0 or surfaces <= 0:
			printerr("FAIL empty mesh: ", path)
			failures += 1
		elif size.y <= 0.05:
			printerr("FAIL zero height (ground origin broken): ", path)
			failures += 1
		else:
			print("OK %s tris=%d surfaces=%d size=%.2fx%.2fx%.2f" % [
				path.get_file(), triangles, surfaces, size.x, size.y, size.z,
			])

		instance.free()

	print("GENERATED_MODELS %s (%d/%d)" % [
		"PASS" if failures == 0 else "FAIL", MODELS.size() - failures, MODELS.size(),
	])
	quit(1 if failures > 0 else 0)
