extends Node

# the origin object has a new nearest cell
signal entered_cell(old_cell : CellData, new_cell : CellData)

# some mutable object got closer to a different cell, and now belongs there
signal reparented_node(old_cell : CellData, new_cell : CellData, node_name : String)

signal cell_added(cell_data : CellData)
signal cell_removed(cell_data : CellData)

# this is the node to do distance checks from, normally the player, or a camera
var origin_object : Node3D = null
var current_cell_key : Vector3i = Vector3.ZERO
var current_cell_coords : Vector3i = Vector3.ZERO

var cell_registries : Array[CellRegistry]
var cell_loaders : Array[CellLoader]
var current_registry_index : int = 0
var cell_save : CellSave

var to_add : Dictionary[Vector3i, int] = {}
var to_remove : Dictionary[Vector3i, int] = {}

func _ready() -> void:
	set_process(false)

func set_origin_object(_origin_object : Node3D) -> void:
	origin_object = _origin_object

# entrypoint to start the cell_manager
func start(_origin_object : Node3D, _world : Node3D, _anchor : CellAnchor) -> void:
	cell_loaders.clear()
	cell_registries.clear()
	origin_object = _origin_object
	cell_registries = _anchor.cell_registries

	if _anchor.cell_save == null:
		push_error("cell_save is null")
		return

	cell_save = _anchor.cell_save

	var dedup = {}
	for registry in cell_registries:
		var loader = _get_loader(_world, registry)
		cell_loaders.append(loader)
		if  registry == null || origin_object == null || loader == null:
			push_error("cell_manager not started correctly, please review the docs if any below are null")
			push_error("cell_registry: %s" % registry)
			push_error("origin_object: %s" % origin_object)
			push_error("cell_loader: %s" % loader)
			return

		loader.configure(registry, cell_save)
		loader.cell_added.connect(_on_cell_added)
		loader.cell_removed.connect(_on_cell_removed)
		if registry.resource_path in dedup:
			push_error("duplicate cell_registry detected: %s" % registry.resource_path)
			return

		dedup[registry.resource_path] = true

	dedup.clear()

	if len(cell_registries) != len(cell_loaders):
		push_error("mismatch in number of loaders to registries")
		return

	_anchor.anchor_exited.connect(_on_anchor_exited)

	set_process(true)

func _get_loader(_world : Node3D, _registry : CellRegistry) -> CellLoader:
	match(_registry.load_strategy):
		CellRegistry.LOAD_STRATEGY.IN_MEMORY_REMOVE: return CellLoaderInMemoryRemove.new(_world, _registry.max_cache_size)

	return null

func save_cells():
	var count = 0
	var save_data = {}
	for cell_loader : CellLoader in cell_loaders:
		var registry := cell_registries[count]
		var active_cells := cell_loader.get_active_cells()
		count += 1
		save_data[registry.resource_path] = {}
		for k in registry.cells.keys():
			var cell_data := registry.cells[k]
			var key = "%v" % k
			save_data[registry.resource_path][key] = cell_data.save_data

		for k in active_cells.keys():
			var cell := active_cells[k]
			var key = "%v" % k
			cell.cell_data.save_data = cell.save_cell(key)
			save_data[registry.resource_path][key] = cell.cell_data.save_data

	cell_save.write_save(save_data)

func stop() -> void:
	set_process(false)

func _process(_delta) -> void:
	if origin_object == null:
		return

	var cell_registry = cell_registries[current_registry_index]
	var cell_loader = cell_loaders[current_registry_index]
	current_cell_coords = world_to_cell_space(origin_object.global_position, cell_registry.cell_size)
	var nearest = get_nearest(current_cell_coords, cell_registry.radius, cell_registry.min_y_depth, cell_registry.max_y_depth)

	enqueue(cell_loader.active_cells.keys(), nearest)

	if len(to_add.keys()) > 0:
		print("to_add: ", len(to_add.keys()))

	if len(to_remove.keys()) > 0:
		print("to_remove: ", len(to_remove.keys()))

	dequeue_active()
	dequeue_inactive()
	update_current_cell(current_cell_coords)

	current_registry_index += 1
	if current_registry_index > len(cell_registries) - 1:
		current_registry_index = 0

func update_current_cell(_nearest : Vector3i) -> void:
	var cell_registry = cell_registries[current_registry_index]
	if _nearest not in cell_registry.cells:
		return

	if _nearest != current_cell_key:
		var new_current : CellData = cell_registry.cells[_nearest]
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

	var lk = to_add.keys().back()
	var last = to_add[lk]
	var cell_registry := cell_registries[last]
	var cell_loader := cell_loaders[last]
	var cell_data : CellData = cell_registry.cells[lk]
	to_add.erase(lk)

	cell_loader.add(cell_data)

func dequeue_inactive():
	if len(to_remove.keys()) == 0:
		return

	var lk = to_remove.keys().back()
	var last = to_remove[lk]
	var cell_registry := cell_registries[last]
	var cell_loader := cell_loaders[last]
	var cell_data : CellData = cell_registry.cells[lk]
	to_remove.erase(lk)

	# mutable objects may have moved out of range of their current cell
	var cell : Cell = cell_loader.active_cells[lk]
	var mutable_objects := cell.get_mutable()
	try_reparent_mutable(mutable_objects, lk, last)

	cell_loader.remove(cell_data)

# enqueue keys of cells to add and remove
func enqueue(active: Array, nearest: Array) -> void:
	for k in active:
		if !nearest.has(k) && k not in to_remove:
			to_remove[k] = current_registry_index

	for k in nearest:
		if !active.has(k) && k not in to_add:
			to_add[k] = current_registry_index

func get_nearest(_coords : Vector3i, _radius : int = 2, _min_y_depth : int = _radius, _max_y_depth : int = _radius) -> Array:
	var nearest = []

	var cell_registry := cell_registries[current_registry_index]

	for x in range(-_radius, _radius + 1):
		for y in range(_min_y_depth, _max_y_depth):
			for z in range(-_radius, _radius + 1):
				var key = Vector3i(_coords.x + x, _coords.y + y, _coords.z + z)
				if key in cell_registry.cells:
					nearest.append(key)

	return nearest

func try_reparent_mutable(_mutable_data : Dictionary, _key : Vector3i, _loader_idx : int):
	if len(_mutable_data.keys()) == 0:
		return

	var cell_registry := cell_registries[_loader_idx]

	var cell_data := cell_registry.cells[_key]
	for k in _mutable_data.keys():
		for object in _mutable_data[k]:
			# if the object clamps to a new cell that exists, parent it there
			var actual = world_to_cell_space(object.global_position, cell_registry.cell_size)
			if actual != _key:
				reparent_node(_key, actual, object, k, _loader_idx)

func reparent_node(_from : Vector3i, _to : Vector3i, _node : Node3D, _data_key : String, _loader_idx : int):
	var cell_registry := cell_registries[_loader_idx]
	var cell_loader := cell_loaders[_loader_idx]
	if _to not in cell_registry.cells:
		return

	var old := cell_registry.cells[_from]
	var new := cell_registry.cells[_to]

	var tmp_pos = _node.global_position
	var resave = _node.on_save()
	var parent = _node.get_parent()
	parent.remove_child(_node)

	old.save_data = cell_loader.active_cells[_from].save_cell("%v" % _from)

	# if the new cell is already loaded, just add it. the new node will be included in the save if
	# the cell gets removed, or if saved while active
	if _to in cell_loader.active_cells:
		var new_cell := cell_loader.active_cells[_to]
		new_cell.add_mutable(_node, _data_key, tmp_pos)
	else:
		if _node.has_method("on_save") && len(new.save_data.keys()) > 0:
			new.save_data[_data_key].append(resave)

		_node.queue_free()

	print("reparented node: ", _node.name)
	emit_signal("reparented_node", old, new, _node.name)

func _on_anchor_exited():
	stop()
	to_add.clear()
	to_remove.clear()
	for loader in cell_loaders:
		loader.on_exit()

func _on_cell_added(_cell_data : CellData):
	emit_signal("cell_added", _cell_data)

func _on_cell_removed(_cell_data : CellData):
	emit_signal("cell_removed", _cell_data)
