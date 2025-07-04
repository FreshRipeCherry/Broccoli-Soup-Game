extends CharacterBody2D

enum States {Normal, GndPnd}
@export var SPEED = 2500.0
@export var JUMP_VELOCITY = -3000.0
@export var ACCELERATION = 150
@export var PUSH_FORCE = 300
@export var CUR_STATE : States = States.Normal #: set = set_state
@onready var sprite_2d = $Sprite2D
@onready var coyote_timer = $CoyoteTimer
@onready var brogle_collision = $CollisionShape2D # just to alter the box when needed lol
@onready var ground_pound_hitbox = $GndPndHitbox

var gravity = 5500 #ProjectSettings.get_setting("physics/2d/default_gravity")
var squishPoppet = 0 #Variable that will squish and stretch Broccoli for some animations
#var lastSquishGndPnd = 0 #Variable to keep track of the scale when getting stretched

signal StateChanged(State : String)

func _physics_process(delta):
	#DEBUG
	brogle_collision.set_debug_color(Color.from_hsv(257, 9, 96, 0.5))
	brogle_collision.visible = true
	# Disable ground pound hitbox when not in ground pound state
	ground_pound_hitbox.monitorable = false
	ground_pound_hitbox.monitoring = false
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
		CUR_STATE = States.Normal
		StateChanged.emit(CUR_STATE) #emits Broccoli's new state
		#unsquish brogle
		"""if (squishPoppet != 0):
			sprite_2d.scale.x = squishPoppet
			squishPoppet -= 0.085
			sprite_2d.scale.y -= squishPoppet
			if squishPoppet <= 0:
				squishPoppet = 0
				sprite_2d.scale.y = 1
				sprite_2d.scale.x = 1
				lastSquishGndPnd = 0"""
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
		if CUR_STATE == States.Normal:
			velocity.y += gravity * delta
			if velocity.y >= 3500:  #Terminal Velocity
				velocity.y = 3500
			if velocity.y < -1:
				sprite_2d.animation = "upBrogleJump"
			if velocity.y >= 0:
				sprite_2d.animation = "upBrogleFall"
			# Short hops!
			if Input.is_action_just_released("jump") and velocity.y < JUMP_VELOCITY / 2:
				velocity.y = JUMP_VELOCITY / 2
			# Starts Ground Pound ability
			if (Input.is_action_pressed("down") and Input.is_action_just_pressed("jump")):
				velocity.y = 0 # Move the delay here
				CUR_STATE = States.GndPnd
				StateChanged.emit(CUR_STATE) #emits Ground Pound state
		elif CUR_STATE == States.GndPnd:
			#StateChanged.emit(CUR_STATE) #emits Ground Pound state
			if velocity.y <= 0:
				sprite_2d.animation = "brogleGndPndStart"
			else:
				# Enables the ground pound hitbox once falling
				ground_pound_hitbox.monitorable = true
				ground_pound_hitbox.monitoring = true
				# Updates the sprite to the falling loop
				sprite_2d.animation = "brogleGndPndFall"
				"""if squishPoppet >= 0.25:
					squishPoppet = 0.25
					sprite_2d.scale.y = lastSquishGndPnd
					sprite_2d.scale.x = 0.65
				lastSquishGndPnd = sprite_2d.scale.y
				squishPoppet += 0.02
				sprite_2d.scale.x -= squishPoppet/3
				sprite_2d.scale.y += squishPoppet"""
			await get_tree().create_timer(0.24).timeout
			velocity.y = 9500
			# Horizontal speed cap while in ground pound state.
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
	
	# Resetting the coyote time timer
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
			
	
"""	func set_state(new_state: int) -> void:
		var previous_state := CUR_STATE
		CUR_STATE = new_state
"""
