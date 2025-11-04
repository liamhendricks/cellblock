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

# the cell data resources, keyed by their grid coordinates
@export var cells : Dictionary[Vector3i, CellData]
# the chosen load strategy (behavior of how the cells are loaded and stored in memory)
@export var load_strategy : LOAD_STRATEGY = LOAD_STRATEGY.IN_MEMORY_REMOVE
# total number of cells that will be cached in memory for ASYNC_LOAD
@export_range(0, 25) var max_cache_size : int = 5
# the total size of your cell grid
@export var grid_size : Vector3i = Vector3i(512, 128, 512)
# the size of each individual cell
@export var cell_size : int = 128

# the radius of cells to keep active
# by default, you will get all cells in a radius of 1 like this (in 3d x,y,z coords):
# C C C
# C C C
# C C C
# a radius of 2 will look like this, etc etc:
# C C C C C
# C C C C C
# C C C C C
# C C C C C
# C C C C C
@export_range(1, 5) var radius_multiplier : int = 1
# the directory in your project where the cell .tscn files will be saved
@export var cell_directory : String = "res://cells/"
# the cell scene that will be created when you create a new cell. the addon provides
# a default, but it is recommended that you extend this and use yours instead
@export var base_cell_scene_path : String = "res://addons/cellblock/cell.tscn"
# sets the number of distance_to checks to do per frame - affects the 'responsiveness'.
# depending on the needs of your project, a low number may be just fine. set this
# higher if you want your cells to load more immediately when the player gets close to them
@export var iterations_per_frame : int = 5
