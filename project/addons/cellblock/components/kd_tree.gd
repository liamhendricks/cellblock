class_name KDTree
extends RefCounted

# Used by Cellblock for efficient scanning of Vector3i keys in a radius.

var root : KDTreeNode

func from_points(points : Array):
	root = build(points)

func build(points : Array, depth : int = 0) -> KDTreeNode:
	if points.is_empty():
		return null

	var axis = _choose_axis(points)
	points.sort_custom(func(a, b): return a[axis] < b[axis])
	var median = points.size() / 2

	var node = KDTreeNode.new(points[median], axis)
	node.left = build(points.slice(0, median), depth + 1)
	node.right = build(points.slice(median + 1, points.size()), depth + 1)

	return node

# try to ensure kdtree is as balanced as possible
func _choose_axis(points: Array) -> int:
	var variances = [0.0, 0.0, 0.0]
	for i in range(3):
		var values = points.map(func(p): return p[i])
		var mean = values.reduce(func(a, b): return a + b) / values.size()
		var sum_sq = 0.0
		for v in values:
			sum_sq += (v - mean) * (v - mean)
		variances[i] = sum_sq

	var max_index := 0
	for i in range(1, 3):
		if variances[i] > variances[max_index]:
			max_index = i
	return max_index

# return all points within max_dist
func radius_search(target : Vector3i, max_dist : float) -> Array:
	var results : Array = []
	_radius_search(root, target, max_dist, results)
	return results

func _radius_search(node, target : Vector3i, max_dist : float, results : Array, depth : int = 0):
	if node == null:
		return

	var axis = depth % 3
	var dist = node.point.distance_to(target)

	if dist < max_dist:
		results.append(node.point)

	var diff = target[axis] - node.point[axis]

	var near
	var far
	if diff < 0:
		near = node.left
		far = node.right
	else:
		near = node.right
		far = node.left

	# always search the near subtree
	_radius_search(near, target, max_dist, results, depth + 1)

	# only search the far subtree if there's a chance it intersects the radius
	if abs(diff) <= max_dist:
		_radius_search(far, target, max_dist, results, depth + 1)

func find_closest_point(target: Vector3i) -> Vector3i:
	var best = {"point": null, "dist": INF}
	_find_closest(root, target, best)
	return best.point

func _find_closest(node: KDTreeNode, target: Vector3i, best: Dictionary, depth: int = 0) -> void:
	if node == null:
		return

	var axis = depth % 3
	var dist = node.point.distance_to(target)

	if dist < best.dist:
		best.point = node.point
		best.dist = dist

	var diff = target[axis] - node.point[axis]

	var near
	var far
	if diff < 0:
		near = node.left
		far = node.right
	else:
		near = node.right
		far = node.left

	# Search nearer subtree first
	_find_closest(near, target, best, depth + 1)

	# check farther side only if it's possible a closer point is there
	if abs(diff) < best.dist:
		_find_closest(far, target, best, depth + 1)
