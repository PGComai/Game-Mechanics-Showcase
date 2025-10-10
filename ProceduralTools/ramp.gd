@tool
extends StaticBody3D
class_name Ramp


@export var size := Vector3(1.0, 1.0, 1.0):
	set(value):
		size = clamp(value, Vector3(0.5, 0.5, 0.5), Vector3(20.0, 20.0, 20.0))
		if collision_shape_3d:
			make_collider()
@export var plank := false:
	set(value):
		plank = value
		if collision_shape_3d:
			make_collider()
@export var plank_thickness: float = 0.2:
	set(value):
		plank_thickness = clampf(value, 0.1, 10.0)
		if collision_shape_3d:
			make_collider()


var collision_shape_3d: CollisionShape3D
var mesh_instance_3d: MeshInstance3D


func _ready() -> void:
	collision_shape_3d = CollisionShape3D.new()
	mesh_instance_3d = MeshInstance3D.new()
	add_child(collision_shape_3d)
	add_child(mesh_instance_3d)
	make_collider()


func make_collider():
	var new_shape := ConvexPolygonShape3D.new()
	
	var am := ArrayMesh.new()
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var verts: PackedVector3Array
	var norms: PackedVector3Array
	
	if not plank:
		var points := PackedVector3Array([Vector3(-size.x / 2.0, 0.0, -size.z / 2.0),
										Vector3(-size.x / 2.0, 0.0, size.z / 2.0),
										Vector3(-size.x / 2.0, size.y, -size.z / 2.0),
										Vector3(size.x / 2.0, 0.0, -size.z / 2.0),
										Vector3(size.x / 2.0, 0.0, size.z / 2.0),
										Vector3(size.x / 2.0, size.y, -size.z / 2.0)])
		
		new_shape.points = points
		
		collision_shape_3d.shape = new_shape
		
		var hyp_norm := Plane(points[1], points[2], points[5]).normal
		
		verts = PackedVector3Array([points[0], points[2], points[1],
										points[3], points[4], points[5],
										points[1], points[2], points[5],
										points[4], points[1], points[5],
										points[0], points[5], points[2],
										points[0], points[3], points[5],
										points[0], points[1], points[3],
										points[1], points[4], points[3]])
		norms = PackedVector3Array([Vector3.LEFT, Vector3.LEFT, Vector3.LEFT,
										Vector3.RIGHT, Vector3.RIGHT, Vector3.RIGHT,
										hyp_norm, hyp_norm, hyp_norm,
										hyp_norm, hyp_norm, hyp_norm,
										Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD,
										Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD,
										Vector3.DOWN, Vector3.DOWN, Vector3.DOWN,
										Vector3.DOWN, Vector3.DOWN, Vector3.DOWN])
	else:
		var points := PackedVector3Array([Vector3(-size.x / 2.0, size.y - plank_thickness, -size.z / 2.0),# BFL
										Vector3(-size.x / 2.0, 0.0, size.z / 2.0),# TBL
										Vector3(-size.x / 2.0, -plank_thickness, size.z / 2.0),# BBL
										Vector3(-size.x / 2.0, size.y, -size.z / 2.0),# TFL
										Vector3(size.x / 2.0, size.y - plank_thickness, -size.z / 2.0),# BFR
										Vector3(size.x / 2.0, 0.0, size.z / 2.0),# TBR
										Vector3(size.x / 2.0, -plank_thickness, size.z / 2.0),# BBR
										Vector3(size.x / 2.0, size.y, -size.z / 2.0)])# TFR
		
		new_shape.points = points
		
		collision_shape_3d.shape = new_shape
		
		var hyp_norm := Plane(points[1], points[3], points[7]).normal
		
		verts = PackedVector3Array([points[0], points[3], points[2],
										points[1], points[2], points[3],
										points[4], points[6], points[7],
										points[5], points[7], points[6],
										points[1], points[3], points[7],
										points[1], points[7], points[5],
										points[0], points[2], points[6],
										points[0], points[6], points[4],
										points[1], points[6], points[2],
										points[1], points[5], points[6],
										points[0], points[7], points[3],
										points[0], points[4], points[7],])
		norms = PackedVector3Array([Vector3.LEFT, Vector3.LEFT, Vector3.LEFT,
										Vector3.LEFT, Vector3.LEFT, Vector3.LEFT,
										Vector3.RIGHT, Vector3.RIGHT, Vector3.RIGHT,
										Vector3.RIGHT, Vector3.RIGHT, Vector3.RIGHT,
										hyp_norm, hyp_norm, hyp_norm,
										hyp_norm, hyp_norm, hyp_norm,
										-hyp_norm, -hyp_norm, -hyp_norm,
										-hyp_norm, -hyp_norm, -hyp_norm,
										Vector3.BACK, Vector3.BACK, Vector3.BACK,
										Vector3.BACK, Vector3.BACK, Vector3.BACK,
										Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD,
										Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD])
	
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	mesh_instance_3d.mesh = am
