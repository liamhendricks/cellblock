@tool
extends Control

@onready var x = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/XSpin
@onready var y = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/YSpin
@onready var z = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer3/ZSpin
@onready var registry_options = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer/Registry/RegistryOptions
@onready var cell_options = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer2/Cells/CellOptions
@onready var active_cell_container = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Panel2/MarginContainer/VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer
@onready var radius_load = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer3/HBoxContainer/Radius
@onready var delete_cell_label = $PanelContainer/MarginContainer/MarginContainer/DeleteCellPopup/MarginContainer/VBoxContainer/DeleteCellLabel
@onready var delete_cell_popup = $PanelContainer/MarginContainer/MarginContainer/DeleteCellPopup

var active_cell_ui_item_scene = load("res://addons/cellblock/active_cell_ui_item.tscn")

var active_cells : Array[EditingCellData]
var active_registry_index : int = 0
var cell_to_load : CellData
var create_cell_name : String
var coordinates : Vector3i
var anchor : CellAnchor
var plugin : EditorPlugin
var to_delete : EditingCellData

func _ready():
	for editing_cell in active_cells:
		if editing_cell.cell_ref != null:
			editing_cell.cell_ref.free()

	if !x.value_changed.is_connected(_coordinates_updated.bind(0)):
		x.value_changed.connect(_coordinates_updated.bind(0))
	if !y.value_changed.is_connected(_coordinates_updated.bind(1)):
		y.value_changed.connect(_coordinates_updated.bind(1))
	if !z.value_changed.is_connected(_coordinates_updated.bind(2)):
		z.value_changed.connect(_coordinates_updated.bind(2))

	active_cells.clear()
	_pick_cell_to_load(0)
	delete_cell_popup.visible = false
	to_delete = null
	init()

func init():
	active_registry_index = 0
	registry_options.clear()
	if anchor != null && len(anchor.cell_registries) > 0:
		for registry in anchor.cell_registries:
			registry_options.add_item(registry.resource_path)

		registry_options.selected = 0

func on_update():
	coordinates = Vector3i(x.value, y.value, z.value)
	_update_cell_options()
	_update_cursor()
	_update_active_cell_items()

	x.min_value = floor(-(anchor.cell_registries[active_registry_index].grid_size.x / 2) / anchor.cell_registries[active_registry_index].cell_size)
	y.min_value = floor(-(anchor.cell_registries[active_registry_index].grid_size.y / 2) / anchor.cell_registries[active_registry_index].cell_size)
	z.min_value = floor(-(anchor.cell_registries[active_registry_index].grid_size.z / 2) / anchor.cell_registries[active_registry_index].cell_size)
	x.max_value = floor((anchor.cell_registries[active_registry_index].grid_size.x / 2) / anchor.cell_registries[active_registry_index].cell_size)
	y.max_value = floor((anchor.cell_registries[active_registry_index].grid_size.y / 2) / anchor.cell_registries[active_registry_index].cell_size)
	z.max_value = floor((anchor.cell_registries[active_registry_index].grid_size.z / 2) / anchor.cell_registries[active_registry_index].cell_size)

func _on_delete_pressed(item : ActiveCellUiItem):
	var active_cell_index = item.cell_index
	var editing_cell = active_cells[active_cell_index]
	var cell = editing_cell.cell_ref
	delete_cell_label.text = "Delete Cell: %s" % editing_cell.cell_data.cell_name
	delete_cell_popup.visible = true
	to_delete = editing_cell

func _delete_cell():
	if !to_delete:
		return

	# delete cell_scene itself
	var dir := DirAccess.open(anchor.cell_registries[to_delete.registry_index].cell_directory)
	if dir == null:
		push_warning("cell_directory not found: %s" % anchor.cell_registries[to_delete.registry_index].cell_directory)
		return

	if dir.file_exists(to_delete.cell_data.scene_path):
		var err := dir.remove(to_delete.cell_data.scene_path)
		if err == OK:
			print("cell deleted: %s" % to_delete.cell_data.cell_name)
		else:
			push_warning("something went wrong, failed to delete scene at: %s - aborting delete" % to_delete.cell_data.scene_path)
			to_delete = null
			delete_cell_popup.visible = false
			return

	# delete cell_data from registry
	anchor.cell_registries[to_delete.registry_index].cells.erase(to_delete.cell_data.coordinates)
	ResourceSaver.save(anchor.cell_registries[to_delete.registry_index])

	# delete cell in the editor
	var root = EditorInterface.get_edited_scene_root()
	var active_cell = to_delete.cell_ref
	active_cell.queue_free()
	active_cells.remove_at(to_delete.active_cell_index)

	EditorInterface.get_resource_filesystem().scan()
	to_delete = null
	delete_cell_popup.visible = false

	on_update()

func _on_save_pressed(item : ActiveCellUiItem):
	var active_cell_index = item.cell_index
	var editing_cell = active_cells[active_cell_index]
	var cell = editing_cell.cell_ref
	_save_active_cell(cell, editing_cell.cell_data, editing_cell.registry_index)

func _on_save_all_pressed():
	_save_all()

func _save_active_cell(_active_cell : Cell, _cell_data : CellData, _idx : int):
	_cell_data.world_position = _active_cell.global_position
	var cell_size = anchor.cell_registries[_idx].cell_size
	_cell_data.coordinates = world_to_cell_space(_active_cell.global_position, cell_size)
	ResourceSaver.save(anchor.cell_registries[active_registry_index])

	_set_owner_recursive_safe(_active_cell, _active_cell)

	var scene = PackedScene.new()
	_active_cell.global_position = Vector3.ZERO
	scene.pack(_active_cell)
	ResourceSaver.save(scene, _cell_data.scene_path)

	# now that the scene is saved, we can make the cell editable again
	_active_cell.global_position = _cell_data.world_position
	_enable_cell_editing(_active_cell, EditorInterface.get_edited_scene_root())

func _save_all():
	for child in active_cell_container.get_children():
		var active_cell_index = child.cell_index
		var editing_cell = active_cells[active_cell_index]
		var cell = editing_cell.cell_ref
		_save_active_cell(cell, editing_cell.cell_data, editing_cell.registry_index)

func _on_load_pressed():
	_pick_cell_to_load(cell_options.get_selected_id())
	_load_cell()

func _load_cell():
	if cell_to_load == null:
		push_warning("no cell chosen to load")
		return

	if _check_cell_active(cell_to_load.coordinates):
		push_warning("cell already active at those coordinates")
		return

	var scene = load(cell_to_load.scene_path)
	if !scene:
		push_warning("cell scene does not exist at: %s" % cell_to_load.scene_path)
		return

	var cell : Cell = scene.instantiate()

	var editing_cell = EditingCellData.new()
	editing_cell.cell_data = cell_to_load
	editing_cell.cell_ref = cell
	editing_cell.registry_index = active_registry_index
	active_cells.append(editing_cell)
	editing_cell.active_cell_index = len(active_cells) - 1

	var root = EditorInterface.get_edited_scene_root()
	print("cell loaded at %v: %s, registry index: %d" % [cell_to_load.coordinates, cell_to_load.cell_name, active_registry_index])
	root.add_child(cell)
	var c = cell_to_world_space(cell_to_load.coordinates, anchor.cell_registries[active_registry_index].cell_size)
	cell.global_position = c
	anchor.global_position = c
	_enable_cell_editing(cell, root)
	cell.name = cell_to_load.cell_name

	on_update()

func _on_create_pressed() -> void:
	if coordinates in anchor.cell_registries[active_registry_index].cells:
		push_warning("cell already exists at the coordinates: %v, load cell instead" % coordinates)
		return

	var cell_data = CellData.new()
	cell_data.coordinates = coordinates
	if create_cell_name == "":
		create_cell_name = "cell_%d_%d_%d" % [coordinates.x, coordinates.y, coordinates.z]
	cell_data.cell_name = create_cell_name
	var dir = anchor.cell_registries[active_registry_index].cell_directory
	var can_open := DirAccess.open(dir)
	if !can_open:
		push_warning("cell directory does not exist at: %s" % dir)
		return

	cell_data.scene_path = dir + cell_data.cell_name + ".tscn"
	cell_data.world_position = anchor.global_position
	anchor.cell_registries[active_registry_index].cells[coordinates] = cell_data

	var path = anchor.cell_registries[active_registry_index].base_cell_scene_path

	can_open = DirAccess.open(cell_data.scene_path)
	if can_open:
		push_warning("cell already exists at: %s" % cell_data.scene_path)
		return

	var cell_scene = load(path)
	if !cell_scene:
		push_warning("cell scene does not exist at: %s" % path)
		return

	var cell = cell_scene.instantiate()
	var editing_cell = EditingCellData.new()
	editing_cell.cell_data = cell_data
	editing_cell.cell_ref = cell
	editing_cell.registry_index = active_registry_index
	active_cells.append(editing_cell)
	editing_cell.active_cell_index = len(active_cells) - 1

	var root = EditorInterface.get_edited_scene_root()
	print("cell created at %v with name: %s, registry index: %d" % [coordinates, cell_data.cell_name, active_registry_index])

	root.add_child(cell)
	cell.global_position = anchor.global_position
	_enable_cell_editing(cell, root)
	cell.name = cell_data.cell_name
	_save_active_cell(cell, cell_data, active_registry_index)
	on_update()

func _on_radius_load_pressed():
	var rad = radius_load.value
	for x in range(-rad, rad + 1):
		for y in range(-rad, rad + 1):
			for z in range(-rad, rad + 1):
				var coords : Vector3i = Vector3i(x, y, z)
				if coords not in anchor.cell_registries[active_registry_index].cells:
					continue
				var cell_data := anchor.cell_registries[active_registry_index].cells[coords]
				cell_to_load = cell_data
				_load_cell()

func _coordinates_updated(value : float, index : int):
	match(index):
		0: coordinates.x = value
		1: coordinates.y = value
		2: coordinates.z = value

	on_update()

func _registry_updated(index : int):
	active_registry_index = index
	on_update()

func cell_to_world_space(_coords : Vector3i, _cell_size : int) -> Vector3:
	return Vector3(
		_coords.x * _cell_size,
		_coords.y * _cell_size,
		_coords.z * _cell_size
	)

func world_to_cell_space(_pos : Vector3, _cell_size : int) -> Vector3i:
	return Vector3i(
		floor(_pos.x / _cell_size),
		floor(_pos.y / _cell_size),
		floor(_pos.z / _cell_size)
	)

func _update_active_cell_items():
	for child in active_cell_container.get_children():
		active_cell_container.remove_child(child)
		child.queue_free()

	for i in active_cells.size():
		var editing_cell := active_cells[i]
		var cell := editing_cell.cell_ref
		var cell_ui_item = active_cell_ui_item_scene.instantiate()
		active_cell_container.add_child(cell_ui_item)
		cell_ui_item.configure(editing_cell.cell_data, editing_cell.registry_index, i, _on_save_pressed, _on_clear_pressed, _on_delete_pressed)

func _update_cursor():
	if anchor.cell_registries.size() == 0:
		return

	anchor.global_position = cell_to_world_space(coordinates, anchor.cell_registries[active_registry_index].cell_size)

func _update_cell_options():
	cell_options.clear()

	for key in anchor.cell_registries[active_registry_index].cells.keys():
		var cell_data := anchor.cell_registries[active_registry_index].cells[key]
		cell_options.add_item(cell_data.cell_name)
		cell_options.set_item_metadata(cell_options.item_count - 1, key)

func _on_clear_pressed(item : ActiveCellUiItem) -> void:
	_clear(item.cell_index)

func _on_clear_all_pressed() -> void:
	_clear_all()

func _enable_cell_editing(cell : Node, root : Node):
	cell.owner = root
	cell.scene_file_path = ""
	_set_owner_recursive_safe(cell, root)

func _set_owner_recursive_safe(node: Node, owner: Node):
	if node.scene_file_path != "":
		node.owner = owner
		for child in node.get_children():
			# only recurse deeper if the child is not in an external scene
			if node != child.owner:
				_set_owner_recursive_safe(child, owner)
		return

	if node != owner:
		node.owner = owner
	for child in node.get_children():
		if child is Node:
			_set_owner_recursive_safe(child, owner)

func _clear(_cell_idx : int):
	var root = EditorInterface.get_edited_scene_root()
	var editing_cell = active_cells[_cell_idx]
	var active_cell = editing_cell.cell_ref
	root.remove_child(active_cell)
	active_cell.queue_free()
	active_cells.remove_at(_cell_idx)

	on_update()

func _clear_all():
	var root = EditorInterface.get_edited_scene_root()
	for editing_cell in active_cells:
		var active_cell = editing_cell.cell_ref
		print("clearing cell ", active_cell.name)
		root.remove_child(active_cell)
		active_cell.queue_free()

	active_cells.clear()
	on_update()

func _on_scene_saved(scene: Node) -> void:
	for child in scene.get_children():
		if child is Cell:
			push_warning("You have uncleared cells that you edited! Make sure you save them and clear them.")
			return

func _pick_cell_to_load(index: int) -> void:
	if index > (cell_options.item_count - 1):
		return

	var v: Vector3i = cell_options.get_item_metadata(index)
	var cell_data := anchor.cell_registries[active_registry_index].cells[v]
	cell_to_load = cell_data

func _check_cell_active(_coords : Vector3i) -> bool:
	for editing_cell in active_cells:
		if editing_cell.cell_data.coordinates == _coords && editing_cell.registry_index == active_registry_index:
			return true

	return false

func _on_cell_name_text_changed(new_text : String) -> void:
	create_cell_name = new_text

func _on_cancel_pressed() -> void:
	to_delete = null
	delete_cell_popup.visible = false
