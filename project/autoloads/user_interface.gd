extends CanvasLayer

@onready var fps_label = $GameInterface/PanelContainer/MarginContainer/VBoxContainer/FPSLabel

func _on_save_button_pressed() -> void:
	CellManager.save_cells()

func _process(_delta) -> void:
	fps_label.text = "FPS: %s" % Engine.get_frames_per_second()
