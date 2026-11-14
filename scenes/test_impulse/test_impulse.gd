extends RayCast3D
class_name Stopper

var local_mass_scale := 1.0
@export var spring_constant := 15000.
@export var damping_zeta_value := 0.5
var spring_damping := 700.
@export var wheel_mesh : MeshInstance3D
@export var wheel_radius := 0.371
var x_force : Vector3
var y_force : Vector3
var z_force : Vector3
@export_category("Motor Settings")
@export var is_motor := false
@export var acceleration := 1.
@export var pedal_ratio := 0.5
@export var maximum_speed := 32.
var f_speed := 0.
@export var speed_control : PDController
var target_speed := 0.
@export_category("Steer Settings")
@export var is_steer := false
@export var handlebar : MeshInstance3D
@export var proportional_gain := 0.5
@export var derivative_gain := 0.5
var pid_previous_error := 0.
@export var self_steer_control : PDController
@export_category("Debug")
@export var show_forces := false
@export var show_point_velocity := false

var interpolated_input = 0.

func _do_collision_physics(body: Ball) -> void:
	var body_basis := body.global_basis.orthonormalized()
	var wheel_basis := wheel_mesh.global_basis.orthonormalized()
	wheel_mesh.rotate_x(f_speed / wheel_radius * get_physics_process_delta_time())
	
	if is_steer:
		var steer_input := Input.get_axis("KEY_LEFT", "KEY_RIGHT")
		
		interpolated_input = move_toward(interpolated_input, steer_input, get_physics_process_delta_time() * 1.)
		body.center_of_mass.x = -steer_input * 0.1
		
		var error := asin(Vector3.UP.cross(body_basis.z).dot(body_basis.y))
		var output : float = -self_steer_control.calculate(error, 0.)
		output = clampf(output, -PI * 0.5, PI * 0.5)
		
		handlebar.set_rotation(Vector3(-23. * PI / 180., output, 0.))
		
		if Input.is_action_just_pressed("ui_accept"):
			handlebar.set_rotation_order(EULER_ORDER_XYZ)
			handlebar.set_rotation(Vector3(-23. * PI / 180., 0., 0.))
			handlebar.set_rotation_order(EULER_ORDER_YXZ)
			body.set_position(Vector3.ZERO)
			body.set_rotation(Vector3.ZERO)
	
	if not is_colliding(): return
	
	var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
	# y force
	var rest_dist : float = 0.5
	var collision_normal = get_collision_normal()
	
	var contact := get_collision_point()
	var spring_len := global_position.distance_to(contact)
	var offset = rest_dist - spring_len
	
	var world_vel := body._get_point_velocity(contact)
	var relative_vel := body_basis.y.dot(world_vel)
	var spring_damp_force := spring_damping * relative_vel
	
	var spring_force : float = spring_constant * offset
	var suspension_force := spring_force - spring_damp_force
	
	y_force = suspension_force * collision_normal * Vector3.UP.dot(collision_normal)
	var force_pos_offset := contact - body.global_position
	
	# z force
	var forward_dir := wheel_basis.x.cross(collision_normal).normalized()
	f_speed = world_vel.dot(forward_dir)
	var z_friction := 0.
	
	if is_motor:
		var acceleration_input := Input.get_action_strength("KEY_UP")
		acceleration_input = Input.get_axis("KEY_DOWN", "KEY_UP")
		target_speed += acceleration_input * get_physics_process_delta_time()
		target_speed = clampf(target_speed, 0., 10.)
		if Input.is_action_pressed("KEY_DOWN"):
			z_friction = 0.2
			target_speed = 0.
		
		z_force = forward_dir * acceleration_input * 100.
		z_force += 4. * -forward_dir * f_speed * z_friction / get_physics_process_delta_time()
	
	# x force
	var x_direction := collision_normal.cross(wheel_basis.z).normalized()
	
	x_direction = forward_dir.rotated(collision_normal, PI * 0.5)
	
	var steering_x_vel := x_direction.dot(world_vel)
	var x_traction := 1.0
	if x_force.length()/y_force.length() > 1.4:
		x_traction = 0.4
	x_force = -x_direction * steering_x_vel * x_traction * body.mass * gravity * 0.5
	
		
	var total_force := x_force + y_force + z_force
	
	if show_point_velocity:
		print(absf(forward_dir.dot(world_vel.normalized())))
		DebugDraw3D.draw_arrow_ray(contact, world_vel.normalized(), 1., Color(1.0, 0.372, 0.262, 1.0), 0.01)
		DebugDraw3D.draw_arrow_ray(contact, forward_dir, 1., Color(0.998, 0.356, 0.409, 1.0), 0.01)
		DebugDraw3D.draw_arrow_ray(contact, x_direction, 1., Color(0.077, 0.694, 0.705, 1.0), 0.01)
	
	if show_forces:
		DebugDraw3D.draw_arrow_ray(contact, x_force/body.mass + Vector3(0.001, 0., 0.), 1., Color(1.0, 0.0, 0.0, 1.0), 0.01)
		DebugDraw3D.draw_arrow_ray(contact, y_force/body.mass, 0.3, Color(0.0, 1.0, 0.0, 1.0), 0.01)
		DebugDraw3D.draw_arrow_ray(contact, z_force/body.mass, 1., Color(0.0, 0.0, 1.0, 1.0), 0.01)
	
	if absf(f_speed) < 0.1:
		var susp := global_basis.y * suspension_force
		z_force.z -= susp.z * body_basis.y.dot(Vector3.UP)
		x_force.x += susp.x * body_basis.y.dot(Vector3.UP)
	
	var drag = -body.linear_velocity
	
	body.apply_force(total_force, force_pos_offset)
	body.apply_central_force(drag)
	
	body.normal_force_accumulator += y_force.length()
