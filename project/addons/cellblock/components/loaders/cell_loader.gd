class_name CellLoader
extends Node

signal cell_added(cell_data : CellData)
signal cell_removed(cell_data : CellData)

var world : Node3D
var active_cells : Dictionary[Vector3i, Cell]
var cell_cache : CellCache

func _init(_world : Node3D, _max_cache_size : int):
	pass

# virtual
func configure(cell_registry : CellRegistry, cell_save : CellSave):
	pass

# virtual
func add(cell_data : CellData):
	pass

# virtual
func remove(cell_data : CellData):
	pass

func load_from(_all_save_data : Dictionary, _cell_data : CellData, _resource_path : String):
	if _resource_path not in _all_save_data:
		_cell_data.save_data = {}
	else:
		var save_data = _all_save_data[_resource_path]
		var key = "%v" % _cell_data.coordinates
		if key in save_data:
			_cell_data.save_data = save_data[key]
		else:
			_cell_data.save_data = {}

func save_to(_all_save_data : Dictionary, _cell_data : CellData, _resource_path : String):
	if _resource_path not in _all_save_data:
		return

	var save_data = _all_save_data[_resource_path]
	var key = "%v" % _cell_data.coordinates
	if key in save_data:
		save_data[key] = _cell_data.save_data

func on_exit():
	if cell_cache != null:
		cell_cache.clear()

	for k in active_cells.keys():
		var cell = active_cells[k]
		if is_instance_valid(cell):
			cell.queue_free()

	active_cells.clear()

func get_active_cells() -> Dictionary[Vector3i, Cell]:
	return active_cells
