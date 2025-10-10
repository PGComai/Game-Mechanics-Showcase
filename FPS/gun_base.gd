@abstract
extends Node3D
class_name Gun


signal reload_started
signal reload_finished
signal fired
signal need_ammo
signal last_shot
signal scoped_changed


enum AmmoType{LIGHT, HEAVY, SNIPER}


@export var reload_time: float = 2.0
@export var shot_time: float = 0.2
@export var clip_size: int = 10
@export var gun_ammo_type: AmmoType
@export var scope_fov: float = 60.0


var reload_timer := Timer.new()
var clip: int = clip_size:
	set(value):
		clip = clampi(value, 0, clip_size)
var shot_timer := Timer.new()
var can_shoot := true
var reloading := false
var scoped := false:
	set(value):
		var changed := scoped != value
		scoped = value
		if changed:
			scoped_changed.emit()


func _ready() -> void:
	add_child(reload_timer)
	add_child(shot_timer)
	
	reload_timer.one_shot = true
	reload_timer.wait_time = reload_time
	reload_timer.timeout.connect(_on_reload_timer_timeout)
	
	shot_timer.one_shot = true
	shot_timer.wait_time = shot_time
	shot_timer.timeout.connect(_on_shot_timer_timeout)


func fire() -> void:
	if not reloading and can_shoot:
		if clip:
			can_shoot = false
			fired.emit()
			shot_timer.start()
			clip -= 1
			if clip == 0:
				last_shot.emit()
		else:
			need_ammo.emit()


func reload(ammo_in: int) -> int:
	if reloading:
		return ammo_in
	var ammo_left: int = maxi((ammo_in + clip) - clip_size, 0)
	clip += ammo_in
	if ammo_in > ammo_left:
		reload_started.emit()
		reload_timer.start()
		reloading = true
	return ammo_left


func _on_reload_timer_timeout() -> void:
	reloading = false
	reload_finished.emit()


func _on_shot_timer_timeout() -> void:
	can_shoot = true
