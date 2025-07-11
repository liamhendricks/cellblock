@tool
class_name ActiveCellUiItem
extends HBoxContainer

@onready var label = $Label
@onready var save = $Save
@onready var clear = $Clear
@onready var delete = $Delete

var cell_index : int

func configure(_cell_data : CellData, _registry_idx : int, _cell_idx : int, _on_save : Callable, _on_clear : Callable, _on_delete : Callable):
	var tt_text = "grid coordinates: (%d, %d, %d) registry idx: %d" % [_cell_data.coordinates.x,  _cell_data.coordinates.y,  _cell_data.coordinates.z, _registry_idx]
	label.text = _cell_data.cell_name
	tooltip_text = tt_text
	cell_index = _cell_idx
	save.pressed.connect(_on_save.bind(self))
	clear.pressed.connect(_on_clear.bind(self))
	delete.pressed.connect(_on_delete.bind(self))
