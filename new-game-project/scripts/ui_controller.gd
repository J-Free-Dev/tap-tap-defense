extends CanvasLayer

# UI Controller - manages score display and lives display
# Connected to: UI CanvasLayer node, references ScoreLabel and LivesContainer nodes
# Listens to: game_manager signals (score_changed, health_changed)

var score_label: Label  # Reference to ScoreLabel
var lives_container: HBoxContainer  # Reference to LivesContainer
var pause_button: Button  # Reference to PauseButton
var game_over_panel: Panel  # Reference to GameOverPanel
var main_menu_button: Button  # Reference to MainMenuButton
var wave_label: Label  # Reference to WaveLabel
var wave_complete_panel: Panel  # Reference to WaveCompletePanel
var wave_score_label: Label  # Reference to WaveScoreLabel
var total_score_label: Label  # Reference to TotalScoreLabel
var next_wave_button: Button  # Reference to NextWaveButton
var game_manager: Node2D  # Reference to game manager

# Heart/life display settings
var heart_size: Vector2 = Vector2(40, 40)  # Size of each heart
var heart_color: Color = Color.RED  # Color of hearts

# Pause state
var is_paused: bool = false

func _ready():
	# Set this UI layer to always process (even when paused)
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Get references to UI elements
	score_label = get_node("ScoreLabel")
	lives_container = get_node("LivesContainer")
	pause_button = get_node("PauseButton")
	game_over_panel = get_node("GameOverPanel")
	main_menu_button = get_node("GameOverPanel/GameOverContainer/MainMenuButton")
	wave_label = get_node("WaveLabel")
	wave_complete_panel = get_node("WaveCompletePanel")
	wave_score_label = get_node("WaveCompletePanel/WaveScoreLabel")
	total_score_label = get_node("WaveCompletePanel/TotalScoreLabel")
	next_wave_button = get_node("WaveCompletePanel/NextWaveButton")

	if score_label == null:
		push_error("ScoreLabel not found!")
	if lives_container == null:
		push_error("LivesContainer not found!")
	if pause_button == null:
		push_error("PauseButton not found!")
	else:
		pause_button.pressed.connect(_on_pause_pressed)

	if game_over_panel == null:
		push_error("GameOverPanel not found!")
	if main_menu_button == null:
		push_error("MainMenuButton not found!")
	else:
		main_menu_button.pressed.connect(_on_main_menu_pressed)

	if wave_label == null:
		push_error("WaveLabel not found!")
	if wave_complete_panel == null:
		push_error("WaveCompletePanel not found!")
	else:
		# Make sure wave complete panel processes while paused
		wave_complete_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		wave_complete_panel.visible = false
	if wave_score_label == null:
		push_error("WaveScoreLabel not found!")
	if total_score_label == null:
		push_error("TotalScoreLabel not found!")
	if next_wave_button == null:
		push_error("NextWaveButton not found!")
	else:
		next_wave_button.pressed.connect(_on_next_wave_pressed)

	# Get reference to game manager
	game_manager = get_node("../")  # Parent is Main, which has game_manager script

	if game_manager == null:
		push_error("Game manager not found!")
		return

	# Connect to game manager signals
	game_manager.score_changed.connect(_on_score_changed)
	game_manager.total_score_changed.connect(_on_total_score_changed)
	game_manager.health_changed.connect(_on_health_changed)
	game_manager.game_over.connect(_on_game_over)
	game_manager.wave_started.connect(_on_wave_started)
	game_manager.wave_complete.connect(_on_wave_complete)

func _on_score_changed(new_score: int):
	# Update score label (spendable score)
	if score_label:
		score_label.text = "Score: " + str(new_score)

func _on_total_score_changed(new_total_score: int):
	# Update total score label in wave complete panel
	if total_score_label:
		total_score_label.text = "Total Score: " + str(new_total_score)

func _on_health_changed(new_health: int):
	# Clear existing hearts
	for child in lives_container.get_children():
		child.queue_free()

	# Create heart ColorRects for remaining lives
	for i in range(new_health):
		var heart = ColorRect.new()
		heart.custom_minimum_size = heart_size
		heart.color = heart_color
		lives_container.add_child(heart)

func _on_pause_pressed():
	# Toggle pause state
	is_paused = !is_paused
	get_tree().paused = is_paused

	# Update button text
	if pause_button:
		if is_paused:
			pause_button.text = "Resume"
		else:
			pause_button.text = "Pause"

func _on_game_over():
	# Pause the game to stop gameplay
	get_tree().paused = true

	# Show game over panel
	if game_over_panel:
		game_over_panel.visible = true
		# Make sure game over panel processes while paused
		game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	# Hide pause button (no pausing during game over)
	if pause_button:
		pause_button.visible = false

func _on_main_menu_pressed():
	# Return to main menu
	print("Main menu button pressed!")
	get_tree().paused = false  # Unpause before changing scenes
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_wave_started(wave_number: int):
	# Update wave label when new wave starts
	if wave_label:
		wave_label.text = "Wave " + str(wave_number)

	# Hide wave complete panel
	if wave_complete_panel:
		wave_complete_panel.visible = false

func _on_wave_complete(wave_number: int, _wave_score_earned: int):
	# Show wave complete panel
	if wave_complete_panel:
		wave_complete_panel.visible = true

	# Update wave label to show next wave number
	if wave_score_label:
		wave_score_label.text = "Wave: " + str(wave_number + 1)

	# Update total score label
	if total_score_label and game_manager:
		total_score_label.text = "Total Score: " + str(game_manager.total_score)

func _on_next_wave_pressed():
	# Call game manager to start next wave
	if game_manager:
		game_manager.on_next_wave_button_pressed()
