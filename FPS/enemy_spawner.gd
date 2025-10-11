extends Node3D


const HORDE_ENEMY = preload("uid://315vad3fbcko")


@onready var area_3d: Area3D = $Area3D


func _ready() -> void:
	_on_timer_spawn_timeout()


func _on_timer_spawn_timeout() -> void:
	var player: CharacterBody3D = get_tree().get_first_node_in_group("player")
	if area_3d.get_overlapping_bodies().size() == 0 and player:
		if player.global_position.distance_squared_to(global_position) > 15.0:
			var new_enemy = HORDE_ENEMY.instantiate()
			add_child(new_enemy)
