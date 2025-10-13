@tool
extends Node3D


@export var passive_noise: FastNoiseLite
@export var movement_speed: float = 5.0
@export var passive_strength: float = 1.0
@export var dimensions := Vector2i(64, 64):
	set(value):
		dimensions = value
		if hmap:
			hmap.map_width = dimensions.x
			hmap.map_depth = dimensions.y
		if image:
			image = Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RH)
		if water_mesh_plane:
			water_mesh_plane.size = dimensions


var hmap: HeightMapShape3D
var movement := Vector2.ZERO
var image: Image
var water_mat: ShaderMaterial
var water_mesh_plane: PlaneMesh


@onready var water_surface: StaticBody3D = $WaterSurface
@onready var collision_shape_3d: CollisionShape3D = $WaterSurface/CollisionShape3D
@onready var water_mesh: MeshInstance3D = $WaterSurface/WaterMesh


func _ready() -> void:
	hmap = collision_shape_3d.shape
	image = Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RH)
	water_mat = water_mesh.material_override
	water_mesh_plane = water_mesh.mesh


func _physics_process(delta: float) -> void:
	make_heightmap()
	movement.x += delta * movement_speed
	movement.y += delta * movement_speed


func make_heightmap() -> void:
	# do this from an image
	
	var map_data: PackedFloat32Array = []
	var size_x: int = hmap.map_width
	var size_z: int = hmap.map_depth
	
	var chunk_x := float(0)
	var chunk_z := float(0)
	
	var chunk_center := Vector2(chunk_x * 0.0, chunk_z * 0.0)
	
	var start_x: float = chunk_center.x - (float(size_x) * 0.5)
	var start_z: float = chunk_center.y - (float(size_z) * 0.5)
	
	var end_x: float = chunk_center.x + (float(size_x) * 0.5)
	var end_z: float = chunk_center.y + (float(size_z) * 0.5)
	
	for x_division: int in size_x:
		var progress_x := float(x_division) / float(size_x)
		var x_coord := lerpf(end_x, start_x, progress_x)
		
		for z_division: int in size_z:
			var progress_z := float(z_division) / float(size_z)
			var z_coord := lerpf(start_z, end_z, progress_z)
			
			var coord_2d := Vector2(x_coord, z_coord)
			var nval := passive_noise.get_noise_2dv(coord_2d + movement)
			var result: float = nval * passive_strength
			var result_mapped: float = remap(nval, -1.0, 1.0, 0.0, 1.0)
			var clr := Color(result_mapped, result_mapped, result_mapped)
			map_data.append(result)
			image.set_pixel(x_division, z_division, clr)
	
	hmap.update_map_data_from_image(image, 0.0, passive_strength)
	#var color_image: Image = image.duplicate()
	#color_image.convert(Image.FORMAT_RGB8)
	water_mat.set_shader_parameter("WaterMap", ImageTexture.create_from_image(image))
	water_mat.set_shader_parameter("Strength", passive_strength)
