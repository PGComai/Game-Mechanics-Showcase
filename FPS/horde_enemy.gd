extends CharacterBody3D


const SPEED: float = 5.0
const MAX_HEALTH: float = 4.0


var player: CharacterBody3D
var health: float = MAX_HEALTH:
	set(value):
		health = value
		if health <= 0.0 and not dead:
			dead = true
			queue_free()
var dead := false
var climbing := false


@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D


func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	
	if not player:
		player = get_tree().get_first_node_in_group("player")
	else:
		navigation_agent_3d.target_position = player.global_position
		var next_pos := navigation_agent_3d.get_next_path_position()
		dir = global_position.direction_to(next_pos)
	
	velocity.x = lerpf(velocity.x, dir.x * SPEED, 0.1)
	velocity.z = lerpf(velocity.z, dir.z * SPEED, 0.1)
	
	var real_vel := get_real_velocity()
	var real_vel_xz := Vector2(real_vel.x, real_vel.z)
	
	if dir.y > 0.6 and is_on_wall():
		velocity.y = 4.0
		climbing = true
	elif dir.y > 0.05 and climbing:
		velocity.y = 2.0
	else:
		climbing = false
		if not is_on_floor():
			velocity += get_gravity() * delta
	
	
	move_and_slide()
