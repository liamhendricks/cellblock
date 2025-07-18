extends CanvasLayer

@onready var fps_label = $GameInterface/PanelContainer/MarginContainer/VBoxContainer/FPSLabel
@onready var active_cells_label = $GameInterface/PanelContainer/MarginContainer/VBoxContainer/ActiveCellsLabel
@onready var coords_labels = $GameInterface/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer
@onready var ws_label = $GameInterface/PanelContainer/MarginContainer/VBoxContainer/WSLabel

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

func _ready():
	set_process(false)

func _on_manager_start():
	for k in CellManager.cell_processors.size():
		var r = CellManager.cell_processors[k].cell_registry
		var rlabel = Label.new()
		rlabel.text = "registry %d - coords: %s" % [k, _get_registry_coords(r, Vector3.ZERO)] 
		coords_labels.add_child(rlabel)

	set_process(true)

func _process(_delta) -> void:
	fps_label.text = "FPS: %s" % Engine.get_frames_per_second()
	var t : Array[String]
	for k in CellManager.cell_processors.size():
		var loader = CellManager.cell_processors[k].cell_loader
		t.append("Active Cells for Registry #%d: %d" % [k, len(loader.get_active_cells())])

	active_cells_label.text = ""
	active_cells_label.text = "\n".join(t)
	ws_label.text = "world space coords: (%d, %d, %d)" % [CellManager.origin_object.global_position.x, CellManager.origin_object.global_position.y, CellManager.origin_object.global_position.z]
	var count = 0
	for child in coords_labels.get_children():
		var r = CellManager.cell_processors[count].cell_registry
		child.text = "registry %d - coords: %s" % [count, _get_registry_coords(r, CellManager.origin_object.global_position)]
		count += 1

func _get_registry_coords(r : CellRegistry, ws : Vector3) -> String:
	var c = CellManager.world_to_cell_space(ws, r.cell_size)
	return "(%d, %d, %d)" % [c.x, c.y, c.z]
