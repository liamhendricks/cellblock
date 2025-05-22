class_name CellRegistry
extends Resource

# The addon will do cell management based on this strategy while the game runs
enum LOAD_STRATEGY {
	# All cells are loaded in memory and added onto the scene tree. Cells that pass distance checks
	# will have visibility enabled, and those that are too far will have visibility disabled. This
	# strategy is good for games which need nodes underneath Cells to continuously run scripts.
	IN_MEMORY_VISUAL,

	# All cells are loaded in memory, but only Cells that pass distance checks will be added to the
	# scene tree. This is the default option. Cells will remain loaded in memory as orphaned nodes
	# so none of their scripts will run.
	IN_MEMORY_REMOVE,

	# Same as above, but adding / removing from the scene tree is done in a separate thread. Removed
	# Cells are placed into a LRU Cache that is of size max_loaded_cells so that they can remain in 
	# memory and don't have to be reloaded all the time.
	IN_MEMORY_REMOVE_ASYNC,

	# Cells are not loaded into memory until they pass a distance check. They are loaded in a
	# separate thread and then added to the scene tree. LRU Cache described above is used here as
	# well.
	ASYNC_LOAD,
}

@export var cells : Dictionary[Vector3i, CellData]
@export var max_loaded_cells : int = 20
@export var max_cache_size : int = 5
@export var load_strategy : LOAD_STRATEGY = LOAD_STRATEGY.IN_MEMORY_REMOVE
@export var grid_size : Vector3i = Vector3i(100, 100, 100)
@export_range(0, 100) var cell_size : int = 10

# how many Cells the CellManager will process per frame
@export var num_iterations : int = 1
