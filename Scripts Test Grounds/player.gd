extends CharacterBody2D

enum States {Normal, GndPnd}
@export var SPEED = 2500.0
@export var JUMP_VELOCITY = -3000.0
@export var ACCELERATION = 150
@export var PUSH_FORCE = 300
@export var CUR_STATE : States = States.Normal #: set = set_state
@onready var sprite_2d = $Sprite2D
@onready var coyote_timer = $CoyoteTimer
@onready var player_collision = $CollisionShape2D # just to alter the box when needed lol
@onready var ground_pound_hitbox = $GndPndHitbox

var gravity = 5500 #ProjectSettings.get_setting("physics/2d/default_gravity")
signal StateChanged(State : String)

func _physics_process(delta):
	DEBUG() # DEBUG

	# Get the input direction and handle the movement/deceleration.
	var horizontal_direction = Input.get_axis("move_left", "move_right")
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
		if (Input.is_action_pressed("down")):
			position.y += 1
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	else:
		if CUR_STATE == States.Normal:
			velocity.y += gravity * delta
			if velocity.y >= 3500:  #Terminal Velocity
				velocity.y = 3500
			# Short hops!
			if Input.is_action_just_released("jump") and velocity.y < JUMP_VELOCITY / 2:
				velocity.y = JUMP_VELOCITY / 2

			# Starts Ground Pound ability
			if (Input.is_action_pressed("down") and Input.is_action_just_pressed("jump")):
				velocity.y = 0 # Move the delay here
				CUR_STATE = States.GndPnd
				StateChanged.emit(CUR_STATE) #emits Ground Pound state
				await get_tree().create_timer(0.24).timeout
				velocity.y = 9500
		elif CUR_STATE == States.GndPnd:
			groundPound(horizontal_direction)
	
	if coyote_timer.time_left > 0.0:
		if (Input.is_action_pressed("down")):
			position.y += 1
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY

	flipSprite()
	spriteUpdate(CUR_STATE)
	
	# Resetting the coyote time timer
	var was_floored = is_on_floor()
	move_and_slide()
	var no_grounded = was_floored && !is_on_floor() && velocity.y >= 0
	if no_grounded:
		coyote_timer.start()
	
	# Push boxes
	pushBox()
	
	# Pause game
	pauseGame()
	
func pushBox() -> void:
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * PUSH_FORCE)

func groundPound(direction) -> void:
	if velocity.y <= 0: sprite_2d.animation = "brogleGndPndStart"
	else:
		# Enables the ground pound hitbox once falling
		ground_pound_hitbox.monitorable = true
		ground_pound_hitbox.monitoring = true
		sprite_2d.animation = "brogleGndPndFall" # Falling loop once timer expires
		# Horizontal speed cap while in ground pound state.
		if direction:
			velocity.x = move_toward(velocity.x, direction*1.05, 0.6)
		else:
			velocity.x = move_toward(velocity.x, 0, 200)

func flipSprite() -> void:
	if Input.is_action_pressed("move_left"):
		sprite_2d.flip_h = true
	if Input.is_action_pressed("move_right"):
		sprite_2d.flip_h = false

func spriteUpdate(playerState: States) -> void:
	if playerState == States.Normal:
		if is_on_floor():
			sprite_2d.animation = "upBrogleIdle" if velocity.x == 0 else "upBrogleRun"
		else: sprite_2d.animation = "upBrogleJump" if velocity.y < -1 else "upBrogleFall"
	else: pass

func pauseGame() -> void:
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = true

func DEBUG() -> void:
	player_collision.set_debug_color(Color.from_hsv(257, 9, 96, 0.5))
	player_collision.visible = true
	# Disable ground pound hitbox when not in ground pound state
	ground_pound_hitbox.monitorable = false
	ground_pound_hitbox.monitoring = false
	
