extends Node

signal manager_started()

# this is the node to do distance checks from, normally the player, or a camera
var origin_object : Node3D = null

var current_processor_index : int = 0
var cell_save : CellSave
var cell_processors : Array[CellProcessor]
var procs_loaded : Dictionary
var loaded : bool = false

func _ready() -> void:
	loaded = false
	set_process(false)
	current_processor_index = 0
	CellblockLogger.init(CellblockLogger.LOG_LEVELS.DEBUG)

func set_origin_object(_origin_object : Node3D) -> void:
	origin_object = _origin_object

# entrypoint to start the cell_manager
# await start(...) and you will have all mutable objects instantiated in the scene on first load
func start(_origin_object : Node3D, _world : Node3D, _anchor : CellAnchor) -> void:
	current_processor_index = 0
	origin_object = _origin_object
	var cell_registries = _anchor.cell_registries

	if _anchor.cell_save == null:
		CellblockLogger.error("cell_save is null")
		return

	cell_save = _anchor.cell_save

	var count = 0
	for registry : CellRegistry in cell_registries:
		var loader = _get_loader(_world, registry)
		var processor = CellProcessor.new(registry, loader, "%d" % count)
		cell_processors.append(processor)
		if  registry == null || origin_object == null || loader == null:
			CellblockLogger.error("cell_manager not started correctly, please review the docs if any below are null")
			CellblockLogger.error("cell_registry: %s" % registry)
			CellblockLogger.error("origin_object: %s" % origin_object)
			CellblockLogger.error("cell_loader: %s" % loader)
			return

		add_child(loader)
		loader.configure(registry, cell_save)
		count += 1

	_anchor.anchor_exited.connect(_on_anchor_exited)

	await _initial_load()

	set_process(true)
	emit_signal("manager_started")
	CellblockLogger.info("cell_manager started")

func _initial_load():
	#load everything
	for proc in cell_processors:
		var total_in_range = await proc.work_all_cells(origin_object)
		if total_in_range > 0:
			await proc.loaded_all_cells_init
			proc.current_loaded_cells_for_init = 0
			proc.total_loaded_cells_for_init = 0
		CellblockLogger.info("done configuring cell_processor")

func _get_loader(_world : Node3D, _registry : CellRegistry) -> CellLoader:
	match(_registry.load_strategy):
		CellRegistry.LOAD_STRATEGY.IN_MEMORY_VISUAL: return CellLoaderInMemoryVisual.new(_world, _registry.max_cache_size)
		CellRegistry.LOAD_STRATEGY.IN_MEMORY_REMOVE: return CellLoaderInMemoryRemove.new(_world, _registry.max_cache_size)
		CellRegistry.LOAD_STRATEGY.ASYNC_LOAD: return CellLoaderAsync.new(_world, _registry.max_cache_size)
	return null

func stop() -> void:
	loaded = false
	set_process(false)
	for proc in cell_processors:
		proc.on_exit()
		proc.cell_loader.queue_free()

	cell_processors.clear()

func _process(_delta) -> void:
	work()

func work():
	if origin_object == null || len(cell_processors) == 0:
		return

	cell_processors[current_processor_index]._work(origin_object)
	current_processor_index += 1
	if current_processor_index > len(cell_processors) - 1:
		current_processor_index = 0

func cell_to_world_space(_coords : Vector3i, _cell_size : int) -> Vector3:
	return Vector3(
		_coords.x * _cell_size,
		_coords.y * _cell_size,
		_coords.z * _cell_size
	)

func world_to_cell_space(_pos : Vector3, _cell_size : int) -> Vector3i:
	return Vector3i(
		round(_pos.x / _cell_size),
		round(_pos.y / _cell_size),
		round(_pos.z / _cell_size)
	)

func save_cells():
	var save_data : Dictionary = {}
	for p in cell_processors:
		save_data.merge(p.get_cell_save_data())

	cell_save.write_save(save_data)

func _on_anchor_exited():
	pass
