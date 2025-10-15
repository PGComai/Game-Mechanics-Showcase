extends Boat


@export var checkpoints: Array[Node3D]


var turn_variation: float = 0.0
var throttle_variation: float = 0.0
var next_checkpoint: int = 0:
	set(value):
		next_checkpoint = wrapi(value, 0, checkpoints.size())


func _process(delta: float) -> void:
	turn_variation = lerpf(turn_variation, randfn(0.0, 1.0), 0.1)
	turn_variation = lerpf(turn_variation, 0.0, 0.01)
	
	throttle_variation = lerpf(throttle_variation, randfn(0.0, 0.1), 0.1)
	throttle_variation = lerpf(throttle_variation, 0.0, 0.01)
	
	var pos_2d := Vector2(global_position.x, global_position.z)
	var target := checkpoints[next_checkpoint].global_position
	var target_2d := Vector2(target.x, target.z)
	var dir := pos_2d.direction_to(target_2d)
	var fore := Vector2(-global_basis.z.x, -global_basis.z.z).normalized()
	
	
	turn = signf(fore.angle_to(dir)) + turn_variation
	throttle = -maxf(fore.dot(dir), 0.1) + throttle_variation
	
	if target_2d.distance_squared_to(pos_2d) < 4.0:
		next_checkpoint += 1
