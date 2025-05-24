class_name CellLoader
extends Resource

signal cell_added(cell_data : CellData)
signal cell_removed(cell_data : CellData)
signal cells_configured()

var world : Node3D
var active_cells : Dictionary[Vector3i, Cell]
var cell_cache : LruCache

func _init(_world : Node3D, _max_cache_size : int):
	world = _world
	cell_cache = LruCache.new(_max_cache_size)

# virtual
func configure(cell_registry : CellRegistry):
	pass

# virtual
func add(cell_data : CellData):
	pass

# virtual
func remove(cell_data : CellData):
	pass

#virtual
func on_exit():
	cell_cache.clear()

	for k in active_cells.keys():
		var cell = active_cells[k]
		if is_instance_valid(cell):
			cell.queue_free()

	active_cells.clear()

# write the save data currently in the cell registry, and active cells
func save_cells(cell_registry : CellRegistry):
	var save_data = {}
	for k in cell_registry.cells.keys():
		var cell_data := cell_registry.cells[k]
		var key = "%v" % k
		save_data[key] = cell_data.save_data

	for k in active_cells.keys():
		var cell := active_cells[k]
		var key = "%v" % k
		cell.cell_data.save_data = cell.save_cell(key)
		save_data[key] = cell.cell_data.save_data

	cell_registry.cell_save.write_save(save_data)

# if no key exists in the save_data, we can safely assume it's the first time loading this cell
func _try_load_cell(cell_data : CellData, cell : Cell, save_data : Dictionary):
	var key = "%v" % cell_data.coordinates
	if key in save_data:
		cell_data.save_data = save_data[key]
		cell.load_cell(cell_data.save_data)
	else:
		cell_data.save_data = cell.save_cell(key)
