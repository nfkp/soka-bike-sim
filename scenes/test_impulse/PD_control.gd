extends Node
class_name PDController

@export var proportional_gain := 0.5
@export var derivative_gain := 0.5
var pid_previous_error := 0.

func calculate(current_value: Variant, target: Variant) -> Variant:
	var error = target - current_value
	var pid_derivative = (error - pid_previous_error) / get_physics_process_delta_time()
	pid_previous_error = error
	return proportional_gain * error + derivative_gain * pid_derivative
