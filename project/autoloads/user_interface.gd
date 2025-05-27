extends CanvasLayer

@onready var fps_label = $GameInterface/PanelContainer/MarginContainer/VBoxContainer/FPSLabel
@onready var tree_scans_label = $GameInterface/PanelContainer/MarginContainer/VBoxContainer/TreeScansLabel

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
	tree_scans_label.text = "Average KDTree Iters: %d" % CellManager.cell_data_tree.last_counter
