@tool
extends StaticBody3D
class_name Platform


@export var size := Vector3(20.0, 1.0, 20.0):
	set(value):
		size = value.clamp(Vector3(0.1, 0.1, 0.1), Vector3(1000.0, 1000.0, 1000.0))
		_parameter_changed()
@export var _material: Material


var slowly_rotating := false


var collision_shape_3d: CollisionShape3D
var mesh_instance_3d: MeshInstance3D


func _enter_tree() -> void:
	for child in get_children():
		child.queue_free()
	collision_shape_3d = CollisionShape3D.new()
	mesh_instance_3d = MeshInstance3D.new()
	add_child(collision_shape_3d)
	add_child(mesh_instance_3d)
	set_meta("_edit_group_", true)
	collision_shape_3d.set_meta("_edit_group_", true)
	mesh_instance_3d.set_meta("_edit_group_", true)
	collision_shape_3d.owner = get_tree().edited_scene_root
	mesh_instance_3d.owner = get_tree().edited_scene_root
	collision_shape_3d.shape = BoxShape3D.new()
	collision_shape_3d.shape.size = size
	mesh_instance_3d.mesh = BoxMesh.new()
	mesh_instance_3d.mesh.size = size
	if _material:
		mesh_instance_3d.set_surface_override_material(0, _material)
	add_to_group("nav")


func _parameter_changed():
	if collision_shape_3d and mesh_instance_3d:
		collision_shape_3d.shape.size = size
		mesh_instance_3d.mesh.size = size
