extends Node

# this is the node to do distance checks from, normally the player, or a camera
var origin_object : Node3D = null
var current_cell : Cell
var closest_cell_dist : float

var cell_registry : CellRegistry
var cell_data_tree : KDTree
var cell_loader : CellLoader

var to_add : Dictionary[Vector3i, CellData] = {}
var to_remove : Dictionary[Vector3i, CellData] = {}

signal entered_cell(old_cell : Cell, new_cell : Cell)
signal reparented_node(old_cell : Cell, new_cell : Cell, node : Node3D)

func _ready() -> void:
	set_process(false)

func set_origin_object(_origin_object : Node3D) -> void:
	origin_object = _origin_object

# entrypoint to start the cell_manager
func start(_origin_object : Node3D, _world : Node3D, _registry : CellRegistry) -> void:
	origin_object = _origin_object
	cell_loader = CellLoader.new(_world, cell_registry.max_cache_size)
	cell_registry = _registry
	if origin_object == null || cell_registry == null:
		return

	cell_data_tree = KDTree.new()
	cell_data_tree.from_points(cell_registry.cells.keys())

	set_process(true)

func stop() -> void:
	set_process(false)

func _process(_delta) -> void:
	if origin_object == null:
		return

	var coords := world_to_cell_space(origin_object.global_position, cell_registry.cell_size)
	var nearest := cell_data_tree.find_nearest(coords, cell_registry.max_loaded_cells, cell_registry.max_dist)

	enqueue(cell_loader.active_cells.keys(), nearest)

	dequeue_active()
	dequeue_inactive()

func update_current_cell(_cell : Cell, _dist : float) -> void:
	if _dist < closest_cell_dist and current_cell.cell_data.cell_name != _cell.cell_data.cell_name:
		enter_cell(current_cell, _cell, _dist)

func enter_cell(_old : Cell, _new : Cell, _dist : float) -> void:
	closest_cell_dist = _dist
	current_cell = _new
	emit_signal("entered_cell", _old, _new)

func cell_to_world_space(_coords : Vector3i, _cell_size : int) -> Vector3:
	return Vector3(
		_coords.x * _cell_size,
		_coords.y * _cell_size,
		_coords.z * _cell_size
	)

func world_to_cell_space(_pos : Vector3, _cell_size : int) -> Vector3i:
	return Vector3i(
		floor(_pos.x / _cell_size),
		floor(_pos.y / _cell_size),
		floor(_pos.z / _cell_size)
	)

func dequeue_active():
	if len(to_add.keys()) == 0:
		return

	var last = to_add.keys().back()
	var cell_data : CellData = cell_registry.cells[last]
	to_add.erase(last)

	cell_loader.add(cell_data)

func dequeue_inactive():
	if len(to_remove.keys()) == 0:
		return

	var last = to_remove.keys().back()
	var cell_data : CellData = cell_registry.cells[last]
	to_remove.erase(last)

	cell_loader.remove(cell_data)

# enqueue keys of cells to add and remove
func enqueue(active: Array, nearest: Array) -> void:
	for k in active:
		if !nearest.has(k) && k not in to_remove:
			to_remove[k] = k

	for k in nearest:
		if !active.has(k) && k not in to_add:
			to_add[k] = k
