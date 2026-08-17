extends RigidBody3D
class_name MutableObject

var object_key : String

func on_save() -> Dictionary:
	return {
		"filename": get_scene_file_path(),
		"pos_x": transform.origin.x,
		"pos_y": transform.origin.y,
		"pos_z": transform.origin.z,
	}

func on_load(data : Dictionary):
	transform.origin.x = data["pos_x"]
	transform.origin.y = data["pos_y"]
	transform.origin.z = data["pos_z"]
