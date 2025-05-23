class_name CellLoaderInMemoryRemove
extends CellLoader

# This loader will load and configure all cells on initial load and store them
# in the cells dictionary. The cells remain in memory and are never queue_freed.

var cells : Dictionary[Vector3i, Cell]

func configure(cell_registry : CellRegistry):
	for k in cell_registry.cells.keys():
		var cell_data : CellData = cell_registry.cells[k]
		var cell : Cell = cell_data.get_scene_instance()
		cell.cell_data = cell_data
		if cell == null:
			continue

		cells[cell_data.coordinates] = cell
		print("added %s at: %v" % [cell_data.cell_name, cell_data.coordinates])

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

func remove(cell_data : CellData):
	if cell_data.coordinates not in active_cells:
		return

	var cell : Cell = active_cells[cell_data.coordinates]
	world.remove_child(cell)
	active_cells.erase(cell_data.coordinates)

func on_exit():
	super()

	for k in cells.keys():
		var cell = cells[k]
		cell.queue_free()
