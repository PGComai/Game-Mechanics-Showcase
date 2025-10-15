extends Control


@export var default_scene: PackedScene


var current_scene: Node


@onready var sub_viewport: SubViewport = $TextureRect/SubViewport


func _ready() -> void:
	sub_viewport.size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)
	if default_scene:
		current_scene = default_scene.instantiate()
		sub_viewport.add_child(current_scene)
