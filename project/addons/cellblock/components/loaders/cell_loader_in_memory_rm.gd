class_name CellLoaderInMemoryRemove
extends CellLoader

# This loader will load and configure all cells on initial start and store them
# in the cells dictionary. The cells remain in memory and are never queue_freed
# until the world scene itself is freed.

var cells : Dictionary[Vector3i, Cell]

func configure(_cell_registry : CellRegistry, _cell_save : CellSave):
	var all_save_data = _cell_save.load_save()
	for k in _cell_registry.cells.keys():
		var cell_data : CellData = _cell_registry.cells[k]
		var cell : Cell = cell_data.get_scene_instance()
		cell.cell_data = cell_data
		if cell == null:
			continue

		if _cell_registry.resource_path not in all_save_data:
			cell_data.save_data = {}
		else:
			var save_data = all_save_data[_cell_registry.resource_path]
			var key = "%v" % k
			if key in save_data:
				cell_data.save_data = save_data[key]
			else:
				cell_data.save_data = {}

		cells[cell_data.coordinates] = cell

func add(cell_data : CellData):
	if cell_data.coordinates in active_cells:
		return

	# load the cell from in memory dictionary
	if cell_data.coordinates not in cells:
		push_error("unable to load cell from coordinates: %v" % cell_data.coordinates)
		return

	var cell : Cell = cells[cell_data.coordinates]
	cell.cell_data = cell_data

	active_cells[cell_data.coordinates] = cell
	world.add_child(cell)
	cell.global_position = cell_data.world_position
	cell.load_cell(cell_data.save_data)
	cell_data.save_data = cell.save_cell("%v" % cell_data.coordinates)

	emit_signal("cell_added", cell_data)

func remove(cell_data : CellData):
	if cell_data.coordinates not in active_cells:
		return

	var cell : Cell = active_cells[cell_data.coordinates]
	cell_data.save_data = cell.save_cell("%v" % cell_data.coordinates)
	world.remove_child(cell)
	active_cells.erase(cell_data.coordinates)

	emit_signal("cell_removed", cell_data)

func on_exit():
	super()

	for k in cells.keys():
		var cell = cells[k]
		cell.queue_free()
