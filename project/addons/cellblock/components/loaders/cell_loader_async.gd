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

func load_from(_cell : Cell, _all_save_data : Dictionary, _cell_data : CellData, _resource_path : String):
	var key = "%v" % _cell_data.coordinates
	if _resource_path not in _all_save_data:
		_cell_data.save_data = {}
	else:
		var save_data = _all_save_data[_resource_path]
		if key in save_data:
			_cell_data.save_data = save_data[key]
		else:
			_cell_data.save_data = {}

	# if we didn't have any previously saved data, we can try to load it directly from the cell
	# likely this is a first load scenario
	if len(_cell_data.save_data.keys()) == 0:
		_cell_data.save_data = _cell.save_cell(key)

func add(_cell_data : CellData):
	if _cell_data.coordinates in active_cells:
		return

	# load the cell from in-memory cache if exists
	var cell := cell_cache.pull(_cell_data.coordinates)
	if cell != null:
		_finish_loading(cell, _cell_data)
		return

	# otherwise trigger an async load operation
	call_deferred("_deferred_load", _cell_data)

func remove(_cell_data : CellData):
	if _cell_data.coordinates not in active_cells:
		return

	var cell : Cell = active_cells[_cell_data.coordinates]
	save_to(all_save_data, _cell_data, cell_registry.resource_path)
	_cell_data.save_data = cell.save_cell("%v" % _cell_data.coordinates)

	world.remove_child(cell)
	active_cells.erase(_cell_data.coordinates)

	# cells get auto freed on cache eviction here
	if !cell_cache.exists(_cell_data.coordinates):
		cell_cache.add(_cell_data.coordinates, cell)

	emit_signal("cell_removed", _cell_data)

func _deferred_load(_cell_data : CellData):
	var res = ResourceLoader.load_threaded_request(_cell_data.scene_path)
	if res == OK && _cell_data.coordinates not in pending_scenes:
		pending_scenes[_cell_data.coordinates] = {
			"cell_data": _cell_data,
			"progress": [0.0],
			"done": false,
			"scene": null,
		}

func _finish_loading(_cell : Cell, _cell_data : CellData):
	_cell.cell_data = _cell_data

	active_cells[_cell_data.coordinates] = _cell
	world.add_child(_cell)
	_cell.global_position = _cell_data.world_position
	load_from(_cell, all_save_data, _cell_data, cell_registry.resource_path)
	_cell.load_cell(_cell_data.save_data)
	_cell_data.save_data = _cell.save_cell("%v" % _cell_data.coordinates)

	pending_scenes.erase(_cell_data.coordinates)
	emit_signal("cell_added", _cell_data)

func _process(_delta):
	for k in pending_scenes.keys():
		var data = pending_scenes[k]
		var done = data["done"]
		var progress = data["progress"]
		var cell_data = data["cell_data"]

		if done:
			var scene = data["scene"]
			data["done"] = false
			var cell = scene.instantiate()
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
