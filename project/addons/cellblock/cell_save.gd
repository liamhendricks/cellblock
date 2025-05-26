class_name CellSave
extends Resource

@export var save_file_name : String = "user://savegame.save"

func write_save(data : Dictionary):
	var save_file = FileAccess.open(save_file_name, FileAccess.WRITE)
	for k in data.keys():
		var json_string = JSON.stringify(data[k])
		save_file.store_line(json_string)

func load_save() -> Dictionary:
	var data = {}
	if not FileAccess.file_exists(save_file_name):
		return data

	var save_file = FileAccess.open(save_file_name, FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()
		var json = JSON.new()

		var parse_result = json.parse(json_string)
		if not parse_result == OK || json.data == null || "key" not in json.data:
			continue

		data[json.data["key"]] = json.data

	return data
