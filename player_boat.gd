extends Boat


func _ready() -> void:
	var scene_root = get_tree().root.get_child(0)
	if scene_root.is_class("Control"):
		var control_root: Control = scene_root
		control_root.gui_input.connect(_on_control_gui_input)


func _process(delta: float) -> void:
	throttle = Input.get_axis("fwd", "back")
	turn = Input.get_axis("left", "right")


func _on_control_gui_input(event: InputEvent) -> void:
	pass
