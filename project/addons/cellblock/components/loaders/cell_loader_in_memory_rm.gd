extends CellLoader

var cells : Dictionary[Vector3i, Cell]

func configure(cell_registry : CellRegistry):
	pass

func add(cell_data : CellData):
	if cell_data.coordinates in active_cells:
		return

	# load the cell from in memory dictionary
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
