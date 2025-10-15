extends CharacterBody3D
class_name Boat


signal boat_under_water(depth: float, pos: Vector2)


const SPEED: float = 20.0
const ACCEL: float = 0.02
const SPEED_TILT_SCALE: float = 0.25
const WAVE_DIST: float = 3.0
const WAVE_THRESH: float = 0.1


var look_y := Vector3.UP
var speed_tilt := Vector3.ZERO
var turn_tilt := Vector3.ZERO
var throttle: float = 0.0
var turn: float = 0.0


@onready var height_detector: RayCast3D = $HeightDetector
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var wave_displacer: Node3D = $WaveDisplacer


func _ready() -> void:
	height_detector.top_level = true


func _physics_process(delta: float) -> void:
	height_detector.global_position.x = global_position.x
	height_detector.global_position.z = global_position.z
	
	var dir := global_basis * Vector3(0.0, 0.0, throttle)
	
	turn_tilt = turn_tilt.lerp(global_basis.x * turn * 0.4, 0.05)
	
	if turn:
		if throttle > 0.0:
			rotation.y = lerp_angle(rotation.y, rotation.y + (turn * delta * 10.0), 0.1)
		else:
			rotation.y = lerp_angle(rotation.y, rotation.y - (turn * delta * 10.0), 0.1)
	
	var real_vel := get_real_velocity()
	var real_vel_xz := Vector2(real_vel.x, real_vel.z)
	
	if height_detector.is_colliding():
		var pos := height_detector.get_collision_point()
		var norm := height_detector.get_collision_normal()
		var height_diff: float = pos.y - global_position.y
		if height_diff > -WAVE_THRESH and dir:
			var disp_strength: float = remap(real_vel_xz.length(),
											0.0,
											SPEED,
											0.0,
											1.0)
			var disp_pos := global_position - dir * WAVE_DIST
			boat_under_water.emit((height_diff + WAVE_THRESH) * disp_strength,
							Vector2(disp_pos.x,
									disp_pos.z))
		if global_position.y > pos.y:
			speed_tilt = speed_tilt.lerp(Vector3.ZERO, 0.005)
			look_y = look_y.slerp(Vector3.UP, 0.005)
			velocity += get_gravity() * delta * 0.8
		else:
			speed_tilt = speed_tilt.lerp(Vector3.DOWN\
									* minf(throttle, 0.0)\
									* SPEED_TILT_SCALE, 0.025)
			look_y = look_y.slerp(norm, 0.025)
			velocity.y *= 0.95
			velocity.x *= 0.99
			velocity.z *= 0.99
			velocity += norm * (pow(absf(height_diff + 0.5), 3.0) * 10.0) * delta
			if dir:
				velocity.x = lerpf(velocity.x, dir.x * SPEED, ACCEL)
				velocity.z = lerpf(velocity.z, dir.z * SPEED, ACCEL)
			else:
				velocity.x = lerpf(velocity.x, 0.0, ACCEL)
				velocity.z = lerpf(velocity.z, 0.0, ACCEL)
	
	mesh_instance_3d.position.y = speed_tilt.y
	mesh_instance_3d.look_at(mesh_instance_3d.global_position\
						+ look_y.cross(global_basis.x)\
						+ speed_tilt,
					look_y + turn_tilt)
	
	move_and_slide()
