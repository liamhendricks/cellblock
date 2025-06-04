@tool
class_name ActiveCellUiItem
extends HBoxContainer

@onready var cell_name_label = $Label
@onready var cell_registry_label = $Label2
@onready var save = $Save
@onready var clear = $Clear

var cell_data : CellData
var registry_index : int
var cell_index : int

func configure(_cell_data : CellData, _registry_idx : int, _cell_idx : int, _on_save : Callable, _on_clear : Callable):
	cell_name_label.text = _cell_data.cell_name
	cell_registry_label.text = "%d" % _registry_idx
	cell_data = _cell_data
	registry_index = _registry_idx
	cell_index = _cell_idx
	save.pressed.connect(_on_save.bind(self))
	clear.pressed.connect(_on_clear.bind(self))
