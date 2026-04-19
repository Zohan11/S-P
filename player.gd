extends CharacterBody3D

@export var walk_speed: float = 1.6
@export var run_speed: float = 6.0
@export var gravity: float = 9.8
@export var jump_force: float = 5.0
@export var base_rotation_speed_deg: float = 560.0

@export var acceleration: float = 10.0
@export var deceleration: float = 20.0

@export var rotation_speed_regulator: float = 0.9
@export var camera_smoothness: float = 10.0
@export var strafe_penalty: float = 0.5
@export var backward_penalty: float = 0.5
@export var idle_rotation_threshold_deg: float = 60.0

var pitch: float = 0.0
var target_pitch: float = 0.0
var target_yaw: float = 0.0
var input_dir: Vector3 = Vector3.ZERO
var is_running: bool = false

var current_horizontal_velocity: Vector3 = Vector3.ZERO
var idle_rotation_active: bool = false   # flag to continue rotation once triggered

@onready var skeleton: Skeleton3D = $Skeleton3D
@onready var pivot_ghost: Node3D = $PivotGhost

func _physics_process(delta: float) -> void:
	# --- Running toggle ---
	var current_speed = run_speed if is_running else walk_speed

	# Orientation vectors from yaw only (camera basis)
	var yaw_only = Basis(Vector3.UP, target_yaw)
	var forward = -yaw_only.z
	var right = yaw_only.x

	# Desired velocity (camera aligned)
	var desired_velocity = (forward * input_dir.z + right * input_dir.x) * current_speed

	# --- Strafing/backward penalties based on Player facing ---
	if desired_velocity != Vector3.ZERO:
		var player_forward = -transform.basis.z.normalized()
		var player_right = transform.basis.x.normalized()

		var forward_component = desired_velocity.dot(player_forward)
		var right_component = desired_velocity.dot(player_right)

		if forward_component < 0.0:
			desired_velocity *= backward_penalty

		var forward_mag = abs(forward_component)
		var right_mag = abs(right_component)
		var total = forward_mag + right_mag
		if total > 0.0:
			var strafe_ratio = right_mag / total
			var penalty_factor = 1.0 - strafe_ratio * (1.0 - strafe_penalty)
			desired_velocity *= penalty_factor

	# --- Acceleration/deceleration ---
	if input_dir != Vector3.ZERO:
		var angle = rad_to_deg(current_horizontal_velocity.angle_to(desired_velocity))
		var blend = clamp(angle / 180.0, 0.0, 1.0)
		var effective_accel = lerp(acceleration, deceleration, blend)
		current_horizontal_velocity = current_horizontal_velocity.move_toward(desired_velocity, effective_accel * delta)
	else:
		current_horizontal_velocity = current_horizontal_velocity.move_toward(Vector3.ZERO, deceleration * delta)

	# --- Gravity/jump ---
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	velocity.x = current_horizontal_velocity.x
	velocity.z = current_horizontal_velocity.z

	move_and_slide()

	# --- Rotation speed scaling ---
	var speed_factor = current_horizontal_velocity.length()
	var adjusted_rotation_speed = base_rotation_speed_deg / (1.0 + rotation_speed_regulator * speed_factor)

	var current_yaw = rotation.y
	var diff = angle_difference(current_yaw, target_yaw)

	if speed_factor > 0.0:
		# Moving: scaled rotation speed
		idle_rotation_active = false
		var max_step = deg_to_rad(adjusted_rotation_speed) * delta
		if abs(diff) <= max_step:
			rotation.y = target_yaw
		else:
			rotation.y += sign(diff) * max_step
	else:
		# Idle: trigger rotation if threshold exceeded
		var diff_deg = rad_to_deg(abs(diff))
		if diff_deg > idle_rotation_threshold_deg:
			idle_rotation_active = true
		if idle_rotation_active:
			# Use base_rotation_speed_deg directly when idle
			var max_step_idle = deg_to_rad(base_rotation_speed_deg) * delta
			if abs(diff) <= max_step_idle:
				rotation.y = target_yaw
				idle_rotation_active = false   # finished aligning
			else:
				rotation.y += sign(diff) * max_step_idle

	# --- PivotGhost sync (always tracks) ---
	if pivot_ghost:
		pivot_ghost.global_position = global_position
		var yaw_basis = Basis(Vector3.UP, target_yaw)
		var pitch_basis = Basis(Vector3.RIGHT, target_pitch)
		pivot_ghost.global_rotation = (yaw_basis * pitch_basis).get_euler()
