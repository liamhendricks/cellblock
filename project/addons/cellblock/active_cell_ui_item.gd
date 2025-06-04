@tool
extends HBoxContainer

@onready var cell_name_label = $Label
@onready var cell_registry_label = $Label2
@onready var save = $Save
@onready var clear = $Clear

func configure(_cell_name : String, _registry_name : String, _on_save : Callable, _on_clear : Callable):
	cell_name_label.text = _cell_name
	cell_registry_label.text = _registry_name
	save.pressed.connect(_on_save)
	clear.pressed.connect(_on_clear)
