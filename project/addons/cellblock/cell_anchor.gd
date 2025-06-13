class_name CellAnchor
extends Node3D

signal anchor_exited()

@export var cell_registries : Array[CellRegistry]
@export var cell_save : CellSave

func _exit_tree() -> void:
	emit_signal("anchor_exited")
