class_name KDTree
extends RefCounted

# Used by Cellblock for efficient scanning of nearest Vector3i keys.

var root : KDTreeNode

func build(points : Array, depth: int = 0) -> KDTreeNode:
	if points.is_empty():
		return null

	var axis = depth % 3
	points.sort_custom(func(a, b): return a[axis] < b[axis])
	var median = points.size() / 2

	var node = KDTreeNode.new(points[median], axis)
	node.left = build(points.slice(0, median), depth + 1)
	node.right = build(points.slice(median + 1, points.size()), depth + 1)
	return node

func from_points(points : Array):
	root = build(points)

func find_nearest(target : Vector3i, k : int, max_dist : float = 10.0) -> Array:
	var heap: Array = []
	_find_nearest(root, target, k, 10.0, heap)
	heap.sort_custom(func(a, b): return a["dist"] < b["dist"])
	return heap.slice(0, k).map(func(entry): return entry["point"])

func _find_nearest(node, target: Vector3i, k: int, max_dist: float, heap: Array, depth: int = 0):
	if node == null:
		return

	var axis = depth % 3
	var dist = node.point.distance_to(target)

	# only consider points smaller than the max_dist
	if dist <= max_dist:
		heap.append({ "point": node.point, "dist": dist })
		heap.sort_custom(func(a, b): return a["dist"] < b["dist"])
		if heap.size() > k:
			heap.resize(k)

	var diff = target[axis] - node.point[axis]

	var near
	var far
	if diff < 0:
		near = node.left
		far = node.right
	else:
		near = node.right
		far = node.left

	_find_nearest(near, target, k, max_dist, heap, depth + 1)

	# Only search the other side if it's possible it contains valid candidates
	if heap.size() < k or abs(diff) <= max_dist:
		_find_nearest(far, target, k, max_dist, heap, depth + 1)
