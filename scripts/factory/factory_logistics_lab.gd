extends Node3D
## Standalone F2 lab: the F1 factory plus automatic road/truck logistics.

const MAIN_SCENE := preload("res://scenes/main.tscn")


func _ready() -> void:
	var main := MAIN_SCENE.instantiate()
	main.name = "Main"
	add_child(main)
	var demo := FactoryDemo.new()
	demo.name = "FactoryDemo"
	demo.enable_logistics = true
	main.add_child(demo)
