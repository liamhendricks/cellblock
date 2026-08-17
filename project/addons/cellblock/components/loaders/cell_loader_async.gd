extends CellLoader
class_name CellLoaderAsync

signal scene_load_progress(progress : float)
signal scene_load_complete()

# This loader loads nearby cells from disk, and only retains a number equal to
# cache_size in the cache. Save state is handled at time of load / unload

var done_loading : bool = false
var pending_scenes = {}
var all_save_data : Dictionary
var cell_registry : CellRegistry

func _init(_world : Node3D, _max_cache_size : int):
	world = _world
	cell_cache = CellCache.new(_max_cache_size)

func configure(_cell_registry : CellRegistry, _cell_save : CellSave):
	all_save_data = _cell_save.load_save()
	cell_registry = _cell_registry

func add(cell_data : CellData):
	if cell_data.coordinates in active_cells:
		return

	# load the cell from in-memory cache if exists
	var cell := cell_cache.pull(cell_data.coordinates)
	if cell != null:
		CellblockLogger.debug("pulling cell from cache")
		call_deferred("_finish_loading", cell, cell_data)
		return

	CellblockLogger.debug("loading cell from disk")

	# otherwise trigger an async load operation
	call_deferred("_deferred_load", cell_data)

func remove(cell_data : CellData):
	if cell_data.coordinates not in active_cells:
		return

	var cell : Cell = active_cells[cell_data.coordinates]
	save_to(all_save_data, cell_data, cell_registry.resource_path)
	cell_data.save_data = cell.save_cell("%v" % cell_data.coordinates)

	world.remove_child(cell)
	active_cells.erase(cell_data.coordinates)

	# cells get auto freed on cache eviction here
	if !cell_cache.exists(cell_data.coordinates):
		cell_cache.add(cell_data.coordinates, cell)

	CellblockLogger.debug("cell removed from async loader")
	emit_signal("cell_removed", cell_data, cell)

func _deferred_load(cell_data : CellData):
	var res = ResourceLoader.load_threaded_request(cell_data.scene_path)
	if res == OK && cell_data.coordinates not in pending_scenes:
		pending_scenes[cell_data.coordinates] = {
			"cell_data": cell_data,
			"progress": [0.0],
			"done": false,
			"scene": null,
		}

func _finish_loading(cell : Cell, cell_data : CellData):
	cell.cell_data = cell_data

	active_cells[cell_data.coordinates] = cell
	var time_start = Time.get_ticks_msec()
	load_from(cell, all_save_data, cell_data, cell_registry.resource_path)

	# remove all mutable objects and we will load them one by one
	var mutable_names = cell.get_mutable_names()
	for child in cell.get_children():
		if mutable_names.has(child.name):
			for gc in child.get_children():
				child.remove_child(gc)
				gc.queue_free()

	# remove all static objects and we will load them one by one
	var object_adder : ObjectAdder = ObjectAdder.new()
	var static_names = cell.get_static_names()
	for child in cell.get_children():
		if static_names.has(child.name):
			for gc in child.get_children():
				child.remove_child(gc)
				gc.owner = null
				object_adder.add_pending_scene(gc)

	cell.add_child(object_adder)
	cell.object_adder = object_adder
	world.add_child(cell)
	cell.mutable_process_frames = cell_registry.mutable_process_frames
	cell.static_process_frames = cell_registry.static_process_frames
	cell.global_position = cell_data.world_position
	cell.object_adder.start()
	cell.load_cell(cell_data.save_data)
	cell_data.save_data = cell.save_cell("%v" % cell_data.coordinates)

	pending_scenes.erase(cell_data.coordinates)
	CellblockLogger.debug("cell added to async loader")
	emit_signal("cell_added", cell_data, cell)

func _process(_delta):
	for k in pending_scenes.keys():
		var data = pending_scenes[k]
		var done = data["done"]
		var progress = data["progress"]
		var cell_data = data["cell_data"]

		if done:
			var scene = data["scene"]
			data["done"] = false
			var cell : Cell = scene.instantiate()
			call_deferred("_finish_loading", cell, cell_data)
			continue

		var load_status = ResourceLoader.load_threaded_get_status(cell_data.scene_path, progress)
		match load_status:
			0,2: # ERROR
				done_loading = false
				set_process(false)
				return
			1: # progress
				emit_signal("scene_load_progress", progress[0])
			3: # finished
				var scene = ResourceLoader.load_threaded_get(cell_data.scene_path)
				data["scene"] = scene
				data["done"] = true
