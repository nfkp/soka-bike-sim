extends RigidBody3D
class_name Ball

@export var stoppers : Array[Stopper]
var current_normal_force := 0.0
var normal_force_accumulator := 0.0
var has_fallen := false
signal jumpscare

func _ready() -> void:
	for stopper in stoppers:
		stopper.spring_damping = stopper.damping_zeta_value * 2 * sqrt(stopper.spring_constant * mass)

func _physics_process(_delta: float) -> void:
	for stopper in stoppers:
		if current_normal_force <= 0.: current_normal_force = 1.
		stopper._do_collision_physics(self)
	current_normal_force = normal_force_accumulator
	normal_force_accumulator = 0.
	if not has_fallen and global_position.y <= -10.:
		jumpscare.emit()
		has_fallen = true

func _get_point_velocity(point: Vector3) -> Vector3:
	var actual_center_of_mass := global_position + global_basis * center_of_mass
	return linear_velocity + angular_velocity.cross(point - actual_center_of_mass)
