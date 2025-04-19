extends CharacterBody2D

@export var SPEED = 2500.0
@export var JUMP_VELOCITY = -3000.0
@export var ACCELERATION = 150
@export var PUSH_FORCE = 300
@export var CUR_STATE : String = "Normal" #World's shittiest state machine lmao
@onready var sprite_2d = $Sprite2D
@onready var coyote_timer = $CoyoteTimer
@onready var brogle_collision = $CollisionShape2D # just to alter the box when needed lol
@onready var state_label = $StateLabel
@onready var horizontal_velocity_debug = $XVelLabel
@onready var vertical_velocity_debug = $YVelLabel

var gravity = 5500 #ProjectSettings.get_setting("physics/2d/default_gravity")
var squishPoppet = 0 #Variable that will squish and stretch Broccoli for some animations
var lastSquishGndPnd = 0 #Variable to keep track of the scale when getting stretched

func _physics_process(delta):
	#DEBUG
	state_label.text = CUR_STATE
	horizontal_velocity_debug.text = str(velocity.x)
	vertical_velocity_debug.text = str(velocity.y)
	
	brogle_collision.set_debug_color(Color.from_hsv(257, 9, 96, 0.5))
	brogle_collision.visible = true
	# Get the input direction and handle the movement/deceleration.
	var horizontal_direction = Input.get_axis("move_left", "move_right")
	#var vertical_direction = Input.get_axis("up", "down") # Unused for now
	if horizontal_direction:
		velocity.x = move_toward(velocity.x, horizontal_direction*SPEED, ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0, 200) # Fixed Deceleration
	
	if horizontal_direction == -1:
		sprite_2d.position.x = -250
	if horizontal_direction == 1:
		sprite_2d.position.x = 0
	
	if is_on_floor():
		CUR_STATE = "Normal"
		#unsquish brogle
		if (squishPoppet != 0):
			sprite_2d.scale.x = squishPoppet
			squishPoppet -= 0.085
			sprite_2d.scale.y -= squishPoppet
			if squishPoppet <= 0:
				squishPoppet = 0
				sprite_2d.scale.y = 1
				sprite_2d.scale.x = 1
				lastSquishGndPnd = 0
		if (velocity.x > 0.1 || velocity.x < -0.1):
			sprite_2d.animation = "upBrogleRun"
		else:
			sprite_2d.animation = "upBrogleIdle"
		# EXTRA_JUMP = 1
		if (Input.is_action_pressed("down")):
			position.y += 1
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	else:  #!is_on_floor()
		if CUR_STATE == "Normal":
			velocity.y += gravity * delta
			if velocity.y >= 3500:  #Terminal Velocity
				velocity.y = 3500
			if velocity.y < -1:
				sprite_2d.animation = "upBrogleJump"
			if velocity.y >= 0:
				sprite_2d.animation = "upBrogleFall"
			if Input.is_action_just_released("jump") and velocity.y < JUMP_VELOCITY / 2:
				velocity.y = JUMP_VELOCITY / 2
			if (Input.is_action_pressed("down") and Input.is_action_just_pressed("jump")):
				velocity.y = 0 # Move the delay here
				CUR_STATE = "GrndPnd"
		elif CUR_STATE == "GrndPnd":
			if velocity.y <= 0:
				sprite_2d.animation = "brogleGndPndStart"
			else:
				sprite_2d.animation = "brogleGndPndFall"
				if squishPoppet >= 0.25:
					squishPoppet = 0.25
					sprite_2d.scale.y = lastSquishGndPnd
					sprite_2d.scale.x = 0.25
				lastSquishGndPnd = sprite_2d.scale.y
				squishPoppet += 0.02
				sprite_2d.scale.x -= squishPoppet/3
				sprite_2d.scale.y += squishPoppet
			await get_tree().create_timer(0.24).timeout
			#await sprite_2d.animation_finished
			velocity.y = 9500
			if horizontal_direction:
				velocity.x = move_toward(velocity.x, horizontal_direction*1.05, 0.6)
			else:
				velocity.x = move_toward(velocity.x, 0, 200)
	
	if coyote_timer.time_left > 0.0:
		if (Input.is_action_pressed("down")):
			position.y += 1
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
		
	if Input.is_action_pressed("move_left"):
		sprite_2d.flip_h = true
	if Input.is_action_pressed("move_right"):
		sprite_2d.flip_h = false
	
	# Resetting the timer
	var was_floored = is_on_floor()
	move_and_slide()
	var no_grounded = was_floored and not is_on_floor() and velocity.y >= 0 # brogle was gruonded but they became airbone
	if no_grounded:
		coyote_timer.start()
	
	# Pushing boxes
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * PUSH_FORCE)
