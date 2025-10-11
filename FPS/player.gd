extends CharacterBody3D
class_name Player

const MAX_HEALTH: int = 5
const SENS: float = 0.003
const SENS_JOY: float = 0.08
const SPEED: float = 7.0
const SPRINT_BOOST: float = 1.5
const SPRINT_MAX_ENERGY: float = 4.0
const SPRINT_RECHARGE_SPEED: float = 0.8
const SPRINT_RECHARGE_SPEED_HARD: float = 0.5
const JUMP: float = 5.0
const GRAV_SCALE: float = 2.0
const JUMP_QUEUE_FRAMES: int = 8
const ACCEL: float = 0.2
const ACCEL_AIR: float = 0.05
const DEFAULT_FOV: float = 75.0
const FOOTSTEP_TIME: float = 0.35
const FOOTSTEP_MIN_VOLUME: float = -7.5
const FOOTSTEP_MAX_VOLUME: float = 0.0
const FOOTSTEP_MIN_SOUND_STRENGTH: float = 0.1
const FOOTSTEP_MAX_SOUND_STRENGTH: float = 0.7
const HEAD_HEIGHT_STAND: float = 1.8
const HEAD_HEIGHT_CROUCH: float = 0.8
const CROUCH_SLOWDOWN: float = 0.7
const PISTOL_IMPACT = preload("uid://d0qsi4tjujcfy")
const PISTOL_MARK = preload("uid://c05e315l3ale")


signal jumped
signal landed
signal movement_state_changed(old_state: MovementState, new_state: MovementState)
signal sprint_finished
signal sprint_exhausted
signal sprint_recharged
signal controller_input_changed(using_controller: bool)


enum MovementState {ON_FLOOR, ASCENDING, FALLING}


@export var current_gun: Gun:
	set(value):
		current_gun = value
		if current_gun:
			current_gun.fired.connect(_on_gun_fired)
			current_gun.reload_started.connect(_on_gun_reload_started)
			current_gun.reload_finished.connect(_on_gun_reload_finished)
			current_gun.need_ammo.connect(_on_gun_need_ammo)
			current_gun.last_shot.connect(_on_gun_last_shot)


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
var aim_sens: float = 1.0
var crouching := false
var head_y_target: float = HEAD_HEIGHT_STAND


@onready var audio_stream_player_3d_footstep: AudioStreamPlayer3D = $AudioStreamPlayer3DFootstep
@onready var cam_h: Node3D = $CamH
@onready var camera_3d: Camera3D = $CamH/Camera3D
@onready var gun_mount: Node3D = $CamH/Camera3D/GunMount
@onready var gun_spot_default: Node3D = $CamH/Camera3D/GunSpotDefault
@onready var gun_spot_scope: Node3D = $CamH/Camera3D/GunSpotScope
@onready var ray_cast_3d_gun: RayCast3D = $CamH/Camera3D/RayCast3DGun
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var collision_shape_3d_crouch: CollisionShape3D = $CollisionShape3DCrouch
@onready var collision_shape_3d_crouch_air: CollisionShape3D = $CollisionShape3DCrouchAir
@onready var shape_cast_3d_uncrouch_up_test: ShapeCast3D = $ShapeCast3DUncrouchUpTest
@onready var shape_cast_3d_uncrouch_down_test: ShapeCast3D = $ShapeCast3DUncrouchDownTest


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var scene_root = get_tree().root.get_child(0)
	if scene_root.is_class("Control"):
		var control_root: Control = scene_root
		control_root.gui_input.connect(_on_control_gui_input)

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rot_h -= event.screen_relative.x * SENS * aim_sens
			rot_v -= event.screen_relative.y * SENS * aim_sens
	elif event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventJoypadMotion or InputEventJoypadButton:
		controller_input = true
	else:
		controller_input = false


func _on_control_gui_input(event: InputEvent) -> void:
	_unhandled_input(event)


func footstep(step_speed: float) -> void:
	audio_stream_player_3d_footstep.play()
	audio_stream_player_3d_footstep.volume_db = remap(step_speed,
														1.0,
														SPRINT_BOOST,
														FOOTSTEP_MIN_VOLUME,
														FOOTSTEP_MAX_VOLUME)
	audio_stream_player_3d_footstep.pitch_scale = randfn(1.0, 0.05)


func _process(delta: float) -> void:
	if Input.is_action_pressed("scope"):
		gun_mount.position = lerp(gun_mount.position, gun_spot_scope.position, 0.4)
		if current_gun:
			camera_3d.fov = lerpf(camera_3d.fov, current_gun.scope_fov, 0.4)
			current_gun.scoped = true
		aim_sens = lerpf(aim_sens, camera_3d.fov / DEFAULT_FOV, 0.4)
	else:
		gun_mount.position = lerp(gun_mount.position, gun_spot_default.position, 0.4)
		camera_3d.fov = lerpf(camera_3d.fov, DEFAULT_FOV, 0.4)
		aim_sens = lerpf(aim_sens, 1.0, 0.4)
		if current_gun:
			current_gun.scoped = false
	
	if current_gun:
		if Input.is_action_just_pressed("shoot"):
			current_gun.fire()
		if Input.is_action_just_pressed("reload"):
			current_gun.reload(10)


func _physics_process(delta: float) -> void:
	if sprint_recharging_hard:
		sprint_energy += delta * SPRINT_RECHARGE_SPEED_HARD
	elif sprint_recharging:
		sprint_energy += delta * SPRINT_RECHARGE_SPEED

	var sprint_held := Input.is_action_pressed("sprint")
	var crouch_held := Input.is_action_pressed("crouch")

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
	if joy_look:
		controller_input = true

	if controller_input:
		var slow_factor: float = 1.0
		var y_invert := 1.0
		rot_h -= joy_look.x * slow_factor * SENS_JOY * aim_sens
		rot_v += joy_look.y * slow_factor * SENS_JOY * aim_sens

	cam_h.rotation.y = rot_h
	camera_3d.rotation.x = rot_v

	var input := Input.get_vector("left", "right", "fwd", "back")
	var direction := cam_h.global_basis * Vector3(input.x, 0.0, input.y)

	#if direction.dot(-cam_h.global_basis.z) < -0.1:
		#direction *= 0.5
	
	if crouching and not crouch_held:
		uncrouch()
		print("uncrouching")
	elif not crouching and crouch_held:
		crouch()
		print("crouching")
	
	cam_h.position.y = lerpf(cam_h.position.y, head_y_target, 0.3)
	
	var crouch_effect: float
	if crouching:
		crouch_effect = CROUCH_SLOWDOWN
	else:
		crouch_effect = 1.0
	
	if current_movement_state == MovementState.ON_FLOOR:
		velocity.x = lerpf(
						velocity.x,
						direction.x * SPEED * sprint_speed_modifier * crouch_effect,
						ACCEL
						)
		velocity.z = lerpf(
						velocity.z,
						direction.z * SPEED * sprint_speed_modifier * crouch_effect,
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
						direction.x * SPEED * sprint_speed_modifier * crouch_effect,
						ACCEL_AIR
						)
		velocity.z = lerpf(
						velocity.z,
						direction.z * SPEED * sprint_speed_modifier * crouch_effect,
						ACCEL_AIR
						)

		velocity += get_gravity() * delta * GRAV_SCALE
		if Input.is_action_just_pressed("jump"):
			jump_queue = JUMP_QUEUE_FRAMES
	elif current_movement_state == MovementState.FALLING:
		if jump_queue:
			jump_queue -= 1
		sprint_speed_modifier = lerpf(sprint_speed_modifier, 1.0, 0.01)
		velocity.x = lerpf(
						velocity.x,
						direction.x * SPEED * sprint_speed_modifier * crouch_effect,
						ACCEL_AIR
						)
		velocity.z = lerpf(
						velocity.z,
						direction.z * SPEED * sprint_speed_modifier * crouch_effect,
						ACCEL_AIR
						)

		velocity += get_gravity() * delta * GRAV_SCALE
		if Input.is_action_just_pressed("jump"):
			jump_queue = JUMP_QUEUE_FRAMES

	move_and_slide()
	
	var real_vel := get_real_velocity()
	if current_gun:
		current_gun.movement_dir = (cam_h.global_basis.inverse() * real_vel) / SPEED

	if is_on_floor():
		if current_movement_state != MovementState.ON_FLOOR:
			if crouching:
				global_position.y += 1.0
				collision_shape_3d_crouch.disabled = false
				collision_shape_3d_crouch_air.disabled = true
				collision_shape_3d.disabled = true
				head_y_target = HEAD_HEIGHT_CROUCH
				cam_h.position.y = head_y_target
		current_movement_state = MovementState.ON_FLOOR
		var real_vel_xz := Vector2(real_vel.x, real_vel.z)
		var footstep_speed: float = real_vel_xz.length() / SPEED
		footstep_timer -= (delta + randfn(0.0, 0.001)) * footstep_speed
		if footstep_timer <= 0.0:
			footstep_timer = FOOTSTEP_TIME
			footstep(real_vel_xz.length() / SPEED)
	elif velocity.y >= 0.0:
		if current_movement_state == MovementState.ON_FLOOR:
			if crouching:
				global_position.y -= 1.0
				collision_shape_3d_crouch.disabled = true
				collision_shape_3d_crouch_air.disabled = false
				collision_shape_3d.disabled = true
				head_y_target = HEAD_HEIGHT_STAND
				cam_h.position.y = head_y_target
		current_movement_state = MovementState.ASCENDING
	else:
		if current_movement_state == MovementState.ON_FLOOR:
			if crouching:
				global_position.y -= 1.0
				collision_shape_3d_crouch.disabled = true
				collision_shape_3d_crouch_air.disabled = false
				collision_shape_3d.disabled = true
				head_y_target = HEAD_HEIGHT_STAND
				cam_h.position.y = head_y_target
		current_movement_state = MovementState.FALLING


func crouch() -> void:
	crouching = true
	if current_movement_state == MovementState.ON_FLOOR:
		collision_shape_3d_crouch.disabled = false
		collision_shape_3d_crouch_air.disabled = true
		collision_shape_3d.disabled = true
		head_y_target = HEAD_HEIGHT_CROUCH
	else:
		collision_shape_3d_crouch.disabled = true
		collision_shape_3d_crouch_air.disabled = false
		collision_shape_3d.disabled = true
		head_y_target = HEAD_HEIGHT_STAND


func uncrouch() -> void:
	if current_movement_state == MovementState.ON_FLOOR:
		if not shape_cast_3d_uncrouch_up_test.is_colliding():
			crouching = false
			collision_shape_3d_crouch.disabled = true
			collision_shape_3d_crouch_air.disabled = true
			collision_shape_3d.disabled = false
			head_y_target = HEAD_HEIGHT_STAND
	else:
		if not shape_cast_3d_uncrouch_down_test.is_colliding():
			crouching = false
			collision_shape_3d_crouch.disabled = true
			collision_shape_3d_crouch_air.disabled = true
			collision_shape_3d.disabled = false
			head_y_target = HEAD_HEIGHT_STAND

func _on_gun_fired() -> void:
	var accuracy: float
	if current_gun.scoped:
		accuracy = current_gun.accuracy_scope
	else:
		accuracy = current_gun.accuracy_hip
	var accuracy_vec := Vector3(randfn(0.0, accuracy),
								randfn(0.0, accuracy),
								randfn(0.0, accuracy))
	accuracy_vec = Plane(camera_3d.global_basis.z, Vector3.ZERO).project(accuracy_vec)
	ray_cast_3d_gun.look_at(ray_cast_3d_gun.global_position\
					- (camera_3d.global_basis.z * 20.0)\
					+ accuracy_vec)
	ray_cast_3d_gun.force_update_transform()
	ray_cast_3d_gun.force_raycast_update()
	
	if ray_cast_3d_gun.is_colliding():
		var collider: Node3D = ray_cast_3d_gun.get_collider()
		if collider.is_in_group("damageable"):
			collider.health -= current_gun.bullet_damage
		else:
			var new_impact: GPUParticles3D = PISTOL_IMPACT.instantiate()
			get_parent().add_child(new_impact)
			var pos := ray_cast_3d_gun.get_collision_point()
			var norm := ray_cast_3d_gun.get_collision_normal()
			var rc_dir := ray_cast_3d_gun.global_basis.z
			var oblique: float = maxf(rc_dir.dot(norm), 0.0)
			var refl := -rc_dir.reflect(norm)
			new_impact.look_at_from_position(
									pos,
									pos + (norm.slerp(-refl, 1.0 - oblique))
									)
			var p_mat: ParticleProcessMaterial = new_impact.process_material
			p_mat.spread = oblique * 90.0
			new_impact.speed_scale = 1.0 + (1.0 - oblique)
			
			var new_mark: MeshInstance3D = PISTOL_MARK.instantiate()
			get_parent().add_child(new_mark)
			new_mark.global_position = pos + (norm * 0.01)
			new_mark.look_at(pos - norm)
	print("fired")


func _on_gun_reload_started() -> void:
	print("reloading")


func _on_gun_reload_finished() -> void:
	print("reload finished")


func _on_gun_need_ammo() -> void:
	current_gun.reload(10)
	print("need ammo")


func _on_gun_last_shot() -> void:
	print("clip empty")
