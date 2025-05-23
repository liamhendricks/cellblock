extends Node

# this is the node to do distance checks from, normally the player, or a camera
var origin_object : Node3D = null
var current_cell_key : Vector3i = Vector3.ZERO

var cell_registry : CellRegistry
var cell_data_tree : KDTree
var cell_loader : CellLoader

var to_add : Dictionary[Vector3i, Vector3i] = {}
var to_remove : Dictionary[Vector3i, Vector3i] = {}

signal entered_cell(old_cell : CellData, new_cell : CellData)
signal reparented_node(old_cell : CellData, new_cell : CellData, node : Node3D)

func _ready() -> void:
	set_process(false)

func set_origin_object(_origin_object : Node3D) -> void:
	origin_object = _origin_object

# entrypoint to start the cell_manager
func start(_origin_object : Node3D, _world : Node3D, _anchor : CellAnchor) -> void:
	origin_object = _origin_object
	cell_registry = _anchor.cell_registry
	cell_loader = get_loader(_world)
	cell_loader.configure(cell_registry)
	if origin_object == null || cell_registry == null:
		return

	cell_data_tree = KDTree.new()
	cell_data_tree.from_points(cell_registry.cells.keys())

	_anchor.anchor_exited.connect(_on_anchor_exited)
	set_process(true)

func get_loader(_world : Node3D) -> CellLoader:
	match(cell_registry.load_strategy):
		CellRegistry.LOAD_STRATEGY.IN_MEMORY_REMOVE: return CellLoaderInMemoryRemove.new(_world, cell_registry.max_cache_size)

	return null

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

	if len(nearest) == 0:
		return

	update_current_cell(nearest[0])

func update_current_cell(_nearest : Vector3i) -> void:
	if _nearest not in cell_registry.cells:
		return

	var new_current : CellData = cell_registry.cells[_nearest]
	if _nearest != current_cell_key:
		var current_cell : CellData = cell_registry.cells[current_cell_key]
		current_cell_key = _nearest
		enter_cell(current_cell, new_current)

func enter_cell(_old : CellData, _new : CellData) -> void:
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

func _on_anchor_exited():
	stop()
	to_add.clear()
	to_remove.clear()
	cell_loader.on_exit()
