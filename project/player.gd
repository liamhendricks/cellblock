extends CharacterBody3D
class_name Player

#basic character controller for demo purposes
@onready var camera_pivot = $CameraPivot

@export var speed = 5.0
@export var acceleration = 4.0
@export var jump_speed = 8.0
@export var mouse_sensitivity = 0.0015
@export var rotation_speed = 12.0
@export var force = 5.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var jumping = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	velocity.y += -gravity * delta
	get_move_input(delta)

	move_and_slide()

	# for knocking around the mutable objects
	for slide in get_slide_collision_count():
		var collision = get_slide_collision(slide)
		var collider = collision.get_collider()
		var normal = collision.get_normal()
		if !collider.is_class("RigidBody3D"):
			continue

		var i = -normal * force
		collider.apply_central_impulse(i)

func get_move_input(delta):
	var vy = velocity.y
	velocity.y = 0
	var input = Input.get_vector("left", "right", "forward", "back")
	var dir = Vector3(input.x, 0, input.y).rotated(Vector3.UP, camera_pivot.rotation.y)
	velocity = lerp(velocity, dir * speed, acceleration * delta)
	velocity.y = vy

func _unhandled_input(event):
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MouseMode.MOUSE_MODE_CAPTURED:
		camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity
		camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, -90.0, 30.0)
		camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity

	if Input.is_action_just_pressed("quit"):
		if Input.mouse_mode == Input.MouseMode.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if Input.is_action_just_pressed("save"):
		CellManager.save_cells()
		return
