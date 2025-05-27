@tool
extends EditorScript

# this script is for testing purposes, just fills the grid with a bunch of simple cell scenes

var registry_resource_path : String = "res://addons/cellblock/resources/example_cell_registry.tres"

func _run() -> void:
	var cell_registry = load(registry_resource_path)
	cell_registry.cells.clear()
