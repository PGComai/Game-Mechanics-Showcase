@tool
extends StaticBody3D
class_name StairMaster


@export var make := false:
	set(value):
		if value:
			make_stairs()
@export var step_size := Vector3(1.0, 1.0, 1.0):
	set(value):
		step_size = clamp(value, Vector3(0.5, 0.5, 0.5), Vector3(20.0, 20.0, 20.0))
		if Engine.is_editor_hint() and is_inside_tree():
			make_stairs()
@export var step_height: float = 1.0:
	set(value):
		step_height = clampf(value, -20.0, 20.0)
		if Engine.is_editor_hint() and is_inside_tree():
			make_stairs()
@export var num_steps: int = 5:
	set(value):
		num_steps = clampi(value, 1, 200)
		if Engine.is_editor_hint() and is_inside_tree():
			make_stairs()
@export var smooth := false:
	set(value):
		smooth = value
		if Engine.is_editor_hint() and is_inside_tree():
			make_stairs()


func _enter_tree() -> void:
	add_to_group("nav")


func make_stairs():
	for child in get_children():
		child.queue_free()
	
	var new_mmi := MultiMeshInstance3D.new()
	var new_mm := MultiMesh.new()
	var stepmesh := BoxMesh.new()
	stepmesh.size = step_size
	
	new_mm.transform_format = MultiMesh.TRANSFORM_3D
	new_mm.mesh = stepmesh
	new_mm.instance_count = num_steps
	new_mm.visible_instance_count = new_mm.instance_count
	
	for i in num_steps:
		var float_i := float(i)
		var step_pos := Vector3(0.0,
						(float_i * step_height) + (step_size.y / 2.0),
						-float_i * step_size.z)
		if not smooth:
			var new_step := CollisionShape3D.new()
			var new_shape := BoxShape3D.new()
			new_shape.size = step_size
			new_step.shape = new_shape
			
			add_child(new_step)
			new_step.owner = get_tree().edited_scene_root
			
			new_step.position = step_pos
		new_mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, step_pos))
	
	if smooth:
		var new_ramp := CollisionShape3D.new()
		var new_shape := ConvexPolygonShape3D.new()
		var float_steps: float = float(num_steps)
		var ramp_height: float = step_height * float_steps
		var ramp_z: float = step_size.z * float_steps
		var plank_thickness: float = step_size.y
		var height_diff: float = step_height - step_size.y
		
		var points := PackedVector3Array([
										Vector3(-step_size.x / 2.0, 0.0, ramp_z / 2.0),# TBL
										Vector3(-step_size.x / 2.0, (ramp_height) - step_size.y - height_diff, (-ramp_z / 2.0) + step_size.z),# TFL
										Vector3(-step_size.x / 2.0, (ramp_height) - step_size.y - height_diff, (-ramp_z / 2.0)),# TFL2
										Vector3(-step_size.x / 2.0, (ramp_height) - (step_size.y * 2.0) - height_diff, (-ramp_z / 2.0)),# BFL
										Vector3(-step_size.x / 2.0, -plank_thickness, (ramp_z / 2.0) - step_size.z),# BBL
										Vector3(-step_size.x / 2.0, -plank_thickness, ramp_z / 2.0),# BBL2
										
										Vector3(step_size.x / 2.0, 0.0, ramp_z / 2.0),# TBR
										Vector3(step_size.x / 2.0, (ramp_height) - step_size.y - height_diff, (-ramp_z / 2.0) + step_size.z),# TFR
										Vector3(step_size.x / 2.0, (ramp_height) - step_size.y - height_diff, (-ramp_z / 2.0)),# TFR2
										Vector3(step_size.x / 2.0, (ramp_height) - (step_size.y * 2.0) - height_diff, (-ramp_z / 2.0)),# BFR
										Vector3(step_size.x / 2.0, -plank_thickness, (ramp_z / 2.0) - step_size.z),# BBR
										Vector3(step_size.x / 2.0, -plank_thickness, ramp_z / 2.0),# BBR2
										])
		
		new_shape.points = points
		
		new_ramp.shape = new_shape
		add_child(new_ramp)
		new_ramp.owner = get_tree().edited_scene_root
		new_ramp.position.z = (-ramp_z / 2.0) + (step_size.z / 2.0)
		new_ramp.position.y = step_size.y
	
	new_mmi.multimesh = new_mm
	add_child(new_mmi)
	new_mmi.owner = get_tree().edited_scene_root
	add_to_group("nav")
