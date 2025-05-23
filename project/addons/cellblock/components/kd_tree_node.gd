class_name KDTreeNode
extends RefCounted

var point: Vector3i
var axis: int
var left: KDTreeNode
var right: KDTreeNode

func _init(p_point: Vector3i, p_axis: int):
	point = p_point
	axis = p_axis
