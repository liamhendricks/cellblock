@tool
extends EditorScript

# this script is for testing purposes, just fills the grid with a bunch of simple cell scenes

var registry_resource_path : String = "res://addons/cellblock/resources/cell_registry_example_far.tres"
#var registry_resource_path : String = "res://addons/cellblock/resources/cell_registry_example_near.tres"

var high_end_scale : int = 3
var ball = load("res://MutableObjectExample.tscn")
var block = load("res://StaticObjectExample2.tscn")

func _run() -> void:
	var cell_registry = load(registry_resource_path)
	create_cell_scenes_in_grid(cell_registry)

func create_cell_scenes_in_grid(cell_registry : CellRegistry):
	print("creating cells...")
	for x in range(-floor((cell_registry.grid_size.x / cell_registry.cell_size) / 2), floor((cell_registry.grid_size.x / cell_registry.cell_size) / 2) + 1):
		for y in range(-floor((cell_registry.grid_size.y / cell_registry.cell_size) / 2), floor((cell_registry.grid_size.y / cell_registry.cell_size) / 2) + 1):
			for z in range(-floor((cell_registry.grid_size.z / cell_registry.cell_size) / 2), floor((cell_registry.grid_size.z / cell_registry.cell_size) / 2) + 1):
				var coords := Vector3i(x, y, z)
				var cell_data = CellData.new()
				cell_data.coordinates = coords
				cell_data.cell_name = "cell_%d_%d_%d" % [coords.x, coords.y, coords.z]
				cell_data.scene_path = cell_registry.cell_directory + cell_data.cell_name + ".tscn"
				cell_data.world_position = cell_to_world_space(coords, cell_registry.cell_size)
				cell_registry.set_cell(cell_data.coordinates, cell_data)
				ResourceSaver.save(cell_registry)

				var cell_scene = load(cell_registry.base_cell_scene_path)
				var instance = cell_scene.instantiate()
				var root = EditorInterface.get_edited_scene_root()
				root.add_child(instance)
				var bi = ball.instantiate()
				instance.get_node("Objects").add_child(bi)
				_randomize_ball(bi)
				var bbi = block.instantiate()
				instance.get_node("Statics").add_child(bbi)
				_randomize_block(bbi)

				_set_owner(bi, instance)
				_set_owner(bbi, instance)

				var scene = PackedScene.new()
				scene.pack(instance)
				ResourceSaver.save(scene, cell_data.scene_path)
				root.remove_child(instance)
				instance.free()
				print("created demo cell: %v" % coords)

func _randomize_block(block : StaticBody3D) -> void:
	block.name = "block"
	var scale = randi_range(1, high_end_scale)
	block.global_scale(Vector3(scale, scale, scale))

func _randomize_ball(ball : RigidBody3D) -> void:
	ball.name = "ball"
	var x = randi_range(1, 4)
	var z = randi_range(1, 4)
	ball.global_position.x = x
	ball.global_position.z = z
	ball.global_position.y = 2

func _set_owner(node : Node, owner : Node):
	node.owner = owner
	for child in owner.get_children():
		child.owner = owner

func cell_to_world_space(_coords : Vector3i, _cell_size : int) -> Vector3:
	return Vector3(
		_coords.x * _cell_size,
		_coords.y * _cell_size,
		_coords.z * _cell_size
	)
