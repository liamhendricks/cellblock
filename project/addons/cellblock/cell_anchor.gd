class_name CellAnchor
extends Node3D

signal anchor_exited()

@export var cell_registries : Array[CellRegistry]
@export var cell_save : CellSave
@export var log_level : CellblockLogger.LOG_LEVELS = CellblockLogger.LOG_LEVELS.ERROR

func _exit_tree() -> void:
	emit_signal("anchor_exited")
