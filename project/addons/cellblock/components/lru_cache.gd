class_name LruCache
extends RefCounted

# Least Recently Used Cache for cells.

var capacity : int
var data : Dictionary[String, Cell] = {}
var queue : Array = []

func _init(_capacity : int) -> void:
	capacity = _capacity

func add(val, key) -> Cell:
	if data.size() > capacity:
		return evict()
	data[key] = val
	queue.push_front(key)

	return null

func exists(key):
	return key in data

func evict() -> Cell:
	var key = queue.pop_back()
	var cell : Cell = data[key]
	data.erase(key)
	return cell
