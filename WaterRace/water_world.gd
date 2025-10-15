@tool
extends Node3D


const WAVE_CONSTANT: float = 75.0
const WAVE_DAMP: float = 0.997
const BOAT_DISP_STRENGTH: float = 7.0
const WALL_OFFSET: float = 5.0


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
@export var boats: Array[Boat] = []


var hmap: HeightMapShape3D
var movement := Vector2.ZERO
var image: Image
var water_mat: ShaderMaterial
var water_mesh_plane: PlaneMesh
var wave_speeds: PackedFloat64Array = []
var wave_accels: PackedFloat64Array = []
var wave_disps: PackedFloat64Array = []


@onready var water_surface: StaticBody3D = $WaterSurface
@onready var collision_shape_3d: CollisionShape3D = $WaterSurface/CollisionShape3D
@onready var water_mesh: MeshInstance3D = $WaterSurface/WaterMesh
@onready var wall_zm: CollisionShape3D = $Walls/WallZM
@onready var wall_zp: CollisionShape3D = $Walls/WallZP
@onready var wall_xm: CollisionShape3D = $Walls/WallXM
@onready var wall_xp: CollisionShape3D = $Walls/WallXP


func _ready() -> void:
	wall_xm.position.x = (-dimensions.x / 2.0) - WALL_OFFSET
	wall_xp.position.x = (dimensions.x / 2.0) + WALL_OFFSET
	wall_zm.position.z = (-dimensions.y / 2.0) - WALL_OFFSET
	wall_zp.position.z = (dimensions.y / 2.0) + WALL_OFFSET
	hmap = collision_shape_3d.shape
	image = Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RH)
	wave_speeds.resize(dimensions.x * dimensions.y)
	wave_speeds.fill(0.0)
	wave_accels.resize(dimensions.x * dimensions.y)
	wave_accels.fill(0.0)
	wave_disps.resize(dimensions.x * dimensions.y)
	wave_disps.fill(0.0)
	water_mat = water_mesh.material_override
	water_mesh_plane = water_mesh.mesh
	if hmap:
		hmap.map_width = dimensions.x
		hmap.map_depth = dimensions.y
	if image:
		image = Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RH)
	if water_mesh_plane:
		water_mesh_plane.size = dimensions
	
	if not Engine.is_editor_hint():
		for boat in boats:
			boat.boat_under_water.connect(_on_boat_under_water)


func _physics_process(delta: float) -> void:
	make_heightmap(delta)
	movement.x += delta * movement_speed
	movement.y += delta * movement_speed


func make_heightmap(delta: float) -> void:
	# do this from an image
	
	#var map_data: PackedFloat32Array = []
	var size_x: int = hmap.map_width
	var size_z: int = hmap.map_depth
	
	var chunk_x := float(0)
	var chunk_z := float(0)
	
	var chunk_center := Vector2(chunk_x * 0.0, chunk_z * 0.0)
	
	var start_x: float = chunk_center.x - (float(size_x) * 0.5)
	var start_z: float = chunk_center.y - (float(size_z) * 0.5)
	
	var end_x: float = chunk_center.x + (float(size_x) * 0.5)
	var end_z: float = chunk_center.y + (float(size_z) * 0.5)
	
	var new_wave_disps := wave_disps.duplicate()
	
	for x_division: int in range(1, size_x - 1):
		for z_division: int in range(1, size_z - 1):
			var i: int = (x_division * size_x) + z_division
			var ixp: int = ((x_division + 1) * size_x) + z_division
			var ixm: int = ((x_division - 1) * size_x) + z_division
			var izp: int = (x_division * size_x) + z_division + 1
			var izm: int = (x_division * size_x) + z_division - 1
			
			var pix: float = wave_disps[i]
			var pix_xp: float = wave_disps[ixp]
			var pix_zp: float = wave_disps[izp]
			var pix_xm: float = wave_disps[ixm]
			var pix_zm: float = wave_disps[izm]
			
			var dx: float = (pix_xp - pix) - (pix - pix_xm)
			var dz: float = (pix_zp - pix) - (pix - pix_zm)
			
			wave_accels[i] = WAVE_CONSTANT * (dx + dz)
			wave_speeds[i] += wave_accels[i] * delta
			var new_value: float = pix + (delta * wave_speeds[i])
			new_value *= WAVE_DAMP
			new_wave_disps[i] = new_value
	
	wave_disps = new_wave_disps
	
	for x_division: int in size_x:
		var progress_x := float(x_division) / float(size_x)
		var x_coord := lerpf(end_x, start_x, progress_x)
		
		for z_division: int in size_z:
			var i: int = ((x_division) * size_x) + (z_division)
			if x_division == 0 or x_division == size_x - 1\
			or z_division == 0 or z_division == size_z - 1:
				wave_disps[i] = 0.0
			var progress_z := float(z_division) / float(size_z)
			var z_coord := lerpf(start_z, end_z, progress_z)
			
			var coord_2d := Vector2(x_coord, z_coord)
			var nval := passive_noise.get_noise_2dv(coord_2d + movement)
			var result: float = (nval * passive_strength) + wave_disps[i]
			
			var clr := Color(result, result, result)
			
			image.set_pixel(x_division, z_division, clr)
	
	#for x_division: int in range(1, size_x - 1):
		#for z_division: int in range(1, size_z - 1):
			#var i: int = (x_division * size_x) + z_division
			#
			#var clr := Color(wave_disps[i], wave_disps[i], wave_disps[i])
			#
			#image.set_pixel(x_division, z_division, clr)
	
	hmap.update_map_data_from_image(image, 0.0, 1.0)
	water_mat.set_shader_parameter("WaterMap", ImageTexture.create_from_image(image))
	water_mat.set_shader_parameter("Strength", 1.0)


func _on_boat_under_water(depth: float, pos: Vector2) -> void:
	var pos_mapped: Vector2 = pos + (dimensions / 2.0)
	
	var idx: int = (roundi(pos_mapped.x) * dimensions.x) + roundi(pos_mapped.y)
	idx = clampi(idx, 0, (dimensions.x * dimensions.y) - 1)
	var strength: float = clampf(depth * BOAT_DISP_STRENGTH, 0.0, BOAT_DISP_STRENGTH)
	
	#wave_disps[idx] -= strength
	wave_disps[idx] = lerpf(wave_disps[idx], -strength, 0.3)
	#wave_disps[idx] *= 0.9
	
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			var new_pos_mapped := pos_mapped + Vector2(x, z)
			if not is_equal_approx(new_pos_mapped.x, 0.0)\
			and not is_equal_approx(new_pos_mapped.x, dimensions.x)\
			and not is_equal_approx(new_pos_mapped.y, 0.0)\
			and not is_equal_approx(new_pos_mapped.y, dimensions.y):
				idx = (roundi(pos_mapped.x + x) * dimensions.x) + roundi(pos_mapped.y + z)
				idx = clampi(idx, 0, (dimensions.x * dimensions.y) - 1)
				strength = clampf(depth * BOAT_DISP_STRENGTH, 0.0, BOAT_DISP_STRENGTH) * 0.5
				
				#wave_disps[idx] -= strength
				wave_disps[idx] = lerpf(wave_disps[idx], -strength, 0.3)
				#wave_disps[idx] *= 0.9
