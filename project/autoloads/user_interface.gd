extends CanvasLayer

@onready var fps_label = $GameInterface/PanelContainer/MarginContainer/VBoxContainer/FPSLabel
@onready var nearest_cell_label = $GameInterface/PanelContainer/MarginContainer/VBoxContainer/NearestCellLabel
@onready var curren_coords_label = $GameInterface/PanelContainer/MarginContainer/VBoxContainer/CurrentCoordsLabel

func _on_save_button_pressed() -> void:
	CellManager.save_cells()

func _on_quit_button_pressed() -> void:
	quit_scene()

func quit_scene():
	var tree = get_tree()
	tree.root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	tree.call_deferred("quit")

func _on_pause_button_pressed() -> void:
	CellManager.stop()

func _process(_delta) -> void:
	fps_label.text = "FPS: %s" % Engine.get_frames_per_second()
	nearest_cell_label.text = "Nearest Cell: %v" % CellManager.current_cell_key
	curren_coords_label.text = "Current Coords: %v" % CellManager.current_cell_coords
