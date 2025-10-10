extends CharacterBody3D
class_name Player

const MAX_HEALTH: int = 5
const SENS: float = 0.003
const SENS_JOY: float = 0.03
const SPEED: float = 7.0
const SPRINT_BOOST: float = 1.5
const SPRINT_MAX_ENERGY: float = 4.0
const SPRINT_RECHARGE_SPEED: float = 0.8
const SPRINT_RECHARGE_SPEED_HARD: float = 0.5
const JUMP: float = 5.0
const JUMP_QUEUE_FRAMES: int = 8
const ACCEL: float = 0.2
const ACCEL_AIR: float = 0.05
const DEFAULT_FOV: float = 75.0
const SCOPE_FOV: float = 45.0
const SCOPE_LOOK_SLOW: float = 0.5
const FOOTSTEP_TIME: float = 0.35
const FOOTSTEP_MIN_VOLUME: float = -7.5
const FOOTSTEP_MAX_VOLUME: float = 0.0
const FOOTSTEP_MIN_SOUND_STRENGTH: float = 0.1
const FOOTSTEP_MAX_SOUND_STRENGTH: float = 0.7

signal jumped
signal landed
signal movement_state_changed(old_state: MovementState, new_state: MovementState)
signal sprint_finished
signal sprint_exhausted
signal sprint_recharged
signal controller_input_changed(using_controller: bool)

enum MovementState {ON_FLOOR, ASCENDING, FALLING}


var current_movement_state: MovementState = MovementState.ON_FLOOR:
	set(value):
		var old_state := current_movement_state
		current_movement_state = value
		if old_state != current_movement_state:
			movement_state_changed.emit(old_state, current_movement_state)
			if current_movement_state == MovementState.ON_FLOOR:
				landed.emit()
				footstep(1.5)
				footstep_timer = FOOTSTEP_TIME
var sprint_energy: float = SPRINT_MAX_ENERGY:
	set(value):
		var value_changed := sprint_energy != value
		sprint_energy = clampf(value, 0.0, SPRINT_MAX_ENERGY)
		if value_changed:
			if sprint_energy == 0.0:
				sprint_recharging_hard = true
				sprint_finished.emit()
				sprint_exhausted.emit()
			elif sprint_energy == SPRINT_MAX_ENERGY:
				sprint_recharging_hard = false
				sprint_recharging = false
				sprint_recharged.emit()
var sprint_recharging := false
var sprint_recharging_hard := false
var sprint_speed_modifier: float = 1.0
var rot_h: float = 0.0
var rot_v: float = 0.0:
	set(value):
		rot_v = clampf(value, -PI/2.1, PI/2.1)
var footstep_timer: float = FOOTSTEP_TIME
var controller_input := false:
	set(value):
		if controller_input != value:
			controller_input = value
			controller_input_changed.emit(controller_input)
var jump_queue: int = 0


@onready var audio_stream_player_3d_footstep: AudioStreamPlayer3D = $AudioStreamPlayer3DFootstep
@onready var cam_h: Node3D = $CamH
@onready var camera_3d: Camera3D = $CamH/Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			var slow_factor: float = 1.0
			rot_h -= event.screen_relative.x * SENS * slow_factor
			rot_v -= event.screen_relative.y * SENS * slow_factor
	elif event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventJoypadMotion or InputEventJoypadButton:
		controller_input = true
	else:
		controller_input = false


func footstep(step_speed: float) -> void:
	audio_stream_player_3d_footstep.play()
	audio_stream_player_3d_footstep.volume_db = remap(step_speed,
														1.0,
														SPRINT_BOOST,
														FOOTSTEP_MIN_VOLUME,
														FOOTSTEP_MAX_VOLUME)
	audio_stream_player_3d_footstep.pitch_scale = randfn(1.0, 0.05)


func _physics_process(delta: float) -> void:
	if sprint_recharging_hard:
		sprint_energy += delta * SPRINT_RECHARGE_SPEED_HARD
	elif sprint_recharging:
		sprint_energy += delta * SPRINT_RECHARGE_SPEED

	var sprint_held := Input.is_action_pressed("sprint")

	if sprint_held and not sprint_recharging_hard:
		sprint_energy -= delta
		sprint_recharging = false
	elif sprint_energy < SPRINT_MAX_ENERGY:
		sprint_recharging = true

	if sprint_held and sprint_energy and not (sprint_recharging or sprint_recharging_hard):
		sprint_speed_modifier = lerpf(sprint_speed_modifier, SPRINT_BOOST, 0.2)
	else:
		sprint_speed_modifier = lerpf(sprint_speed_modifier, 1.0, 0.2)

	if sprint_energy and Input.is_action_just_released("sprint"):
		sprint_finished.emit()

	var joy_look := Input.get_vector(
								"joy_look_left",
								"joy_look_right",
								"joy_look_down",
								"joy_look_up"
								)

	if controller_input:
		var slow_factor: float = 1.0
		var y_invert := 1.0
		rot_h -= joy_look.x * slow_factor * SENS_JOY
		rot_v += joy_look.y * slow_factor * SENS_JOY

	cam_h.rotation.y = rot_h
	camera_3d.rotation.x = rot_v

	var input := Input.get_vector("left", "right", "fwd", "back")
	var direction := cam_h.global_basis * Vector3(input.x, 0.0, input.y)

	#if direction.dot(-cam_h.global_basis.z) < -0.1:
		#direction *= 0.5

	if current_movement_state == MovementState.ON_FLOOR:
		velocity.x = lerpf(
						velocity.x,
						direction.x * SPEED * sprint_speed_modifier,
						ACCEL
						)
		velocity.z = lerpf(
						velocity.z,
						direction.z * SPEED * sprint_speed_modifier,
						ACCEL
						)

		if Input.is_action_just_pressed("jump") or jump_queue:
			velocity.y += JUMP
			jumped.emit()
			footstep(1.0)
			footstep_timer = FOOTSTEP_TIME
			jump_queue = 0
	elif current_movement_state == MovementState.ASCENDING:
		if jump_queue:
			jump_queue -= 1
		sprint_speed_modifier = lerpf(sprint_speed_modifier, 1.0, 0.01)
		velocity.x = lerpf(
						velocity.x,
						direction.x * SPEED * sprint_speed_modifier,
						ACCEL_AIR
						)
		velocity.z = lerpf(
						velocity.z,
						direction.z * SPEED * sprint_speed_modifier,
						ACCEL_AIR
						)

		velocity += get_gravity() * delta
		if Input.is_action_just_pressed("jump"):
			jump_queue = JUMP_QUEUE_FRAMES
	elif current_movement_state == MovementState.FALLING:
		if jump_queue:
			jump_queue -= 1
		sprint_speed_modifier = lerpf(sprint_speed_modifier, 1.0, 0.01)
		velocity.x = lerpf(
						velocity.x,
						direction.x * SPEED * sprint_speed_modifier,
						ACCEL_AIR
						)
		velocity.z = lerpf(
						velocity.z,
						direction.z * SPEED * sprint_speed_modifier,
						ACCEL_AIR
						)

		velocity += get_gravity() * delta
		if Input.is_action_just_pressed("jump"):
			jump_queue = JUMP_QUEUE_FRAMES

	move_and_slide()

	if is_on_floor():
		current_movement_state = MovementState.ON_FLOOR
		var real_vel := get_real_velocity()
		var real_vel_xz := Vector2(real_vel.x, real_vel.z)
		var footstep_speed: float = real_vel_xz.length() / SPEED
		footstep_timer -= (delta + randfn(0.0, 0.001)) * footstep_speed
		if footstep_timer <= 0.0:
			footstep_timer = FOOTSTEP_TIME
			footstep(real_vel_xz.length() / SPEED)
	elif velocity.y >= 0.0:
		current_movement_state = MovementState.ASCENDING
	else:
		current_movement_state = MovementState.FALLING
