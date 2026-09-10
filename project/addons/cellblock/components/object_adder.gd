extends Node
class_name ObjectAdder

signal scene_added(node : Node)
signal finished_adding()

var pending_scenes : Array = []
var cell : Cell
var statics : Node3D

func _ready() -> void:
	set_process(false)

func init(_cell : Cell) -> void:
	cell = _cell
	pending_scenes = cell.pending_scenes
	statics = cell.get_node("statics")

func start() -> void:
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
		emit_signal("scene_added", next_node)
