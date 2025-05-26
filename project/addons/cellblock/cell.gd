class_name Cell
extends Node3D

var cell_data : CellData

@onready var statics = $Statics
@onready var objects = $Objects
@onready var characters = $Characters

# check mutable object positions for movement to different cells
func get_mutable() -> Dictionary:
	var mutable = {
		"objects": objects.get_children(),
		"characters": characters.get_children(),
	}

	return mutable

# add mutable object to specific parent
func add_mutable(_node : Node3D, _key : String):
	match(_key):
		"objects": 
			objects.add_node(_node)
			_node.owner = objects
		"characters": 
			characters.add_node(_node)
			_node.owner = characters

# construct a keyed save dictionary of all mutable cell children
func save_cell(_key : String) -> Dictionary:
	var save_data = {
		"key": _key,
		"objects": [],
		"characters": []
	}

	for obj in objects.get_children():
		if obj.has_method("on_save"):
			save_data["objects"].append(obj.on_save())

	for char in characters.get_children():
		if char.has_method("on_save"):
			save_data["characters"].append(char.on_save())

	return save_data

# delete old mutable cell children and reconstruct them with saved data
func load_cell(_data : Dictionary):
	if "objects" in _data && len(_data["objects"]) > 0:
		for obj in objects.get_children():
			obj.queue_free()

		for o in _data["objects"]:
			var new_object = load(o["filename"]).instantiate()
			objects.add_child(new_object)
			if new_object.has_method("on_load"):
				new_object.on_load(o)

	if "characters" in _data && len(_data["characters"]) > 0:
		for char in characters.get_children():
			char.queue_free()

		for c in _data["characters"]:
			var new_character = load(c["filename"]).instantiate()
			characters.add_child(new_character)
			if new_character.has_method("on_load"):
				new_character.on_load(c)
