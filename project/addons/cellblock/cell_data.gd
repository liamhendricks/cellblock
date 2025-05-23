class_name CellData
extends Resource

@export var cell_name : String = "cell_0_0_0"
@export var coordinates : Vector3i = Vector3.ZERO
@export var world_position : Vector3 = Vector3.ZERO
@export var scene_path : String = "res://cells/" + cell_name + ".tscn"

var cell_save : CellSave

func get_scene_instance() -> Cell:
	var scene = load(scene_path)
	if scene:
		return scene.instantiate()

	return null

# virtual
func load_data(cell : Cell):
	pass

# virtual
func save_data(cell : Cell):
	pass
