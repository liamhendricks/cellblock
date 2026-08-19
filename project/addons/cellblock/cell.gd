class_name Cell
extends Node3D

signal cell_configured(cell : Cell)

var cell_data : CellData
var cell_fully_configured : bool = false
var mutable_loading_complete : bool = false
var static_loading_complete : bool = false
var mutable_process_frames : int = 1
var static_process_frames : int = 10

@onready var object_loader : ObjectLoader = $ObjectLoader
var object_adder : ObjectAdder

func _enter_tree() -> void:
	request_ready()

func _ready() -> void:
	cell_fully_configured = false
	if object_loader != null:
		object_loader.init(self)
		if !object_loader.finished_loading.is_connected(_on_finished_loading_mutable):
			object_loader.finished_loading.connect(_on_finished_loading_mutable)
	if object_adder != null:
		object_adder.init(self)
		if !object_adder.finished_adding.is_connected(_on_finished_adding):
			object_adder.finished_adding.connect(_on_finished_adding)

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
func add_mutable(_mutable_node : Node3D, _key : String, _pos : Vector3) -> void:
	if !has_node(_key):
		return

	var node = get_node(_key)
	node.add_child(_mutable_node)
	_mutable_node.owner = node
	_mutable_node.global_position = _pos

func get_static_names() -> Array[String]:
	return ["statics"]

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
func load_cell(_data : Dictionary) -> void:
	object_loader.start()
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
			else:
				CellblockLogger.error(
					"failed to load mutable scene: %s (error %d)" % [obj["filename"], res]
				)

func _on_finished_loading_mutable() -> void:
	mutable_loading_complete = true
	if static_loading_complete:
		_cell_configured()

func _on_finished_adding() -> void:
	static_loading_complete = true
	if mutable_loading_complete:
		_cell_configured()

func _cell_configured() -> void:
	cell_fully_configured = true
	CellblockLogger.debug("cell configured: %s" % name)
	emit_signal("cell_configured", self)
