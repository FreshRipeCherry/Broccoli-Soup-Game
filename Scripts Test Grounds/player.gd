extends CharacterBody2D

@export var SPEED = 800.0
@export var JUMP_VELOCITY = -950.0
@export var ACCELERATION = 50
@export var PUSH_FORCE = 300
#@export var EXTRA_JUMP = 1
@onready var sprite_2d = $Sprite2D
@onready var coyote_timer = $CoyoteTimer

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	if (velocity.x > 0.1 || velocity.x < -0.1):
		sprite_2d.animation = "brogleRun"
	else:
		sprite_2d.animation = "brogleIdleNEW"
		
	if Input.is_action_pressed("move_left"):
		sprite_2d.flip_h = true
	if Input.is_action_pressed("move_right"):
		sprite_2d.flip_h = false
	
	if !is_on_floor():
		velocity.y += gravity * delta
		if velocity.y >= 2150:
			velocity.y = 2150
		"""if EXTRA_JUMP != 0 and Input.is_action_just_pressed("jump") and coyote_timer.time_left == 0.0:
			EXTRA_JUMP -= 1
			velocity.y = JUMP_VELOCITY"""
		if velocity.y < -1:
			sprite_2d.animation = "brogleJump"
		if velocity.y >= 0:
			sprite_2d.animation = "brogleFallNEW"
		if Input.is_action_just_released("jump") and velocity.y < JUMP_VELOCITY / 2:
			velocity.y = JUMP_VELOCITY / 2

	if is_on_floor() or coyote_timer.time_left > 0.0:
		# EXTRA_JUMP = 1
		if (Input.is_action_pressed("down")):
			position.y += 1
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			
	# Get the input direction and handle the movement/deceleration.
	var horizontal_direction = Input.get_axis("move_left", "move_right")
	var vertical_direction = Input.get_axis("up", "down")
	if horizontal_direction:
		velocity.x = move_toward(velocity.x, horizontal_direction*SPEED, ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0, 50)

	# Resetting the timer
	var was_floored = is_on_floor()
	move_and_slide()
	var no_grounded = was_floored and not is_on_floor() and velocity.y >= 0 # brogle was gruonded but they just left ledge
	if no_grounded:
		coyote_timer.start()
	
	# Pushing boxes
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * PUSH_FORCE)
