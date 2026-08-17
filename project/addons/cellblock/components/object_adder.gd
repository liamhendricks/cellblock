extends Node
class_name ObjectAdder

signal scene_added(node : Node, data : Dictionary)
signal finished_adding()

var pending_scenes = []
var cell : Cell
var statics : Node3D

func _ready():
	set_process(false)

func init(_cell : Cell):
	cell = _cell
	statics = cell.get_node("statics")

func add_pending_scene(node : Node):
	pending_scenes.append(node)

func start():
	set_process(true)

func _process(_delta: float) -> void:
	for i in range(cell.static_process_frames):
		if len(pending_scenes) == 0:
			set_process(false)
			CellblockLogger.debug("finished adding scenes")
			emit_signal("finished_adding")
			return

		var next_node = pending_scenes.pop_back()
		statics.add_child(next_node)
		emit_signal("scene_added")
