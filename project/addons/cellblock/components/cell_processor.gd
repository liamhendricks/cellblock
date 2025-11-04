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
var current_index : int

var current_cell_coords : Vector3i = Vector3.ZERO
var half_cell_size : float = 0.0

func _init(_cell_registry : CellRegistry, _cell_loader : CellLoader, _name : String) -> void:
	half_cell_size = _cell_registry.cell_size / 2
	cell_registry = _cell_registry
	cell_loader = _cell_loader
	cell_loader.cell_removed.connect(_on_cell_removed)
	cell_loader.cell_added.connect(_on_cell_added)
	if len(_cell_registry.cells) > 0:
		var key = _cell_registry.cells.keys()[0]
		current_cell_coords = _cell_registry.cells[key].coordinates

func work_all_cells(origin_object : Node3D):
	for k in cell_registry.cells.keys():
		_work_cell(origin_object, k)

func _work(origin_object : Node3D):
	for i in range(cell_registry.iterations_per_frame):
		var key = cell_registry.cells.keys()[current_index]
		current_index += 1
		if current_index > len(cell_registry.cells) - 1:
			current_index = 0

		_work_cell(origin_object, key)

# convert the cell_data coords to world space and calculate the distance to the
# origin and the current nearest cell.
func _work_cell(origin_object : Node3D, _coords : Vector3i) -> void:
	var in_range : bool = false
	var cd : CellData = cell_registry.cells[_coords]
	var world_space_coords = CellManager.cell_to_world_space(_coords, cell_registry.cell_size)
	var dist : float = origin_object.global_position.distance_to(world_space_coords)
	var dist_to_current : float = origin_object.global_position.distance_to(current_cell_coords)

	if dist <= (cell_registry.cell_size * cell_registry.radius_multiplier) + half_cell_size:
		in_range = true
		if dist < dist_to_current:
			update_current_cell(cd.coordinates)

	if in_range:
		if cd.coordinates not in cell_loader.active_cells:
			cell_loader.add(cd)
	else:
		if cd.coordinates in cell_loader.active_cells:
			var cell : Cell = cell_loader.active_cells[cd.coordinates]
			try_reparent_mutable(cell, cd.coordinates)
			cell_loader.remove(cd)

func update_current_cell(_cell_coords : Vector3i) -> void:
	if _cell_coords not in cell_registry.cells:
		return

	if _cell_coords != current_cell_coords:
		var old : CellData = cell_registry.cells[current_cell_coords]
		var new_current : CellData = cell_registry.cells[_cell_coords]
		current_cell_coords = _cell_coords
		enter_cell(old, new_current)

func enter_cell(_old : CellData, _new : CellData) -> void:
	emit_signal("entered_cell", _old, _new)

func try_reparent_mutable(_cell : Cell, _key : Vector3i):
	var _mutable_data = _cell.get_mutable()
	if len(_mutable_data.keys()) == 0:
		return

	var cell_data = cell_registry.cells[_key]
	for k in _mutable_data.keys():
		for object in _mutable_data[k]:
			# if the object clamps to a new cell that exists, parent it there
			var pos = object.global_transform.origin
			var actual = CellManager.world_to_cell_space(pos, cell_registry.cell_size)

			if actual != _key:
				reparent_node(_key, actual, object, k, _cell)

func reparent_node(_from : Vector3i, _to : Vector3i, _node : Node3D, _data_key : String, _old_cell : Cell):
	if _to not in cell_registry.cells:
		return

	var old = cell_registry.cells[_from]
	var new = cell_registry.cells[_to]

	var tmp_pos = _node.global_position
	var parent = _node.get_parent()
	parent.remove_child(_node)

	old.save_data = _old_cell.save_cell("%v" % _from)

	# if the new cell is already loaded, just add it. the new node will be included in the save if
	# the cell gets removed, or if saved while active
	if _to in cell_loader.active_cells:
		var new_cell := cell_loader.active_cells[_to]
		new_cell.add_mutable(_node, _data_key, tmp_pos)
	else:
		if _node.has_method("on_save") && len(new.save_data.keys()) > 0:
			var resave = _node.on_save()
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
		var cell_data = cell_registry.cells[k]
		var key = "%v" % k
		save_data[cell_registry.resource_path][key] = cell_data.save_data

	for k in active_cells.keys():
		var cell := active_cells[k]
		var key = "%v" % k
		cell.cell_data.save_data = cell.save_cell(key)
		save_data[cell_registry.resource_path][key] = cell.cell_data.save_data

	return save_data

func _on_cell_added(_cell_data : CellData, _cell : Cell):
	emit_signal("cell_added", _cell_data)

func _on_cell_removed(_cell_data : CellData, _cell : Cell):
	emit_signal("cell_removed", _cell_data)

func on_exit():
	cell_loader.on_exit()
