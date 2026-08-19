extends Node
class_name CellInstantiationWorker

# we can run cell scene instantiation in a separate thread

var thread: Thread
var mu: Mutex
var sem: Semaphore
var exit_thread: bool = false
var scenes_to_work: Dictionary[int, PackedScene]
var done_scenes: Dictionary[int, Node]
var key_counter: int = 0

func _ready() -> void:
	thread = Thread.new()
	mu = Mutex.new()
	sem = Semaphore.new()
	exit_thread = false
	key_counter = 0
	var res := thread.start(_worker)
	if res != 0:
		CellblockLogger.error("error starting instantiation worker thread")
		return

func enqueue(scene: PackedScene, key: int) -> void:
	mu.lock()
	if key in scenes_to_work:
		CellblockLogger.error("requested duplicate key")
		mu.unlock()
		return

	scenes_to_work[key] = scene
	mu.unlock()
	sem.post()

func _worker() -> void:
	while true:
		sem.wait()
		mu.lock()
		var l := len(scenes_to_work.keys())
		var should_exit = exit_thread
		mu.unlock()
		if should_exit:
			break

		if l > 0:
			mu.lock()
			var k := scenes_to_work.keys().front()
			var scene := scenes_to_work[k]
			mu.unlock()
			var node = scene.instantiate()
			mu.lock()
			done_scenes[k] = node
			scenes_to_work.erase(k)
			mu.unlock()

func get_done_node(k: int) -> Node:
	mu.lock()
	if k in done_scenes.keys():
		var n := done_scenes[k]
		done_scenes.erase(k)
		mu.unlock()
		return n

	mu.unlock()
	return null

func request_key() -> int:
	key_counter += 1
	return key_counter

func _exit_tree() -> void:
	mu.lock()
	exit_thread = true
	mu.unlock()
	sem.post()
	thread.wait_to_finish()
	for k in done_scenes.keys():
		var s := done_scenes[k]
		s.free()
