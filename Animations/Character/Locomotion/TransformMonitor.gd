extends Node

var tracked_owner: CharacterBody3D
var anim_tree: AnimationTree
var last_yaw: float = 0.0

# Smoothed values
var smoothed_forward: float = 0.0
var smoothed_right: float = 0.0

# Floor collision flag
var airborne: bool = false

# Interpolated yaw blend
var yaw_blend: float = 0.0

const IDLE_RUNNING := "parameters/IdleRunning/blend_position"
const IDLE_WALKING := "parameters/IdleWalking/blend_position"
const IDLE_STANDING := "parameters/IdleStanding/blend_position"
const AIRBORNE_PARAM := "parameters/conditions/airborne"
const TRANSITION_PARAM := "parameters/MovementType/transition_request"   # Transition node request
const MOVEMENT_ANIM_SPEED := "parameters/MovementAnimSpeed/scale"        # New anim speed parameter

const LERP_SPEED := 10.0
const ANGULAR_SCALE := 30.0
const YAW_BLEND_SPEED := 10.0

func _ready() -> void:
	tracked_owner = get_parent() as CharacterBody3D
	if tracked_owner == null:
		tracked_owner = get_tree().get_root().find_child("Player", true, false) as CharacterBody3D
	if tracked_owner == null:
		push_warning("TransformMonitor: Could not auto-assign tracked_owner!")

	if tracked_owner:
		anim_tree = tracked_owner.find_child("AnimationTree", true, false) as AnimationTree
	if anim_tree == null:
		push_warning("TransformMonitor: Could not auto-assign AnimationTree!")
	else:
		anim_tree.active = true

func _process(delta: float) -> void:
	if tracked_owner == null:
		return

	var vel = tracked_owner.velocity
	var basis = tracked_owner.global_transform.basis

	var forward = -basis.z.normalized()
	var right = basis.x.normalized()

	var forward_speed = vel.dot(forward)
	var right_speed = vel.dot(right)

	# Smooth interpolation for movement speeds
	smoothed_forward = lerp(smoothed_forward, forward_speed, LERP_SPEED * delta)
	smoothed_right = lerp(smoothed_right, right_speed, LERP_SPEED * delta)

	# Angular velocity (yaw)
	var current_yaw = tracked_owner.rotation.y
	var yaw_diff = angle_difference(last_yaw, current_yaw)
	var yaw_speed = yaw_diff / delta
	var yaw_speed_deg = rad_to_deg(yaw_speed)

	last_yaw = current_yaw

	# Floor collision check
	airborne = not tracked_owner.is_on_floor()

	if anim_tree:
		var blend_vec = Vector2(smoothed_right, smoothed_forward)
		anim_tree.set(IDLE_RUNNING, blend_vec)
		anim_tree.set(IDLE_WALKING, blend_vec)

		anim_tree.set(AIRBORNE_PARAM, airborne)

		# Interpolated yaw blend → IdleStanding
		var target_yaw_blend = clamp(yaw_speed_deg / ANGULAR_SCALE, -3.0, 3.0)
		yaw_blend = lerp(yaw_blend, target_yaw_blend, YAW_BLEND_SPEED * delta)
		anim_tree.set(IDLE_STANDING, yaw_blend)

		# --- Transition node logic ---
		var walk_speed = tracked_owner.walk_speed
		var current_speed = vel.length()

		var state: String
		if abs(smoothed_forward) <= 0.01 and abs(smoothed_right) <= 0.01:
			state = "Idle"
		elif current_speed <= walk_speed + 0.1:
			state = "Walking"
		else:
			state = "Running"

		anim_tree.set(TRANSITION_PARAM, state)

		# MovementAnimSpeed proportional to current speed / walk_speed, divided by 2, clamp min 1
		var scale_val = (current_speed / walk_speed) / 2.0
		scale_val = max(scale_val, 1.0)
		anim_tree.set(MOVEMENT_ANIM_SPEED, scale_val)

		# Debug print
		var msg = "Forward: %.2f, Right: %.2f, Speed: %.2f | YawVel: %.2f deg/s | Airborne: %s | BlendVec: %s | YawBlend: %.2f | State: %s | AnimSpeed: %.2f" % [
			smoothed_forward, smoothed_right, current_speed, yaw_speed_deg, str(airborne),
			str(blend_vec), yaw_blend, state, scale_val
		]
		print(msg)

		var label := get_node_or_null("Label")
		if label:
			label.text = msg
