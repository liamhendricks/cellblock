@tool
extends EditorScript

# this script is for testing purposes, a helper to edit values across cell data entries

var registry_resource_path : String = "res://addons/cellblock/resources/cell_registry_example_near.tres"

func _run() -> void:
	var cell_registry = load(registry_resource_path)
	alter_cell_data(cell_registry)

func alter_cell_data(cell_registry : CellRegistry):
	for k in cell_registry.cells.keys():
		var cd : CellData = cell_registry.cells[k]
		cd.distance_to_origin = 200.0
