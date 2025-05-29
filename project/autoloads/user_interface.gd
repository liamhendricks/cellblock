extends CanvasLayer

@onready var fps_label = $GameInterface/PanelContainer/MarginContainer/VBoxContainer/FPSLabel
@onready var active_cells_label = $GameInterface/PanelContainer/MarginContainer/VBoxContainer/ActiveCellsLabel

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
	var t : Array[String]
	var count = 0
	for loader in CellManager.cell_loaders:
		t.append("Active Cells for Registry #%d: %d" % [count, len(loader.get_active_cells())])
		count += 1

	active_cells_label.text = ""
	active_cells_label.text = "\n".join(t)
