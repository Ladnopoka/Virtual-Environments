extends CharacterBody3D

var speed = 5.0
const WALK_SPEED = 5.0
const SPRINT_SPEED = 11.0
const ACCELERATION = 20
const FRICTION = 2
const JUMP_VELOCITY = 8
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") # gravity from project settings 

var mouse_position
#@onready var base_camera = $Head/Camera3D
@onready var base_camera = $Camera3D

#@onready var model = $MeshInstance3D
#@onready var model = $"."
@onready var model = $Head

func _physics_process(delta):
	apply_gravity(delta)
	movement(delta)
	update_orientation()
	apply_jump()
	move_and_slide()
	
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func movement(delta): 
	# Handle Sprint
	if Input.is_key_pressed(KEY_SHIFT):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	var input_dir = Vector2(
		int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A)),
		int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
	)
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		apply_velocity(direction, delta) 
	else:
		apply_friction(direction, delta) 
		
# velocity with acceleration
func apply_velocity(direction, delta):
	velocity.x = move_toward(velocity.x, direction.x * speed, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, ACCELERATION * delta)
	
# deceleration through friction
func apply_friction(direction, delta):
	velocity.x = move_toward(velocity.x, 0, FRICTION)
	velocity.z = move_toward(velocity.z, 0, FRICTION) 
	
func apply_jump():
	if is_on_floor():
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY
		
func update_orientation():
	# All the logic related to updating the character's orientation goes here
	var space_state = get_world_3d().direct_space_state
	mouse_position = get_viewport().get_mouse_position()
	
	print(mouse_position)

	var ray_origin = base_camera.project_ray_origin(mouse_position)
	var ray_end = ray_origin + base_camera.project_ray_normal(mouse_position) * 1000

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end); 
	var intersection = space_state.intersect_ray(query)

	if intersection.size() > 0:
		var pos = intersection.position
		var direction_to_pos = pos - model.global_position

		if direction_to_pos.length() > 0.5:
			direction_to_pos.y = 0
			var look_at_pos = model.global_position + direction_to_pos
			model.look_at(look_at_pos, Vector3(0, 1, 0))
