class_name CellLoaderInMemoryRemove
extends CellLoader

# This loader will load and configure all cells on initial start and store them
# in the cells dictionary. The cells remain in memory and are never queue_freed
# until the world scene itself is freed. Save state is retained in memory.

# all configured cell scenes
var cells : Dictionary[Vector3i, Cell]
var cell_registry : CellRegistry
var pending_scenes : Dictionary = {}

func _init(_world : Node3D, _max_cache_size : int) -> void:
	world = _world

func configure(_cell_registry : CellRegistry, _cell_save : CellSave) -> void:
	var all_save_data = _cell_save.load_save()
	cell_registry = _cell_registry
	for k in _cell_registry.cells.keys():
		var cell_data : CellData = cell_registry.cells[k]
		var cell : Cell = cell_data.get_scene_instance()
		if cell == null:
			CellblockLogger.error(
				"failed to instantiate cell: %s at %s" % [cell_data.scene_path, cell_data.coordinates]
			)
			continue

		CellblockLogger.debug("cell %s instantiated" % cell_data.coords_to_key())
		cell.mutable_process_frames = cell_registry.mutable_process_frames
		cell.static_process_frames = cell_registry.static_process_frames
		cell.cell_data = cell_data

		var should_load := load_from(all_save_data, cell_data, cell_registry.resource_path)
		if should_load:
			cell_data.save_data = cell.save_cell(cell_data.coords_to_key())

		cells[cell_data.coordinates] = cell

func get_registry() -> CellRegistry:
	return cell_registry

func add(cell_data : CellData) -> void:
	if cell_data.coordinates in active_cells:
		return

	if cell_data.coordinates not in cells:
		CellblockLogger.error("unable to load cell from coordinates: %v" % cell_data.coordinates)
		return

	var key := CellManager.instantiation_worker.request_key()
	var cell : Cell = cells[cell_data.coordinates]
	var data : Dictionary = {
		"cell": cell,
		"cell_data": cell_data,
		"should_load": false,
		"key": key,
	}
	pending_scenes[cell_data.coordinates] = data
	CellManager.instantiation_worker.enqueue(data, key)

func _finish_loading(cell : Cell, cell_data : CellData) -> void:
	if cell == null:
		pending_scenes.erase(cell_data.coordinates)
		emit_signal("cell_added", cell_data, null)
		return

	active_cells[cell_data.coordinates] = cell
	world.add_child(cell)
	cell.name = cell_data.cell_name
	cell.mutable_process_frames = cell_registry.mutable_process_frames
	cell.static_process_frames = cell_registry.static_process_frames
	cell.global_position = cell_data.world_position
	cell.load_cell_async(cell_data.save_data)
	CellblockLogger.debug("cell %s added" % cell_data.coords_to_key())
	emit_signal("cell_added", cell_data, cell)

func remove(cell_data : CellData) -> void:
	if cell_data.coordinates not in active_cells:
		return

	var cell : Cell = active_cells[cell_data.coordinates]
	cell_data.save_data = cell.save_cell(cell_data.coords_to_key())

	world.remove_child(cell)
	active_cells.erase(cell_data.coordinates)

	CellblockLogger.debug("cell %s removed" % cell_data.coords_to_key())
	emit_signal("cell_removed", cell_data, cell)

func _process(_delta : float) -> void:
	for k in pending_scenes.keys():
		var data = pending_scenes[k]
		var cell_data = data["cell_data"]

		var scell = data["cell"]
		if scell != null:
			#here we are polling for our cell to be ready
			var cell : Cell = CellManager.instantiation_worker.get_done_node(data["key"])
			if cell != null:
				_finish_loading(cell, cell_data)
		else:
			_finish_loading(null, cell_data)

func on_exit() -> void:
	super()

	for k in cells.keys():
		var cell = cells[k]
		if is_instance_valid(cell):
			cell.queue_free()
