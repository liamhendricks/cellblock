class_name World
extends Node3D

@onready var player = $Player
@onready var cell_anchor : CellAnchor = $CellAnchor

func _ready():
	# here is where you would create your cell save, or update it's filepath.
	cell_anchor.cell_save.save_file_name = "user://savegame.save"
	CellManager.start(player, self, cell_anchor)
