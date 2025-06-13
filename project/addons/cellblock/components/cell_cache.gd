class_name CellCache
extends RefCounted

var capacity : int
var data : Dictionary[Vector3i, Cell] = {}

func _init(_capacity : int) -> void:
	capacity = _capacity

func add(_key : Vector3i, _val : Cell) -> void:
	if data.size() >= capacity:
		_evict()

	data[_key] = _val

func pull(_key : Vector3i) -> Cell:
	if !exists(_key):
		return null

	var cell : Cell = data[_key]
	data.erase(_key)
	return cell

func exists(_key : Vector3i):
	return _key in data

# TODO: probably better to refactor this to return an evicted cell and let the
# caller decide what to do with it, rather than queue_free here.
func _evict() -> void:
	var key = data.keys().front()
	var cell : Cell = data[key]
	cell.queue_free()
	data.erase(key)

func clear():
	for k in data.keys():
		var cell = data[k]
		cell.free()

	data.clear()
