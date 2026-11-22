class_name OreNode
extends Node3D
## Simple visible ore deposit. F2 treats it as infinite; depletion can come later.

@export var item_id: StringName = &"iron_ore"
@export var display_name: String = "Iron Ore"
@export var radius: float = 0.9


func _ready() -> void:
	_build_visual()


func _build_visual() -> void:
	var rock := MeshInstance3D.new()
	rock.name = "Rock"
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 1.2
	rock.mesh = sphere
	rock.position = Vector3(0.0, radius * 0.45, 0.0)
	rock.scale = Vector3(1.0, 0.55, 1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _ore_color()
	mat.roughness = 0.95
	rock.material_override = mat
	add_child(rock)

	var label := Label3D.new()
	label.name = "Label"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 22
	label.outline_size = 4
	label.text = display_name
	label.position = Vector3(0.0, 1.0, 0.0)
	add_child(label)


func _ore_color() -> Color:
	match String(item_id):
		"coal":
			return Color(0.14, 0.14, 0.16)
		"copper_ore":
			return Color(0.55, 0.36, 0.20)
		_:
			return Color(0.46, 0.26, 0.18)
