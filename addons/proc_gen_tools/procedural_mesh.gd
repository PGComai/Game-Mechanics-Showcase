@tool
extends MeshInstance3D
class_name ProceduralMesh


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func random_vector() -> Vector3:
	return Vector3(randfn(0.0, 1.0),
					randfn(0.0, 1.0),
					randfn(0.0, 1.0)).normalized()


func generate_sphere_points(radius: float,
							num_points: int,
							separation_iterations: int = 50,
							separation_power: float = 2.0,
							separation_rotation_divisor: float = 8.0,
							origin: Vector3 = Vector3.ZERO) -> PackedVector3Array:
	var points := PackedVector3Array([])
	
	for i in num_points:
		var new_point = random_vector() * radius
		points.append(new_point)
	
	var psize = points.size()
	
	for i in separation_iterations:
		for pi in psize:
			for pi2 in psize:
				var point = points[pi]
				var point2 = points[pi2]
				if point == point2:
					pass
				else:
					var ang_between = point.angle_to(point2)
					var ang_remapped = ang_between / PI
					var rotation_strength = (pow(1.0 - ang_remapped, separation_power) *
											(PI/(separation_rotation_divisor + float(i))))
					var axis = point.cross(point2).normalized()
					points[pi] = point.rotated(axis, -rotation_strength)
					points[pi2] = point2.rotated(axis, rotation_strength)
	
	for i in points.size():
		points[i] += origin
	
	return points


func create_convex_hull(points: PackedVector3Array, normals_inward := false, smooth_normals := true, holes: Array[PackedVector3Array] = []) -> Array:
	var triangles := Dictionary({})
	var all_possible_triangles = []
	var last_sphere_index: int = 0
	var hole_indices := {}
	
	if holes.size() > 0:
		for hole in holes:
			var regular_points_array := Array(points)
			
			var hole_center := Vector3.ZERO
			
			for pt in hole:
				hole_center += pt
			
			hole_center /= float(hole.size())
			
			var hole_radius: float = 0.0
			
			for pt in hole:
				hole_radius = maxf(hole_radius, pt.distance_to(hole_center))
			
			for i in points.size():
				var point = points[i]
				if point.distance_squared_to(hole_center) < pow(hole_radius * 1.2, 2.0):
					regular_points_array.erase(point)
			
			points = PackedVector3Array(regular_points_array)
		
		last_sphere_index = points.size() - 1
		
		for hole in holes:
			var current_last_index = points.size() - 1
			
			var hole_location = [current_last_index + 1, points.size() + hole.size() - 1]
			hole_indices[hole_location] = hole
			
			points.append_array(hole)
	
	
	var psize = points.size()
	
	for i in psize:
		for ii in psize:
			for iii in psize:
				if i != ii and ii != iii and i != iii:
					var all_points_are_hole = (i > last_sphere_index and
												ii > last_sphere_index and
												iii > last_sphere_index) and holes.size() > 0
					
					if all_points_are_hole:
						var hole_i: Array
						for di in hole_indices:
							if i >= di[0] and i <= di[1]:
								hole_i = di
						
						if (ii >= hole_i[0] and ii <= hole_i[1] and
							iii >= hole_i[0] and iii <= hole_i[1]):
							pass
						else:
							all_possible_triangles.append([i, ii, iii])
					else:
						all_possible_triangles.append([i, ii, iii])
					
	
	for possible_triangle in all_possible_triangles:
		var p = points[possible_triangle[0]]
		var p1 = points[possible_triangle[1]]
		var p2 = points[possible_triangle[2]]
		
		var t1 = [p, p1, p2]
		var t2 = [p, p2, p1]
		
		var i1 = [possible_triangle[0], possible_triangle[1], possible_triangle[2]]
		var i2 = [possible_triangle[0], possible_triangle[2], possible_triangle[1]]
		
		var t1_good := true
		var t2_good := true
		
		var plane1 = Plane(t1[0], t1[1], t1[2])
		var plane2 = Plane(t2[0], t2[1], t2[2])
		
		var c1 = plane1.get_center()
		var c2 = plane2.get_center()
		
		for i in psize:
			if possible_triangle.has(i):
				pass
			else:
				if plane1.is_point_over(points[i]):
					t1_good = false
				if plane2.is_point_over(points[i]):
					t2_good = false
		
		if (t1_good and normals_inward) or (t2_good and not normals_inward):
			var n2 = plane2.normal
			
			if not triangles.has(n2):
				triangles[n2] = PackedInt32Array(i2)
		if (t2_good and normals_inward) or (t1_good and not normals_inward):
			var n1 = plane1.normal
			
			if not triangles.has(n1):
				triangles[n1] = PackedInt32Array(i1)
	
	var hull_am = ArrayMesh.new()
	
	var arrays_hull = []
	arrays_hull.resize(Mesh.ARRAY_MAX)
	
	var verts_hull: PackedVector3Array
	
	if smooth_normals:
		verts_hull = points
	else:
		verts_hull = PackedVector3Array([])
	var norms_hull := PackedVector3Array([])
	var indices_hull := PackedInt32Array([])
	
	var unsmoothed_normals = []
	
	if smooth_normals:
		for hi in verts_hull.size():
			unsmoothed_normals.append([])
			for n in triangles:
				var tri_indices = triangles[n]
				if tri_indices.has(hi):
					unsmoothed_normals[hi].append(n)
		
		for uns: Array in unsmoothed_normals:
			if uns.size() > 0:
				var avg_vector := Vector3.ZERO
				for un in uns:
					avg_vector += un
				avg_vector /= float(uns.size())
				norms_hull.append(avg_vector.normalized())
			else:
				norms_hull.append(Vector3.UP)
	
	for tri_norm in triangles:
		var tri = triangles[tri_norm]
		if not smooth_normals:
			var p0: Vector3 = points[tri[0]]
			var p1: Vector3 = points[tri[1]]
			var p2: Vector3 = points[tri[2]]
			
			var n: Vector3 = Plane(p0, p1, p2).normal
			
			verts_hull.append_array([p0, p1, p2])
			norms_hull.append_array([n, n, n])
			
		indices_hull.append_array(tri)
	
	arrays_hull[Mesh.ARRAY_VERTEX] = verts_hull
	arrays_hull[Mesh.ARRAY_NORMAL] = norms_hull
	if smooth_normals:
		arrays_hull[Mesh.ARRAY_INDEX] = indices_hull
	
	hull_am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_hull)
	
	mesh = hull_am
	
	return [triangles, points]
