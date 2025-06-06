class_name CellLoader
extends Resource

signal cell_added(cell_data : CellData)
signal cell_removed(cell_data : CellData)

var world : Node3D
var active_cells : Dictionary[Vector3i, Cell]
var cell_cache : LruCache

func _init(_world : Node3D, _max_cache_size : int):
	world = _world
	cell_cache = LruCache.new(_max_cache_size)

# virtual
func configure(cell_registry : CellRegistry, cell_save : CellSave):
	pass

# virtual
func add(cell_data : CellData):
	pass

# virtual
func remove(cell_data : CellData):
	pass

func on_exit():
	cell_cache.clear()

	for k in active_cells.keys():
		var cell = active_cells[k]
		if is_instance_valid(cell):
			cell.queue_free()

	active_cells.clear()

func get_active_cells() -> Dictionary[Vector3i, Cell]:
	return active_cells
