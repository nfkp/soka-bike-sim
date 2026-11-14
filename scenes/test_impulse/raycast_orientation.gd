extends Node3D
class_name RaycastOrientation

func _physics_process(_delta: float) -> void:
	global_basis = Basis.looking_at(Vector3(0., 1., 0.), Vector3(0., 0., 1.))
