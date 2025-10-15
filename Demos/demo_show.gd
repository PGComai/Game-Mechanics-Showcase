extends PanelContainer


signal picked(scene: PackedScene)


@export var demo: Demo


@onready var icon_button: Button = $MarginContainer/VBoxContainer/IconButton
@onready var label_title: Label = $MarginContainer/VBoxContainer/LabelTitle
@onready var label_description: Label = $MarginContainer/VBoxContainer/LabelDescription


func _ready() -> void:
	if demo:
		icon_button.icon = demo.thumbnail
		label_title.text = demo.title
		label_description.text = demo.description


func _on_icon_button_pressed() -> void:
	picked.emit(demo.scene)
