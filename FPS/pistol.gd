extends Gun


const PISTOL_EJECT = preload("uid://ph6qi5x0ye6b")


@onready var visual: Node3D = $Visual
@onready var particle_spot: Node3D = $Visual/ParticleSpot
@onready var reticle: Control = $Reticle
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _on_fired() -> void:
	var new_eject_particle = PISTOL_EJECT.instantiate()
	particle_spot.add_child(new_eject_particle)
	animation_player.play("fire")


func _on_scoped_changed() -> void:
	reticle.visible = not scoped


func _on_reload_started() -> void:
	animation_player.play("reload")
