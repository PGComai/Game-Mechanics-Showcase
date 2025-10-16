extends Control


const DEMO_SHOW = preload("uid://tdqvrqgt343p")
const DEMOS_PER_PAGE: int = 3


@export var default_scene: PackedScene
@export var demos: Array[Demo]


var current_scene: Node
var current_demo: Demo
var current_page: int = 0:
	set(value):
		var max_page: int = ceili(float(demos.size()) / float(DEMOS_PER_PAGE))
		current_page = wrapi(value, 0, max_page)
		print(current_page)
var focus_first_demo := true
var last_focused_demo: DemoShow
var valid_demos_shown: Array[DemoShow] = []


@onready var sub_viewport: SubViewport = $TextureRect/SubViewport
@onready var demo_browser: PanelContainer = $DemoBrowser
@onready var h_box_container_demos: HBoxContainer = $DemoBrowser/MarginContainer/HBoxContainerPages/HBoxContainerDemos


func _ready() -> void:
	sub_viewport.size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)
	if default_scene:
		current_scene = default_scene.instantiate()
		sub_viewport.add_child(current_scene)
	
	show_demo_page()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		get_tree().paused = not get_tree().paused
		demo_browser.visible = get_tree().paused
		if get_tree().paused:
			if last_focused_demo:
				last_focused_demo.icon_button.grab_focus()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func show_demo_page() -> void:
	for child in h_box_container_demos.get_children():
		child.queue_free()
	var iter: int = 0
	var demos_on_page: int = 0
	valid_demos_shown = []
	for demo: Demo in demos:
		if iter < (current_page * DEMOS_PER_PAGE) + 3 and iter > (current_page * DEMOS_PER_PAGE) - 1:
			var new_demo_show: DemoShow = DEMO_SHOW.instantiate()
			new_demo_show.demo = demo
			h_box_container_demos.add_child(new_demo_show)
			new_demo_show.picked.connect(_on_demo_selected)
			new_demo_show.focused.connect(_on_demo_focused)
			demos_on_page += 1
			valid_demos_shown.append(new_demo_show)
		iter += 1
	
	for need_dummy in DEMOS_PER_PAGE - demos_on_page:
		var new_dummy: DemoShow = DEMO_SHOW.instantiate()
		h_box_container_demos.add_child(new_dummy)
	
	if focus_first_demo:
		valid_demos_shown[0].icon_button.grab_focus()
	else:
		valid_demos_shown[-1].icon_button.grab_focus()


func _on_demo_selected(demo: Demo) -> void:
	get_tree().paused = false
	demo_browser.visible = false
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	var new_scene = demo.scene.instantiate()
	sub_viewport.call_deferred("add_child", new_scene)
	current_scene = new_scene


func _on_demo_focused(demo_show: DemoShow) -> void:
	last_focused_demo = demo_show


func _on_button_page_right_pressed() -> void:
	current_page += 1
	focus_first_demo = true
	last_focused_demo = null
	show_demo_page()


func _on_button_page_left_pressed() -> void:
	current_page -= 1
	focus_first_demo = false
	last_focused_demo = null
	show_demo_page()
