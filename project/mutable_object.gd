extends RigidBody3D
class_name MutableObject

var object_key : String

func on_save() -> Dictionary:
	return {
		"filename": get_scene_file_path(),
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"pos_z": global_position.z,
	}

func on_load(data : Dictionary):
	global_position.x = data["pos_x"]
	global_position.y = data["pos_y"]
	global_position.z = data["pos_z"]
