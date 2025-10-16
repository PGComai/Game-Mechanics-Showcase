extends Node3D


const SENS: float = 0.002
const SENS_JOY: float = 0.03
const OBJ_ROT_SENS: float = 0.05
const OBJ_TILT_SENS: float = 0.05


var rot_h: float = 0.0
var rot_v: float = 0.0:
	set(value):
		rot_v = clampf(value, -PI/2.1, PI/2.1)
var target_cam_dist: float = 10.0:
	set(value):
		target_cam_dist = clampf(value, 5.0, 50.0)

var held_object: Node3D
var build_speed_multiplier: float = 1.0


@onready var free_cam_v: Node3D = $FreeCamV
@onready var cam: Camera3D = $FreeCamV/FreeCam


func _process(delta: float) -> void:
	var object_rotation: bool = Input.is_action_pressed("level_edit_rotate")\
	and held_object
	
	var object_size_edit: bool = Input.is_action_pressed("level_edit_edit")\
	and held_object
	
	if Input.is_action_pressed("level_edit_fast"):
		build_speed_multiplier = lerp(build_speed_multiplier, 10.0, 0.1)
	elif Input.is_action_pressed("level_edit_slow"):
		build_speed_multiplier = lerp(build_speed_multiplier, 0.1, 0.1)
	else:
		build_speed_multiplier = lerp(build_speed_multiplier, 1.0, 0.1)
	
	var look_axis = Input.get_vector("joy_look_left", "joy_look_right", "joy_look_up", "joy_look_down")
	var updown = Input.get_axis("level_edit_down", "level_edit_up")
	var input_dir = Input.get_vector("left", "right", "fwd", "back")
	
	if not object_rotation:
		if look_axis:
			rot_h -= look_axis.x * SENS_JOY
			rot_v -= look_axis.y * SENS_JOY
		
		rotation.y = rot_h
		free_cam_v.rotation.x = rot_v
		var travel_dir = (cam.global_transform.basis
							* Vector3(input_dir.x,
									updown,
									input_dir.y)
									).normalized()
		
		if object_size_edit:
			pass#Global.exposed_object.size_edit(input_dir.x * SIZE_ADJUST_SENS)
		#elif travel_dir and not held_object:
			#global_position += travel_dir * 0.2 * build_speed_multiplier
		elif travel_dir:
			var movement_offset = travel_dir * 0.2 * build_speed_multiplier
			if held_object:
				held_object.global_position += movement_offset
			global_position += movement_offset
	elif abs(input_dir.y) > abs(input_dir.x):
		# adjusting camera distance
		target_cam_dist += input_dir.y * 0.3
	elif held_object:
		# rotating object
		held_object.orthonormalize()
		if abs(look_axis.x) > abs(look_axis.y):
			rotate_object_y(look_axis.x)
		elif abs(look_axis.x) < abs(look_axis.y):
			rotate_object_x(look_axis.y)
		elif abs(input_dir.x) > 0.0:
			rotate_object_z(-input_dir.x)
		held_object.orthonormalize()
	
	cam.position.z = lerpf(cam.position.z, -target_cam_dist, 0.1)


func rotate_object_y(rot_amount: float):
	if held_object.global_basis.x.angle_to(cam.global_basis.y) < PI/4.0:
		held_object.rotate(held_object.global_basis.x, rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.x.angle_to(cam.global_basis.y) > 3.0 * PI/4.0:
		held_object.rotate(held_object.global_basis.x, -rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.y.angle_to(cam.global_basis.y) < PI/4.0:
		held_object.rotate(held_object.global_basis.y, rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.y.angle_to(cam.global_basis.y) > 3.0 * PI/4.0:
		held_object.rotate(held_object.global_basis.y, -rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.z.angle_to(cam.global_basis.y) < PI/4.0:
		held_object.rotate(held_object.global_basis.z, rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.z.angle_to(cam.global_basis.y) > 3.0 * PI/4.0:
		held_object.rotate(held_object.global_basis.z, -rot_amount * OBJ_ROT_SENS)


func rotate_object_x(rot_amount: float):
	if held_object.global_basis.x.angle_to(cam.global_basis.x) < PI/4.0:
		held_object.rotate(held_object.global_basis.x, rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.x.angle_to(cam.global_basis.x) > 3.0 * PI/4.0:
		held_object.rotate(held_object.global_basis.x, -rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.y.angle_to(cam.global_basis.x) < PI/4.0:
		held_object.rotate(held_object.global_basis.y, rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.y.angle_to(cam.global_basis.x) > 3.0 * PI/4.0:
		held_object.rotate(held_object.global_basis.y, -rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.z.angle_to(cam.global_basis.x) < PI/4.0:
		held_object.rotate(held_object.global_basis.z, rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.z.angle_to(cam.global_basis.x) > 3.0 * PI/4.0:
		held_object.rotate(held_object.global_basis.z, -rot_amount * OBJ_ROT_SENS)


func rotate_object_z(rot_amount: float):
	if held_object.global_basis.x.angle_to(cam.global_basis.z) < PI/4.0:
		held_object.rotate(held_object.global_basis.x, rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.x.angle_to(cam.global_basis.z) > 3.0 * PI/4.0:
		held_object.rotate(held_object.global_basis.x, -rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.y.angle_to(cam.global_basis.z) < PI/4.0:
		held_object.rotate(held_object.global_basis.y, rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.y.angle_to(cam.global_basis.z) > 3.0 * PI/4.0:
		held_object.rotate(held_object.global_basis.y, -rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.z.angle_to(cam.global_basis.z) < PI/4.0:
		held_object.rotate(held_object.global_basis.z, rot_amount * OBJ_ROT_SENS)
	elif held_object.global_basis.z.angle_to(cam.global_basis.z) > 3.0 * PI/4.0:
		held_object.rotate(held_object.global_basis.z, -rot_amount * OBJ_ROT_SENS)
