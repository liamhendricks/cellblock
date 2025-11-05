class_name CellLoaderInMemoryRemove
extends CellLoader

# This loader will load and configure all cells on initial start and store them
# in the cells dictionary. The cells remain in memory and are never queue_freed
# until the world scene itself is freed. Save state is retained in memory.

# all configured cell scenes
var cells : Dictionary[Vector3i, Cell]

func _init(_world : Node3D, _max_cache_size : int):
	world = _world

func configure(_cell_registry : CellRegistry, _cell_save : CellSave):
	var all_save_data = _cell_save.load_save()
	for k in _cell_registry.cells.keys():
		var cell_data : CellData = _cell_registry.cells[k]
		var key = "%v" % cell_data.coordinates
		var cell : Cell = cell_data.get_scene_instance()
		cell.cell_data = cell_data
		if cell == null:
			continue

		load_from(cell, all_save_data, cell_data, _cell_registry.resource_path)

		cells[cell_data.coordinates] = cell

func add(cell_data : CellData):
	if cell_data.coordinates in active_cells:
		return

	# load the cell from in memory dictionary
	if cell_data.coordinates not in cells:
		push_error("unable to load cell from coordinates: %v" % cell_data.coordinates)
		return

	print("adding cell from memory")

	var cell : Cell = cells[cell_data.coordinates]
	cell.cell_data = cell_data

	# remove all mutable objects and we will load them one by one
	var mutable_names = cell.get_mutable_names()
	for child in cell.get_children():
		if mutable_names.has(child.name):
			for gc in child.get_children():
				gc.queue_free()

	active_cells[cell_data.coordinates] = cell
	world.add_child(cell)
	cell.name = cell_data.cell_name
	cell.global_position = cell_data.world_position
	cell.load_cell(cell_data.save_data)
	cell_data.save_data = cell.save_cell("%v" % cell_data.coordinates)

	emit_signal("cell_added", cell_data, cell)

func remove(cell_data : CellData):
	if cell_data.coordinates not in active_cells:
		return

	var cell : Cell = active_cells[cell_data.coordinates]
	cell_data.save_data = cell.save_cell("%v" % cell_data.coordinates)
	world.remove_child(cell)
	active_cells.erase(cell_data.coordinates)

	emit_signal("cell_removed", cell_data, cell)

func on_exit():
	super()

	for k in cells.keys():
		var cell = cells[k]
		if is_instance_valid(cell):
			cell.queue_free()
