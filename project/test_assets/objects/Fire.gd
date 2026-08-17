extends Node3D

@onready var fire = $Fire

func shrink():
	fire.amount -= 3
	fire.process_material.scale_min -= .8
