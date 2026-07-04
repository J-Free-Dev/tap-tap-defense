extends Control

# Main Menu Controller
# Connected to: MainMenu Control node, references StartButton and ExitButton
# Handles: Menu button clicks and scene transitions

var start_button: Button
var exit_button: Button

func _ready():
	# Get button references
	start_button = get_node("MenuContainer/StartButton")
	exit_button = get_node("MenuContainer/ExitButton")

	if start_button == null:
		push_error("StartButton not found!")
	else:
		start_button.pressed.connect(_on_start_pressed)

	if exit_button == null:
		push_error("ExitButton not found!")
	else:
		exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed():
	# Load and switch to the main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_exit_pressed():
	# Quit the game
	get_tree().quit()
