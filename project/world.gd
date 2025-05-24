class_name World
extends Node3D

@onready var player = $Player
@onready var cell_anchor = $CellAnchor

func _ready():
	CellManager.start(player, self, cell_anchor)
