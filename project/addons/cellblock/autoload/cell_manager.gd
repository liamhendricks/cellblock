extends Node

# this is the node to do distance checks from, normally the player, or a camera
var origin_object : Node3D = null
var current_cell : Cell
var closest_cell_dist : float

# this is the node that cells are parented to
var world : Node3D
var active_cells : Dictionary[String, Cell] = {}

var cell_registry : CellRegistry
var cell_data : CellStack
var cell_cache : LruCellCache

signal entered_cell(old_cell : Cell, new_cell : Cell)
signal reparented_node(old_cell : Cell, new_cell : Cell, node : Node3D)

func _ready() -> void:
	set_process(false)

func set_origin_object(_origin_object : Node3D) -> void:
	origin_object = _origin_object

# entrypoint to start the cell_manager
func start(_origin_object : Node3D, _registry : CellRegistry) -> void:
	origin_object = _origin_object
	cell_registry = _registry
	if origin_object == null || cell_registry == null:
		return

	cell_cache = LruCellCache.new()
	cell_data = CellStack.new()
	for k in cell_registry.cells.keys():
		var cd = cell_registry.cells[k]
		cell_data._push(cd)

func stop() -> void:
	set_process(false)

func _process(_delta) -> void:
	if origin_object == null:
		return

	var pos = origin_object.global_position
	for i in range(cell_registry.num_iterations):
		cell_data._work(pos)

func update_current_cell(_cell : Cell, _dist : float) -> void:
	if _dist < closest_cell_dist and current_cell.cell_data.cell_name != _cell.cell_data.cell_name:
		enter_cell(current_cell, _cell, _dist)

func enter_cell(_old : Cell, _new : Cell, _dist : float) -> void:
	closest_cell_dist = _dist
	current_cell = _new
	emit_signal("entered_cell", _old, _new)

func coordinate_to_world_space(_coords : Vector3) -> Vector3:
	return Vector3.ZERO
