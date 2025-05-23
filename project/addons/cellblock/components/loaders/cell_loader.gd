class_name CellLoader
extends Resource

var world : Node3D
var active_cells : Dictionary[Vector3i, Cell]
var cell_cache : LruCache

func _init(_world : Node3D, _max_cache_size : int):
	cell_cache = LruCache.new(_max_cache_size)

func configure(cell_registry : CellRegistry):
	pass

# virtual
func add(cell_data : CellData):
	pass

# virtual
func remove(cell_data : CellData):
	pass
