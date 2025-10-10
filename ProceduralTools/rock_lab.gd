@tool
extends Node3D
class_name Rock


@export_tool_button("Make New Rock") var new_rock = make_new_rock
@export var smooth_normals := false
@export var num_points: int = 20
@export var radius: float = 1.0


var procedural_mesh: ProceduralMesh


func make_new_rock():
	if not procedural_mesh:
		procedural_mesh = ProceduralMesh.new()
		add_child(procedural_mesh)
		procedural_mesh.owner = get_tree().edited_scene_root
	var pts := procedural_mesh.generate_sphere_points(radius, num_points)
	procedural_mesh.create_convex_hull(pts, false, smooth_normals)
