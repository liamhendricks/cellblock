class_name CellLoader
extends Node

signal cell_added(cell_data : CellData, cell : Cell)
signal cell_removed(cell_data : CellData, cell : Cell)

var world : Node3D
var active_cells : Dictionary[Vector3i, Cell]

func _init(_world : Node3D, _max_cache_size : int) -> void:
	pass

#virtual
func get_registry() -> CellRegistry:
	return null

# virtual
func configure(cell_registry : CellRegistry, cell_save : CellSave) -> void:
	pass

# virtual
func add(cell_data : CellData) -> void:
	pass

# virtual
func remove(cell_data : CellData) -> void:
	pass

# loads the save data from a persistent dictionary
func load_from(_all_save_data : Dictionary, _cell_data : CellData, _resource_path : String) -> bool:
	var key := _cell_data.coords_to_key()
	if _resource_path not in _all_save_data:
		_all_save_data[_resource_path] = {}
	else:
		var save_data = _all_save_data[_resource_path]
		if key in save_data:
			_cell_data.save_data = save_data[key]
		else:
			_cell_data.save_data = {}

	CellblockLogger.debug("cell data loaded %s" % key)
	return _cell_data.save_data.is_empty()

# saves the save data to a persistent dictionary
func save_to(_all_save_data : Dictionary, _cell_data : CellData, _resource_path : String) -> void:
	if _resource_path not in _all_save_data:
		_all_save_data[_resource_path] = {}

	var key := _cell_data.coords_to_key()
	_all_save_data[_resource_path][key] = _cell_data.save_data

	CellblockLogger.debug("cell data saved %s" % key)

func on_exit() -> void:
	for k in active_cells.keys():
		var cell = active_cells[k]
		if is_instance_valid(cell):
			cell.queue_free()

	active_cells.clear()

func get_active_cells() -> Dictionary[Vector3i, Cell]:
	return active_cells
