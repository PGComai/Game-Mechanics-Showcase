extends Gun


@onready var movement_pivot: Node3D = $MovementPivot
@onready var reticle: Control = $Reticle


func _process(delta: float) -> void:
	movement_pivot.rotation.z = clampf(movement_dir.x, -1.5, 1.5) * -(PI/32.0)


func _on_scoped_changed() -> void:
	reticle.visible = not scoped
