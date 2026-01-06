class_name PauseMenu
extends Control

@onready var unpause = $UnpauseButton as Button
@onready var quitGame = $QuitGameButton as Button


func _process(_delta: float) -> void:
	if !get_tree().paused:
		hide()
		unpause.disabled = true
		quitGame.disabled = true
	else:
		show()
		unpause.disabled = false
		quitGame.disabled = false

func _ready() -> void:
	unpause.button_down.connect(resumeGame)
	quitGame.button_down.connect(exitGame)
	#if Input.is_action_just_pressed("pause"): resumeGame()

func resumeGame() -> void:
	hide()
	get_tree().paused = false
	pass

func exitGame() -> void:
	get_tree().quit()
