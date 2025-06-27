extends StaticBody2D

var brogleCurrentState : String = "Normal" 
var destroyable : bool = false

func _process(delta: float) -> void:
	print(destroyable)
	if !destroyable:
		return
	if brogleCurrentState == "Normal":
		return
	elif brogleCurrentState == "GrndPnd":
		print("Succesful Destruction!")
		$CollisionShape2D.disabled = true
		queue_free() # Delete block on impact

func _on_brogle_state_changed(State: String) -> void:
	brogleCurrentState = State # Sets Broccoli's new state to objects and shit

func _on_gnd_pnd_detect_body_entered(body: Node2D) -> void:
	print(body.name) # debug
	if "brogle" in body.name:
		destroyable = true # sets the destroyable property to true

func _on_gnd_pnd_detect_body_exited(body: Node2D) -> void:
	if "brogle" in body.name:
		destroyable = false # sets the destroyable property to false
