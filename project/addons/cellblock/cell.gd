class_name Cell
extends Node3D

signal cell_configured(cell : Cell)

var cell_data : CellData
var cell_fully_configured : bool = false
var process_frames : int = 1

@onready var object_loader : ObjectLoader = $ObjectLoader

func _enter_tree() -> void:
	visible = false
	request_ready()

func _ready():
	cell_fully_configured = false
	object_loader.init(self)
	if !object_loader.finished_loading.is_connected(_on_finished_loading_mutable):
		object_loader.finished_loading.connect(_on_finished_loading_mutable)
	call_deferred("set_visible", true)

# define the names of the cell children which are the parents of each type of mutable node
func get_mutable_names() -> Array[String]:
	return ["objects", "characters", "doors"]

# check mutable object positions for movement to different cells
func get_mutable() -> Dictionary:
	var mutable = {}
	var mut = get_mutable_names()
	for m in mut:
		if !has_node(m):
			continue
		var mutable_node = get_node(m)
		mutable[m] = mutable_node.get_children()

	return mutable

# add mutable object to specific parent
func add_mutable(_mutable_node : Node3D, _key : String, _pos : Vector3):
	if !has_node(_key):
		return

	var node = get_node(_key)
	node.add_child(_mutable_node)
	_mutable_node.owner = node
	_mutable_node.global_position = _pos

# construct a keyed save dictionary of all current mutable cell children
func save_cell(_key : String) -> Dictionary:
	var save_data = {
		"key": _key,
	}

	var mutable_names = get_mutable_names()
	for m in mutable_names:
		var mutable_root = get_node(m)
		var k = m.to_lower()
		save_data[k] = []
		for child in mutable_root.get_children():
			if child.has_method("on_save"):
				save_data[k].append(child.on_save())

	return save_data

# NOTE: the loaders delete the mutable nodes before we add the cell to the scene tree. that is done
# so that we can batch load all the mutable nodes, and add them to the tree over a few frames for
# performance reasons

# load mutable cell objects from save
func load_cell(_data : Dictionary):
	if len(_data.keys()) == 0:
		return

	var mutable_names = get_mutable_names()
	for m in mutable_names:
		var mutable_root = get_node(m)
		if m not in _data:
			continue

		for obj in _data[m]:
			var res = ResourceLoader.load_threaded_request(obj["filename"])
			if res == OK:
				var load_data = {
					"fn": obj["filename"],
					"progress": [0.0],
					"done": false,
					"scene": null,
					"data": obj,
					"parent": mutable_root,
				}
				object_loader.pending_scenes.append(load_data)

	object_loader.start()

func _on_finished_loading_mutable():
	CellblockLogger.debug("cell configured: %s" % name)
	cell_fully_configured = true
	emit_signal("cell_configured", self)
