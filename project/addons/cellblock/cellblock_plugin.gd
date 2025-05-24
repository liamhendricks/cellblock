@tool
extends EditorPlugin

const AUTOLOAD_NAME = "CellManager"

var dock

func _enter_tree() -> void:
	dock = preload("res://addons/cellblock/cellblock_editor.tscn").instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_INSPECTOR_BOTTOM, dock)
	dock.visible = false
	dock.plugin = self
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, "res://addons/cellblock/autoload/cell_manager.gd")

func _exit_tree() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_INSPECTOR_BOTTOM, dock)
	dock.queue_free()
	if ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)

func _enable_plugin():
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/cellblock/autoload/cell_manager.gd")

func _disable_plugin():
	remove_autoload_singleton(AUTOLOAD_NAME)

func _handles(object):
	return object is CellAnchor

func _edit(object):
	if object is CellAnchor:
		dock.visible = true
		dock.anchor = object
		dock.init()
		dock._update_cursor()
	else:
		dock.visible = false

func _make_visible(visible : bool):
	dock.visible = visible
