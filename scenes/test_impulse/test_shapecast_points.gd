extends ShapeCast3D


func _physics_process(delta: float) -> void:
	if not is_colliding(): return
	
	var points : PackedVector3Array
	for i in range(get_collision_count()):
		points.append(get_collision_point(i))
	DebugDraw3D.draw_points(points)
