class_name CellLoaderInMemoryVisual
extends CellLoader

# This loader will load and configure all cells on initial start and store them
# in the cells dictionary. The cells remain in memory and in the scene tree, but
# only nearby cells will have visible = enabled.

# all configured cell scenes
var cells : Dictionary[Vector3i, Cell]
var cell_registry : CellRegistry

func _init(_world : Node3D, _max_cache_size : int) -> void:
	world = _world

func configure(_cell_registry : CellRegistry, _cell_save : CellSave) -> void:
	var all_save_data = _cell_save.load_save()
	cell_registry = _cell_registry
	for k in _cell_registry.cells.keys():
		var cell_data : CellData = _cell_registry.cells[k]
		var cell : Cell = cell_data.get_scene_instance()
		if cell == null:
			continue

		CellblockLogger.debug("cell %s instantiated" % cell_data.coords_to_key())
		var should_load := load_from(all_save_data, cell_data, _cell_registry.resource_path)
		if should_load:
			cell_data.save_data = cell.save_cell(cell_data.coords_to_key())

		# remove all mutable objects and we will load them one by one
		var mutable_names = cell.get_mutable_names()
		for child in cell.get_children():
			if mutable_names.has(child.name):
				for gc in child.get_children():
					child.remove_child(gc)
					gc.queue_free()

		cell.cell_data = cell_data
		world.add_child(cell)
		cell.name = cell_data.cell_name
		cell.mutable_process_frames = cell_registry.mutable_process_frames
		cell.static_process_frames = cell_registry.static_process_frames
		cell.global_position = cell_data.world_position
		cell.load_cell(cell_data.save_data)
		cells[cell_data.coordinates] = cell
		cell.visible = false
		cell.cell_fully_configured = true
		CellblockLogger.debug("cell %s added" % cell_data.coords_to_key())

func get_registry() -> CellRegistry:
	return cell_registry

func add(cell_data : CellData) -> void:
	if cell_data.coordinates in active_cells:
		return

	# load the cell from in memory dictionary
	if cell_data.coordinates not in cells:
		CellblockLogger.error("unable to load cell from coordinates: %v" % cell_data.coordinates)
		return

	var cell : Cell = cells[cell_data.coordinates]
	active_cells[cell_data.coordinates] = cell
	cell.visible = true

	call_deferred("_finish_loading", cell)

func _finish_loading(cell : Cell) -> void:
	CellblockLogger.debug("cell %s added" % cell.cell_data.coords_to_key())
	emit_signal("cell_added", cell.cell_data, cell)

func remove(cell_data : CellData) -> void:
	if cell_data.coordinates not in active_cells:
		return

	var cell : Cell = active_cells[cell_data.coordinates]
	cell_data.save_data = cell.save_cell(cell_data.coords_to_key())
	cell.visible = false
	active_cells.erase(cell_data.coordinates)

	CellblockLogger.debug("cell %s removed" % cell_data.coords_to_key())
	emit_signal("cell_removed", cell_data, cell)

func on_exit() -> void:
	super()

	for k in cells.keys():
		var cell = cells[k]
		cell.queue_free()
