extends RefCounted
class_name CellProcessor

# the origin object has a new nearest cell
signal entered_cell(old_cell : CellData, new_cell : CellData)

# some mutable object got closer to a different cell, and now belongs there
signal reparented_node(old_cell : CellData, new_cell : CellData, node_name : String)

signal cell_added(cell_data : CellData)
signal cell_removed(cell_data : CellData)

var cell_registry : CellRegistry
var cell_loader : CellLoader
var nearest : Array[Vector3i]
var radius : Vector3i

var current_cell_key : Vector3i = Vector3.ZERO
var current_cell_coords : Vector3i = Vector3.ZERO
var search_coords : Vector3i = Vector3.ZERO
var iterations_per_frame := 10
var done_processing : bool = false

var count : int = 0

var to_add : Dictionary[Vector3i, bool] = {}
var to_remove : Dictionary[Vector3i, bool] = {}

func _init(_cell_registry : CellRegistry, _cell_loader : CellLoader) -> void:
	cell_registry = _cell_registry
	cell_loader = _cell_loader
	cell_loader.cell_removed.connect(_on_cell_removed)
	cell_loader.cell_added.connect(_on_cell_added)
	radius = Vector3i(-cell_registry.radius, -cell_registry.radius, -cell_registry.radius)

func _work(origin_object : Node3D):
	get_nearest(cell_registry.radius)

	if done_processing:
		enqueue(cell_loader.active_cells.keys(), nearest)
		nearest.clear()
		current_cell_coords = CellManager.world_to_cell_space(origin_object.global_position, cell_registry.cell_size)
		search_coords = current_cell_coords + radius
		done_processing = false

	dequeue_active()
	dequeue_inactive()
	update_current_cell(current_cell_coords)

# work through the entire radius search over the course of a few frames
func get_nearest(_radius : int = 2) -> void:
	done_processing = false
	var count := 0
	var min := (current_cell_coords + radius)
	var max := _radius + 1

	while search_coords.x < max + current_cell_coords.x:
		while search_coords.y < max + current_cell_coords.y:
			while search_coords.z < max + current_cell_coords.z:
				if search_coords in cell_registry.cells:
					nearest.append(search_coords)
				search_coords.z += 1
				count += 1

				if count >= iterations_per_frame:
					return

			search_coords.z = min.z
			search_coords.y += 1
		search_coords.y = min.y
		search_coords.x += 1
		if search_coords.x >= max + current_cell_coords.x:
			done_processing = true

# enqueue keys of cells to add and remove
func enqueue(active: Array, nearest: Array) -> void:
	for k in active:
		if !nearest.has(k) && k not in to_remove:
			to_remove[k] = true

	for k in nearest:
		if !active.has(k) && k not in to_add:
			to_add[k] = true

func dequeue_active():
	if len(to_add.keys()) == 0:
		return

	var lk = to_add.keys().back()
	var last = to_add[lk]
	var cell_data : CellData = cell_registry.cells[lk]

	cell_loader.add(cell_data)

func dequeue_inactive():
	if len(to_remove.keys()) == 0:
		return

	var lk = to_remove.keys().back()
	var cell_data : CellData = cell_registry.cells[lk]

	# mutable objects may have moved out of range of their current cell
	var cell : Cell = cell_loader.active_cells[lk]
	var mutable_objects := cell.get_mutable()
	try_reparent_mutable(mutable_objects, lk)

	cell_loader.remove(cell_data)

func update_current_cell(_nearest : Vector3i) -> void:
	if _nearest not in cell_registry.cells:
		return

	if _nearest != current_cell_key:
		var new_current : CellData = cell_registry.cells[_nearest]
		var current_cell : CellData = cell_registry.cells[current_cell_key]
		current_cell_key = _nearest
		enter_cell(current_cell, new_current)

func enter_cell(_old : CellData, _new : CellData) -> void:
	emit_signal("entered_cell", _old, _new)

func try_reparent_mutable(_mutable_data : Dictionary, _key : Vector3i):
	if len(_mutable_data.keys()) == 0:
		return

	var cell_data := cell_registry.cells[_key]
	for k in _mutable_data.keys():
		for object in _mutable_data[k]:
			# if the object clamps to a new cell that exists, parent it there
			var actual = CellManager.world_to_cell_space(object.global_position, cell_registry.cell_size)
			if actual != _key:
				reparent_node(_key, actual, object, k)

func reparent_node(_from : Vector3i, _to : Vector3i, _node : Node3D, _data_key : String):
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

	emit_signal("reparented_node", old, new, _node.name)

func get_cell_save_data() -> Dictionary:
	var count = 0
	var save_data = {}
	var active_cells := cell_loader.get_active_cells()
	count += 1
	save_data[cell_registry.resource_path] = {}
	for k in cell_registry.cells.keys():
		var cell_data := cell_registry.cells[k]
		var key = "%v" % k
		save_data[cell_registry.resource_path][key] = cell_data.save_data

	for k in active_cells.keys():
		var cell := active_cells[k]
		var key = "%v" % k
		cell.cell_data.save_data = cell.save_cell(key)
		save_data[cell_registry.resource_path][key] = cell.cell_data.save_data

	return save_data

func _on_cell_added(_cell_data : CellData):
	to_add.erase(_cell_data.coordinates)
	emit_signal("cell_added", _cell_data)

func _on_cell_removed(_cell_data : CellData):
	to_remove.erase(_cell_data.coordinates)
	emit_signal("cell_removed", _cell_data)

func on_exit():
	cell_loader.on_exit()
