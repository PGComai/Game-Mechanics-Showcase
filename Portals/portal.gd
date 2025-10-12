extends Node3D
class_name Portal


var red := true


@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var sub_viewport: SubViewport = $SubViewport
@onready var camera_3d: Camera3D = $SubViewport/Camera3D
@onready var mesh_instance_3d_empty: MeshInstance3D = $MeshInstance3DEmpty
@onready var cam_show: MeshInstance3D = $SubViewport/Camera3D/CamShow
@onready var virtual_transform: Node3D = $VirtualTransform
@onready var top_left: Node3D = $TopLeft
@onready var bottom_right: Node3D = $BottomRight
@onready var inner_collider: StaticBody3D = $InnerCollider
@onready var inner_detector: Area3D = $InnerDetector
@onready var outer_detector: Area3D = $OuterDetector
@onready var player_detector: Area3D = $PlayerDetector


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
		var player_cam: Camera3D = player.camera_3d
		
		camera_3d.global_transform = other_portal.virtual_transform.global_transform\
		* virtual_transform.global_transform.inverse() * player_cam.global_transform
		
		var dist_to_portal := player_cam.global_position.distance_to(global_position)
		camera_3d.near = dist_to_portal
			
		var collider_on := inner_detector.get_overlapping_bodies() and not outer_detector.get_overlapping_bodies()
		if player_detector.get_overlapping_bodies().has(player):
			inner_collider.set_collision_layer_value(2, collider_on)
			inner_collider.set_collision_mask_value(2, collider_on)
			other_portal.inner_collider.set_collision_layer_value(2, collider_on)
			other_portal.inner_collider.set_collision_mask_value(2, collider_on)
			player.set_collision_layer_value(1, not collider_on)
			player.set_collision_mask_value(1, not collider_on)
			var pl := Plane(global_basis.z, global_position)
			if not pl.is_point_over(player.camera_3d.global_position):
				teleport_player(player, other_portal)


func teleport_player(player: Player, other_portal: Portal) -> void:
	player.global_transform = other_portal.virtual_transform.global_transform\
	* virtual_transform.global_transform.inverse() * player.global_transform
	player.velocity = other_portal.virtual_transform.global_basis\
	* virtual_transform.global_basis.inverse() * player.velocity
