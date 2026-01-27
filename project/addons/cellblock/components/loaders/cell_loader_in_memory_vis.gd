class_name CellLoaderInMemoryVisual
extends CellLoader

# This loader will load and configure all cells on initial start and store them
# in the cells dictionary. The cells remain in memory and in the scene tree, but
# only nearby cells will have visible = enabled.

# all configured cell scenes
var cells : Dictionary[Vector3i, Cell]
var cell_registry : CellRegistry

func _init(_world : Node3D, _max_cache_size : int):
	world = _world

func configure(_cell_registry : CellRegistry, _cell_save : CellSave):
	var all_save_data = _cell_save.load_save()
	cell_registry = _cell_registry
	for k in _cell_registry.cells.keys():
		var cell_data : CellData = _cell_registry.cells[k]
		var cell : Cell = cell_data.get_scene_instance()
		cell.cell_data = cell_data
		if cell == null:
			continue

		load_from(cell, all_save_data, cell_data, _cell_registry.resource_path)
		world.add_child(cell)
		cell.name = cell_data.cell_name
		cell.process_frames = cell_registry.mutable_process_frames
		cell.global_position = cell_data.world_position
		cell.load_cell(cell_data.save_data)
		cells[cell_data.coordinates] = cell
		cell.visible = false

func add(cell_data : CellData):
	if cell_data.coordinates in active_cells:
		return

	# load the cell from in memory dictionary
	if cell_data.coordinates not in cells:
		CellblockLogger.error("unable to load cell from coordinates: %v" % cell_data.coordinates)
		return

	CellblockLogger.debug("enabling cell from memory")

	var cell : Cell = cells[cell_data.coordinates]
	cell.cell_data = cell_data

	active_cells[cell_data.coordinates] = cell
	cell.visible = true
	cell_data.save_data = cell.save_cell("%v" % cell_data.coordinates)

	call_deferred("_finish_loading", cell)

func _finish_loading(cell : Cell):
	CellblockLogger.debug("cell added to in memory visual")
	emit_signal("cell_added", cell.cell_data, cell)

func remove(cell_data : CellData):
	if cell_data.coordinates not in active_cells:
		return

	var cell : Cell = active_cells[cell_data.coordinates]
	cell_data.save_data = cell.save_cell("%v" % cell_data.coordinates)
	cell.visible = false
	active_cells.erase(cell_data.coordinates)

	emit_signal("cell_removed", cell_data, cell)

func on_exit():
	super()

	for k in cells.keys():
		var cell = cells[k]
		cell.queue_free()
