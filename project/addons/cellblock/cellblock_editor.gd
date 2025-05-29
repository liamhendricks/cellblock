@tool
extends Control

@onready var x = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/XSpin
@onready var y = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/YSpin
@onready var z = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/ZSpin
@onready var container = $PanelContainer/MarginContainer/VBoxContainer

var active_cell : Cell
var coordinates : Vector3i
var anchor : CellAnchor
var plugin : EditorPlugin

func _ready():
	init()

func init():
	coordinates = Vector3i(x.value, y.value, z.value)
	if anchor != null && anchor.cell_registry != null:
		x.min_value = floor(-(anchor.cell_registry.grid_size.x / 2) / anchor.cell_registry.cell_size)
		y.min_value = floor(-(anchor.cell_registry.grid_size.y / 2) / anchor.cell_registry.cell_size)
		z.min_value = floor(-(anchor.cell_registry.grid_size.z / 2) / anchor.cell_registry.cell_size)
		x.max_value = floor((anchor.cell_registry.grid_size.x / 2) / anchor.cell_registry.cell_size)
		y.max_value = floor((anchor.cell_registry.grid_size.y / 2) / anchor.cell_registry.cell_size)
		z.max_value = floor((anchor.cell_registry.grid_size.z / 2) / anchor.cell_registry.cell_size)

	if !x.value_changed.is_connected(_coordinates_updated.bind(0)):
		x.value_changed.connect(_coordinates_updated.bind(0))
	if !y.value_changed.is_connected(_coordinates_updated.bind(1)):
		y.value_changed.connect(_coordinates_updated.bind(1))
	if !z.value_changed.is_connected(_coordinates_updated.bind(2)):
		z.value_changed.connect(_coordinates_updated.bind(2))

func _on_save_pressed():
	_save_active_cell()

func _save_active_cell():
	print("saving active")
	var cell_data = anchor.cell_registry.cells[coordinates]
	cell_data.world_position = active_cell.global_position
	cell_data.coordinates = coordinates
	ResourceSaver.save(anchor.cell_registry)

	_set_owner_recursive_safe(active_cell, active_cell)

	print("done setting owner temporarily")
	var scene = PackedScene.new()
	active_cell.global_position = Vector3.ZERO
	scene.pack(active_cell)
	ResourceSaver.save(scene, cell_data.scene_path)

	print("done saving")
	# now that the scene is saved, we can make the cell editable again
	active_cell.global_position = cell_data.world_position
	_enable_cell_editing(active_cell, EditorInterface.get_edited_scene_root())
	print("done enabling")

func _on_load_pressed():
	if coordinates not in anchor.cell_registry.cells:
		push_warning("no cell exists at the coordinates: %v, create new cell instead" % coordinates)
		return

	_clear()

	var data = anchor.cell_registry.cells[coordinates]
	var scene = load(data.scene_path)
	if scene:
		var cell = scene.instantiate()
		active_cell = cell

		var root = EditorInterface.get_edited_scene_root()
		print("cell loaded at %v: %s" % [coordinates, data.cell_name])
		root.add_child(cell)
		cell.global_position = anchor.global_position
		_enable_cell_editing(cell, root)

func _on_create_pressed() -> void:
	if coordinates in anchor.cell_registry.cells:
		push_warning("cell already exists at the coordinates: %v, load cell instead" % coordinates)
		return

	_clear()

	var cell_data = CellData.new()
	cell_data.coordinates = coordinates
	cell_data.cell_name = "cell_%d_%d_%d" % [coordinates.x, coordinates.y, coordinates.z]
	cell_data.scene_path = anchor.cell_registry.cell_directory + cell_data.cell_name + ".tscn"
	cell_data.world_position = anchor.global_position
	anchor.cell_registry.cells[coordinates] = cell_data

	var cell_scene = load(anchor.cell_registry.base_cell_scene_path)
	var cell = cell_scene.instantiate()
	active_cell = cell
	var root = EditorInterface.get_edited_scene_root()
	print("cell created at %v with name: %s" % [coordinates, cell_data.cell_name])
	root.add_child(cell)
	cell.global_position = anchor.global_position

	_save_active_cell()
	active_cell.owner = root

func _coordinates_updated(value : float, index : int):
	match(index):
		0: coordinates.x = value
		1: coordinates.y = value
		2: coordinates.z = value

	init()
	_update_cursor()

func cell_to_world_space(_coords : Vector3i, _cell_size : int) -> Vector3:
	return Vector3(
		_coords.x * _cell_size,
		_coords.y * _cell_size,
		_coords.z * _cell_size
	)

func world_to_cell_space(_pos : Vector3, _grid_size : Vector3i) -> Vector3i:
	return Vector3i(
		floor(_pos.x / _grid_size.x),
		floor(_pos.y / _grid_size.y),
		floor(_pos.z / _grid_size.z)
	)

func _update_cursor():
	anchor.global_position = cell_to_world_space(coordinates, anchor.cell_registry.cell_size)

func _on_clear_pressed() -> void:
	_clear()

func _enable_cell_editing(cell : Node, root : Node):
	cell.owner = root
	cell.scene_file_path = ""
	_set_owner_recursive_safe(cell, root)

func _set_owner_recursive_safe(node: Node, owner: Node):
	# If this node is a scene instance, skip it and its subtree
	if node.scene_file_path != "":
		node.owner = owner
		return

	if node != owner:
		node.owner = owner

	for child in node.get_children():
		if child is Node:
			_set_owner_recursive_safe(child, owner)

func _clear():
	if active_cell != null && is_instance_valid(active_cell):
		active_cell.free()

	active_cell = null

	var root = EditorInterface.get_edited_scene_root()
	for child in root.get_children():
		if child is Cell:
			child.queue_free()
