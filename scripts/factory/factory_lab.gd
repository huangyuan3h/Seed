extends Node3D
## Standalone F1 lab scene. Instances the normal main scene, then adds the
## factory demo as a child so the art/landscape stream can keep editing
## main.tscn in parallel.

const MAIN_SCENE := preload("res://scenes/main.tscn")


func _ready() -> void:
	var main := MAIN_SCENE.instantiate()
	main.name = "Main"
	add_child(main)
	var demo := FactoryDemo.new()
	demo.name = "FactoryDemo"
	main.add_child(demo)
