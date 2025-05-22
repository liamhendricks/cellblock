class_name CellStack
extends RefCounted

# Wrapper around array with convenience methods for working through the data.
var data : Array[CellData] = []
var current : int = 0

func _push(_data : CellData):
	data.push_back(_data)

func _pop() -> CellData:
	return data.pop_back()

func _work(_pos : Vector3):
	var l = len(data)
	if l > 0:
		var cell_data : CellData = data[current]
		cell_data.work(_pos)
		current += 1
		if current >= l:
			current = 0

func _find(_cell : CellData) -> CellData:
	var i = data.find(_cell)
	if i != -1:
		return data[i]

	return null

func _find_closest_other(_pos : Vector3, _old : CellData) -> CellData:
	var closest_dist = 100
	var closest_cell = data[0]

	for cell in data:
		pass

	return closest_cell

func _find_closest(_pos : Vector3) -> CellData:
	var closest_dist = 100
	var closest_cell = data[0]

	for cell in data:
		pass

	return closest_cell
