class_name CellData
extends Resource

@export var cell_name : String = "cell_0_0_0"
@export var coordinates : Vector3i = Vector3.ZERO
@export var world_position : Vector3 = Vector3.ZERO
@export var scene_path : String = "res://cells/" + cell_name + ".tscn"

var cell_save : Resource

func work(_pos : Vector3):
	pass

func _load_scene():
	var scene = load(scene_path)
	if scene:
		var cell = scene.instantiate()
