extends Node
class_name ObjectLoader

signal scene_loaded(node : Node, data : Dictionary)
signal finished_loading()

var pending_scenes = []
var cell : Cell

func _ready():
	set_process(false)

func init(_cell : Cell):
	cell = _cell

func add_pending_scene(data : Dictionary):
	pending_scenes.append(data)

func start():
	set_process(true)

func _process(_delta: float) -> void:
	if len(pending_scenes) == 0:
		set_process(false)
		CellblockLogger.debug("finished loading mutable scenes")
		emit_signal("finished_loading")
		return

	var next = pending_scenes.back()
	var load_status = ResourceLoader.load_threaded_get_status(next["fn"], next["progress"])

	if next["done"]:
		var scene = next["scene"]
		var new_object = scene.instantiate()
		var data = next["data"]
		call_deferred("_finish_loading", new_object, next, data, next["parent"])
		pending_scenes.erase(next)
		return

	match load_status:
		0,2: # ERROR
			set_process(false)
			pending_scenes.clear()
			return
		3: # finished
			var scene = ResourceLoader.load_threaded_get(next["fn"])
			next["scene"] = scene
			next["done"] = true
			return

func _finish_loading(new_instance : Node, data : Dictionary, node_data : Dictionary, parent : Node) -> void:
	parent.add_child(new_instance)
	if new_instance.has_method("update_current_cell"):
		new_instance.update_current_cell(cell)
	if new_instance.has_method("on_load"):
		new_instance.call_deferred("on_load", node_data)
	if new_instance.has_method("get_mutable_node_name"):
		var nn = new_instance.get_mutable_node_name()
		if nn != "":
			new_instance.name = nn

	CellblockLogger.debug("loaded mutable instance: %s" % new_instance.name)
	emit_signal("scene_loaded", new_instance, data)
