@tool
extends EditorPlugin


var dock

func _enter_tree() -> void:
	dock = EditorDock.new()
	var dock_content = preload("res://addons/cellblock/cellblock_editor.tscn").instantiate()
	dock.add_child(dock_content)
	dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UL
	add_dock(dock)
	dock.visible = false
	if not ProjectSettings.has_setting("autoload/" + "CellManager"):
		add_autoload_singleton("CellManager", "res://addons/cellblock/autoload/cell_manager.gd")
	if not ProjectSettings.has_setting("autoload/" + "CellblockLogger"):
		add_autoload_singleton("CellblockLogger", "res://addons/cellblock/autoload/cellblock_logger.gd")

func _exit_tree() -> void:
	remove_dock(dock)
	dock.queue_free()
	if ProjectSettings.has_setting("autoload/" + "CellManager"):
		remove_autoload_singleton("CellManager")
	if ProjectSettings.has_setting("autoload/" + "CellblockLogger"):
		remove_autoload_singleton("CellblockLogger")

func _enable_plugin():
	add_autoload_singleton("CellManager", "res://addons/cellblock/autoload/cell_manager.gd")
	add_autoload_singleton("CellblockLogger", "res://addons/cellblock/autoload/cellblock_logger.gd")

func _disable_plugin():
	remove_autoload_singleton("CellManager")
	remove_autoload_singleton("CellblockLogger")

func _handles(object):
	return object is CellAnchor

func _edit(object):
	if object is CellAnchor:
		var editor = dock.get_node("CellblockEditor")
		editor.anchor = object
		editor.init()
		editor.on_update()

func _make_visible(visible : bool):
	dock.visible = visible
