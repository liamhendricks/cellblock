class_name CellData
extends Resource

@export var cell_name : String = "cell_0_0_0"
@export var coordinates : Vector3i = Vector3.ZERO
@export var world_position : Vector3 = Vector3.ZERO
@export var scene_path : String = "res://cells/" + cell_name + ".tscn"

# runtime storage of cell save data
var save_data : Dictionary

func get_scene_instance() -> Cell:
	var scene = load(scene_path)
	if scene:
		return scene.instantiate()

	return null
