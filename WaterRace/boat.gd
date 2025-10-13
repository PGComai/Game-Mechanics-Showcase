extends CharacterBody3D
class_name Boat


@onready var height_detector: RayCast3D = $HeightDetector
@onready var camera_3d: Camera3D = $Camera3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	height_detector.top_level = true


func _physics_process(delta: float) -> void:
	height_detector.global_position.x = global_position.x
	height_detector.global_position.z = global_position.z
	
	
	var input := Input.get_vector("left", "right", "fwd", "back")
	var dir := global_basis * Vector3(0.0, 0.0, input.y)
	
	if input.x:
		rotation.y = lerp_angle(rotation.y, rotation.y - (input.x * delta * 10.0), 0.1)
	
	
	if height_detector.is_colliding():
		var pos := height_detector.get_collision_point()
		var norm := height_detector.get_collision_normal()
		var height_diff: float = pos.y - global_position.y
		var contact_damping: float = 1.0 / (100.0 * (absf(height_diff) + 0.05))
		#velocity.y = lerpf(velocity.y, 0.0, contact_damping)
		if global_position.y > pos.y:
			velocity += get_gravity() * delta * 0.8
		else:
			velocity.y *= 0.95
			velocity.x *= 0.99
			velocity.z *= 0.99
			velocity += norm * (pow(absf(height_diff + 0.5), 3.0) * 10.0) * delta
			var old_y: float = velocity.y
			if dir.z:
				velocity = lerp(velocity, -global_basis.z * 20.0, 0.05)
			else:
				velocity = lerp(velocity, -global_basis.z, 0.01)
			velocity.y = old_y
	
	
	move_and_slide()
