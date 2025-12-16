@tool
extends EditorPlugin


var dock

func _enter_tree() -> void:
	dock = preload("res://addons/cellblock/cellblock_editor.tscn").instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_INSPECTOR_BOTTOM, dock)
	dock.visible = false
	dock.plugin = self
	if not ProjectSettings.has_setting("autoload/" + "CellManager"):
		add_autoload_singleton("CellManager", "res://addons/cellblock/autoload/cell_manager.gd")
	if not ProjectSettings.has_setting("autoload/" + "CellblockLogger"):
		add_autoload_singleton("CellblockLogger", "res://addons/cellblock/autoload/cellblock_logger.gd")

func _exit_tree() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_INSPECTOR_BOTTOM, dock)
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
		dock.visible = true
		dock.anchor = object
		dock.init()
		dock.on_update()
	else:
		dock.visible = false

func _make_visible(visible : bool):
	dock.visible = visible
