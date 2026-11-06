class_name PlayerController extends CharacterBody3D

var _input_dir : Vector2 = Vector2.ZERO
var _movement_velocity : Vector3 = Vector3.ZERO
var speed : float = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	_input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	move_and_slide()
	

func update_rotation(rotation_input) -> void:
	global_transform.basis = Basis.from_euler(rotation_input)
