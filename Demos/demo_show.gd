extends PanelContainer
class_name DemoShow


signal picked(_demo: Demo)
signal focused(demo_show: DemoShow)


@export var demo: Demo


@onready var icon_button: Button = $MarginContainer/VBoxContainer/IconButton
@onready var label_title: Label = $MarginContainer/VBoxContainer/LabelTitle
@onready var label_description: Label = $MarginContainer/VBoxContainer/LabelDescription


func _ready() -> void:
	if demo:
		icon_button.icon = demo.thumbnail
		label_title.text = demo.title
		label_description.text = demo.description
	else:
		label_title.text = ""
		label_description.text = ""


func _on_icon_button_pressed() -> void:
	if demo:
		picked.emit(demo)


func _on_icon_button_focus_entered() -> void:
	focused.emit(self)
