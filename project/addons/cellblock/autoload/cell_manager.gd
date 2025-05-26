extends Node

# the origin object has a new nearest cell
signal entered_cell(old_cell : CellData, new_cell : CellData)

# some mutable object got closer to a different cell, and now belongs there
signal reparented_node(old_cell : CellData, new_cell : CellData, node_name : String)

# this is the node to do distance checks from, normally the player, or a camera
var origin_object : Node3D = null
var current_cell_key : Vector3i = Vector3.ZERO

var cell_registry : CellRegistry
var cell_data_tree : KDTree
var cell_loader : CellLoader

var to_add : Dictionary[Vector3i, Vector3i] = {}
var to_remove : Dictionary[Vector3i, Vector3i] = {}

func _ready() -> void:
	set_process(false)

func set_origin_object(_origin_object : Node3D) -> void:
	origin_object = _origin_object

# entrypoint to start the cell_manager
func start(_origin_object : Node3D, _world : Node3D, _anchor : CellAnchor) -> void:
	origin_object = _origin_object
	cell_registry = _anchor.cell_registry
	cell_loader = _get_loader(_world)
	if  cell_registry == null || cell_registry.cell_save == null || origin_object == null || cell_loader == null:
		push_error("cell_manager not started correctly, please review the docs if any below are null")
		push_error("cell_registry: %s" % cell_registry)
		push_error("cell_save: %s" % cell_registry.cell_save)
		push_error("origin_object: %s" % origin_object)
		push_error("cell_loader: %s" % cell_loader)
		return

	cell_loader.configure(cell_registry)

	cell_data_tree = KDTree.new()
	cell_data_tree.from_points(cell_registry.cells.keys())

	_anchor.anchor_exited.connect(_on_anchor_exited)
	set_process(true)

func _get_loader(_world : Node3D) -> CellLoader:
	match(cell_registry.load_strategy):
		CellRegistry.LOAD_STRATEGY.IN_MEMORY_REMOVE: return CellLoaderInMemoryRemove.new(_world, cell_registry.max_cache_size)

	return null

func save_cells():
	cell_loader.save_cells(cell_registry)

func stop() -> void:
	set_process(false)

func _process(_delta) -> void:
	if origin_object == null:
		return

	var coords := world_to_cell_space(origin_object.global_position, cell_registry.cell_size)
	var nearest := cell_data_tree.radius_search(coords, cell_registry.max_dist)

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

	# some mutable objects may have moved out of range of the current cell
	var cell : Cell = cell_loader.active_cells[last]
	var mutable_objects := cell.get_mutable()
	try_reparent_mutable(mutable_objects, last)

	cell_loader.remove(cell_data)

# enqueue keys of cells to add and remove
func enqueue(active: Array, nearest: Array) -> void:
	for k in active:
		if !nearest.has(k) && k not in to_remove:
			to_remove[k] = k

	for k in nearest:
		if !active.has(k) && k not in to_add:
			to_add[k] = k

func try_reparent_mutable(_mutable_data : Dictionary, _key : Vector3i):
	if len(_mutable_data.keys()) == 0:
		return

	var cell_data := cell_registry.cells[_key]
	for k in _mutable_data.keys():
		for object in _mutable_data[k]:
			var actual = world_to_cell_space(object.global_position, cell_registry.cell_size)

			# distance check
			if actual.distance_squared_to(_key) < cell_data.max_mutable_travel_dist_sq:
				continue

			if actual in cell_registry.cells && actual != _key:
				reparent_node(_key, actual, object, k)

func reparent_node(_from : Vector3i, _to : Vector3i, _node : Node3D, _data_key : String):
	if _to not in cell_registry.cells:
		return

	var old := cell_registry.cells[_from]
	var new := cell_registry.cells[_to]

	var parent = _node.get_parent()
	parent.remove_child(_node)

	old.save_data = cell_loader.active_cells[_from].save_cell("%v" % _from)

	# if the new cell is already loaded, just add it. the new node will be included in the save if
	# the cell gets removed, or if saved while active
	if _to in cell_loader.active_cells:
		var new_cell := cell_loader.active_cells[_to]
		new_cell.add_mutable(_node, _data_key)
	else:
		if _node.has_method("on_save"):
			new.save_data[_data_key].append(_node.on_save())

		_node.queue_free()

	print("reparented node: ", _node.name)
	emit_signal("reparented_node", old, new, _node.name)

func _on_anchor_exited():
	stop()
	to_add.clear()
	to_remove.clear()
	cell_loader.on_exit()
