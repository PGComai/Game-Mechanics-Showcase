extends Control


@export var default_scene: PackedScene


var current_scene: Node


@onready var sub_viewport: SubViewport = $TextureRect/SubViewport


func _ready() -> void:
	current_scene = default_scene.instantiate()
	sub_viewport.add_child(current_scene)
