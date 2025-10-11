extends Gun


const PISTOL_EJECT = preload("uid://ph6qi5x0ye6b")


@onready var movement_pivot: Node3D = $MovementPivot
@onready var visual: Node3D = $MovementPivot/Visual
@onready var particle_spot: Node3D = $MovementPivot/Visual/ParticleSpot
@onready var animation_player: AnimationPlayer = $MovementPivot/Visual/AnimationPlayer
@onready var reticle: Control = $Reticle


func _process(delta: float) -> void:
	movement_pivot.rotation.z = clampf(movement_dir.x, -1.5, 1.5) * -(PI/32.0)


func _on_fired() -> void:
	var new_eject_particle = PISTOL_EJECT.instantiate()
	particle_spot.add_child(new_eject_particle)
	animation_player.play("fire")


func _on_scoped_changed() -> void:
	reticle.visible = not scoped


func _on_reload_started() -> void:
	animation_player.play("reload")
