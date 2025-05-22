@tool
extends Control

@onready var x = $PanelContainer/MarginContainer/VBoxContainer/XSpin
@onready var y = $PanelContainer/MarginContainer/VBoxContainer/YSpin
@onready var z = $PanelContainer/MarginContainer/VBoxContainer/ZSpin
@onready var container = $PanelContainer/MarginContainer/VBoxContainer

var active_cell : Cell
var coordinates : Vector3i
var loader : CellLoader
var plugin : EditorPlugin

func _ready():
	init()

func init():
	coordinates = Vector3i(x.value, y.value, z.value)
	if loader != null && loader.cell_registry != null:
		x.min_value = floor(-(loader.cell_registry.grid_size.x / 2) / loader.cell_registry.cell_size)
		y.min_value = floor(-(loader.cell_registry.grid_size.y / 2) / loader.cell_registry.cell_size)
		z.min_value = floor(-(loader.cell_registry.grid_size.z / 2) / loader.cell_registry.cell_size)
		x.max_value = floor((loader.cell_registry.grid_size.x / 2) / loader.cell_registry.cell_size)
		y.max_value = floor((loader.cell_registry.grid_size.y / 2) / loader.cell_registry.cell_size)
		z.max_value = floor((loader.cell_registry.grid_size.z / 2) / loader.cell_registry.cell_size)

	if !x.value_changed.is_connected(_coordinates_updated.bind(0)):
		x.value_changed.connect(_coordinates_updated.bind(0))
	if !y.value_changed.is_connected(_coordinates_updated.bind(1)):
		y.value_changed.connect(_coordinates_updated.bind(1))
	if !z.value_changed.is_connected(_coordinates_updated.bind(2)):
		z.value_changed.connect(_coordinates_updated.bind(2))

func _on_save_pressed():
	var cell_data = loader.cell_registry.cells[coordinates]
	cell_data.world_position = active_cell.global_position
	ResourceSaver.save(cell_data)

	_set_owner_recursive(active_cell, active_cell)
	var scene = PackedScene.new()
	scene.pack(active_cell)
	ResourceSaver.save(scene, cell_data.scene_path)

	# now that the scene is saved, we can make the cell editable again
	_enable_cell_editing(active_cell, EditorInterface.get_edited_scene_root())

func _on_load_pressed():
	if coordinates not in loader.cell_registry.cells:
		push_warning("no cell exists at the coordinates: %v, create new cell instead" % coordinates)
		return

	_clear()

	var data = loader.cell_registry.cells[coordinates]
	var scene = load(data.scene_path)
	if scene:
		var cell = scene.instantiate()
		active_cell = cell

		var root = EditorInterface.get_edited_scene_root()
		print("cell loaded: ", cell)
		root.add_child(cell)
		cell.global_position = loader.global_position
		_enable_cell_editing(cell, root)

func _set_owner_recursive(node: Node, owner: Node):
	if node.name == owner.name:
		node.owner = null
	else:
		node.owner = owner

	for child in node.get_children():
		if child is Node:
			_set_owner_recursive(child, owner)

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
	loader.global_position = cell_to_world_space(coordinates, loader.cell_registry.cell_size)

func _on_clear_pressed() -> void:
	_clear()

func _enable_cell_editing(cell : Node, root : Node):
	_set_owner_recursive(cell, root)
	cell.scene_file_path = ""

func _clear():
	if active_cell != null && is_instance_valid(active_cell):
		active_cell.free()

	active_cell = null

	var root = EditorInterface.get_edited_scene_root()
	for child in root.get_children():
		if child is Cell:
			child.queue_free()
