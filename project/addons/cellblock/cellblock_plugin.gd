@tool
extends EditorPlugin

const AUTOLOAD_NAME = "CellManager"

var dock

func _enter_tree() -> void:
	dock = preload("res://addons/cellblock/cellblock_editor.tscn").instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_INSPECTOR_BOTTOM, dock)
	dock.visible = false
	dock.plugin = self

func _exit_tree() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_INSPECTOR_BOTTOM, dock)
	dock.queue_free()

func _enable_plugin():
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/cellblock/autoload/cell_manager.gd")

func _disable_plugin():
	remove_autoload_singleton(AUTOLOAD_NAME)

func _handles(object):
	return object is CellLoader

func _edit(object):
	if object is CellLoader:
		dock.visible = true
		dock.loader = object
		dock.init()
	else:
		dock.visible = false

func _make_visible(visible : bool):
	dock.visible = visible
