class_name CellRegistry
extends Resource

# The addon will do cell management based on this strategy while the game runs
enum LOAD_STRATEGY {
	# All cells are loaded in memory and added onto the scene tree. Cells that are close enough
	# will have visibility enabled, and those that are too far will have visibility disabled. This
	# strategy is good for games which need nodes underneath Cells to continuously run scripts.
	IN_MEMORY_VISUAL,

	# All cells are loaded in memory, but Cells are not added the scene until they are close enough
	# to the origin. scene tree. This is the default option. Cells will remain loaded in memory as 
	# orphaned nodes so none of their scripts will run.
	IN_MEMORY_REMOVE,

	# Cells are not loaded into memory until they are close enough to the origin. They are loaded in 
	# a separate thread and then added to the scene tree. LRU Cache described above is used here as
	# well.
	ASYNC_LOAD,
}

@export var cells : Dictionary[Vector3i, CellData]
@export_range(0, 25) var max_cache_size : int = 5
@export var load_strategy : LOAD_STRATEGY = LOAD_STRATEGY.IN_MEMORY_REMOVE
@export var grid_size : Vector3i = Vector3i(100, 100, 100)
@export var cell_size : int = 10
@export var cell_directory : String = "res://cells/"
@export var base_cell_scene_path : String = "res://addons/cellblock/cell.tscn"
@export_range(1, 3) var radius : int = 2
