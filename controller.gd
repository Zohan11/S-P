extends Node

@export var mouse_sensitivity: float = 0.2
@export var max_pitch: float = 80.0
@export var camera_smoothness: float = 10.0
@export var follow_speed: float = 0.3

var player_ref: CharacterBody3D
var pivot_ref: Marker3D
var camera_ref: Camera3D

var raw_yaw: float = 0.0
var raw_pitch: float = 0.0
var smoothed_yaw: float = 0.0
var smoothed_pitch: float = 0.0

func _ready() -> void:
	# Auto-assign references
	player_ref = get_parent() as CharacterBody3D
	pivot_ref = $CameraPivot
	camera_ref = $CameraPivot/Camera3D

	# Hide and capture mouse for gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and player_ref:
		# Update raw yaw/pitch from mouse input
		raw_yaw -= event.relative.x * mouse_sensitivity * 0.01
		raw_pitch = clamp(
			raw_pitch - event.relative.y * mouse_sensitivity * 0.01,
			deg_to_rad(-max_pitch),
			deg_to_rad(max_pitch)
		)

		# Pass raw values to Player (stable targets)
		player_ref.target_yaw = raw_yaw
		player_ref.target_pitch = raw_pitch

	# Jump input
	if event.is_action_pressed("jump"):
		player_ref.jump_requested = true

func _process(delta: float) -> void:
	if not player_ref or not pivot_ref:
		return

	# Movement input
	var input_dir = Vector3.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	player_ref.input_dir = input_dir.normalized()
	player_ref.is_running = Input.is_action_pressed("run")

	pivot_ref.rotation.y = raw_yaw
	pivot_ref.rotation.x = raw_pitch

	# Smooth follow
	pivot_ref.global_position = player_ref.global_position


func toggle_mouse_mode() -> void:
	# Utility to toggle between captured and visible mouse (e.g. for menus)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
