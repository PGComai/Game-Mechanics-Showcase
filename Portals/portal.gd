extends Node3D
class_name Portal


var red := true


@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var sub_viewport: SubViewport = $SubViewport
@onready var camera_3d: Camera3D = $SubViewport/Camera3D
@onready var mesh_instance_3d_empty: MeshInstance3D = $MeshInstance3DEmpty
@onready var cam_show: MeshInstance3D = $SubViewport/Camera3D/CamShow
@onready var virtual_transform: Node3D = $VirtualTransform


func _ready() -> void:
	var mat: ShaderMaterial = mesh_instance_3d.material_override
	var cam_mat: StandardMaterial3D = cam_show.material_override
	if red:
		add_to_group("portal_red")
		mat.set_shader_parameter("OutlineColor", Color.RED)
		cam_mat.albedo_color = Color.RED
	else:
		virtual_transform.rotation.y = PI
		add_to_group("portal_blue")
		mat.set_shader_parameter("OutlineColor", Color.BLUE)
		cam_mat.albedo_color = Color.BLUE
	
	if get_tree().get_node_count_in_group("portal") == 2:
		mesh_instance_3d.visible = true
		mesh_instance_3d_empty.visible = false
	else:
		mesh_instance_3d.visible = false
		mesh_instance_3d_empty.visible = true


func _process(delta: float) -> void:
	var other_portal: Portal
	
	if red:
		if get_tree().get_node_count_in_group("portal_blue"):
			other_portal = get_tree().get_first_node_in_group("portal_blue")
	else:
		if get_tree().get_node_count_in_group("portal_red"):
			other_portal = get_tree().get_first_node_in_group("portal_red")
	
	if other_portal:
		mesh_instance_3d.visible = true
		mesh_instance_3d_empty.visible = false
	else:
		mesh_instance_3d.visible = false
		mesh_instance_3d_empty.visible = true
	
	var player: Player = get_tree().get_first_node_in_group("player")
	
	if player and other_portal:
		var diagonal: float = sqrt(pow(1.1, 2.0) + pow(2.2, 2.0))
		var player_cam: Camera3D = player.camera_3d
		
		var dist_to_portal := player_cam.global_position.distance_to(global_position)
		var cam_local_pos := virtual_transform.to_local(player_cam.global_position)
		var cam_local_basis := virtual_transform.global_basis.inverse() * player_cam.global_basis
		camera_3d.position = other_portal.virtual_transform.to_global(cam_local_pos)
		#camera_3d.global_basis = other_portal.virtual_transform.global_basis * cam_local_basis
		camera_3d.global_basis = Basis.looking_at(other_portal.virtual_transform.global_basis * -cam_local_pos)
		camera_3d.near = dist_to_portal
		var offset: Vector3 = player_cam.to_local(global_position)
		var cam_frust := player_cam.get_frustum()
		#camera_3d.set_frustum(1.0 / dist_to_portal, -Vector2(offset.x, offset.y), dist_to_portal, 4000.0)
