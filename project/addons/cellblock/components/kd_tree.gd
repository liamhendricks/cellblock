class_name KDTree
extends RefCounted

# Used by Cellblock for efficient scanning of Vector3i keys in a radius.

var root : KDTreeNode
var counter : int
var last_counter : int
var fn_counter : int

func from_points(points : Array):
	counter = 0
	root = build(points)
	print("DONE ", counter)

func build(points : Array, depth : int = 0) -> KDTreeNode:
	counter += 1
	if points.is_empty():
		return null

	var axis = depth % 3
	points.sort_custom(func(a, b): return a[axis] < b[axis])
	var median = points.size() / 2

	var node = KDTreeNode.new(points[median], axis)
	node.left = build(points.slice(0, median), depth + 1)
	node.right = build(points.slice(median + 1, points.size()), depth + 1)

	return node

# return all points within max_dist
func radius_search(target : Vector3i, max_dist : float) -> Array:
	counter = 0
	var results : Array = []
	_radius_search(root, target, max_dist, results)

	return results

func _radius_search(node : KDTreeNode, target : Vector3i, max_dist : float, results : Array, depth : int = 0):
	counter += 1
	if node == null:
		return

	var axis = node.axis
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
	fn_counter = 0
	var best = {"point": null, "dist": INF}
	_find_closest(root, target, best)
	last_counter = fn_counter
	return best.point

func _find_closest(node: KDTreeNode, target: Vector3i, best: Dictionary, depth: int = 0) -> void:
	fn_counter += 1
	if node == null:
		return

	var axis = node.axis
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
