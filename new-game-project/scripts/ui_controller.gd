extends CanvasLayer

# UI Controller - manages score display and health display
# Connected to: UI CanvasLayer node, references ScoreLabel and HealthBar nodes
# Listens to: game_manager signals (score_changed, health_changed)

var score_label: Label  # Reference to ScoreLabel
var health_bar: ProgressBar  # Reference to HealthBar
var pause_button: Button  # Reference to PauseButton
var game_over_panel: Panel  # Reference to GameOverPanel
var main_menu_button: Button  # Reference to MainMenuButton
var wave_label: Label  # Reference to WaveLabel
var wave_complete_panel: Panel  # Reference to WaveCompletePanel
var wave_score_label: Label  # Reference to WaveScoreLabel
var total_score_label: Label  # Reference to TotalScoreLabel
var next_wave_button: Button  # Reference to NextWaveButton
var game_manager: Node2D  # Reference to game manager

# Power-up loadout display - 3 slots showing equipped power-up type + level
var powerup_slot_icons: Array = []  # ColorRect per slot
var powerup_slot_type_labels: Array = []  # Label per slot (overlaid on icon)
var powerup_slot_level_labels: Array = []  # Label per slot (below icon)
const POWERUP_EMPTY_SLOT_COLOR = Color(0.3, 0.3, 0.3, 1)

# Pause state
var is_paused: bool = false

func _ready():
	# Set this UI layer to always process (even when paused)
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Get references to UI elements
	score_label = get_node("ScoreLabel")
	health_bar = get_node("HealthBar")
	pause_button = get_node("PauseButton")
	game_over_panel = get_node("GameOverPanel")
	main_menu_button = get_node("GameOverPanel/GameOverContainer/MainMenuButton")
	wave_label = get_node("WaveLabel")
	wave_complete_panel = get_node("WaveCompletePanel")
	wave_score_label = get_node("WaveCompletePanel/WaveScoreLabel")
	total_score_label = get_node("WaveCompletePanel/TotalScoreLabel")
	next_wave_button = get_node("WaveCompletePanel/NextWaveButton")

	# Get references to the 3 power-up loadout slots
	for i in range(3):
		var slot_path = "PowerUpDisplay/Slot" + str(i)
		powerup_slot_icons.append(get_node(slot_path + "/Icon"))
		powerup_slot_type_labels.append(get_node(slot_path + "/Icon/TypeLabel"))
		powerup_slot_level_labels.append(get_node(slot_path + "/LevelLabel"))

	if score_label == null:
		push_error("ScoreLabel not found!")
	if health_bar == null:
		push_error("HealthBar not found!")
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

	# Configure health bar range to match game manager's max health
	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = game_manager.max_health
		health_bar.value = game_manager.max_health

	# Connect to game manager signals
	game_manager.score_changed.connect(_on_score_changed)
	game_manager.total_score_changed.connect(_on_total_score_changed)
	game_manager.health_changed.connect(_on_health_changed)
	game_manager.game_over.connect(_on_game_over)
	game_manager.wave_started.connect(_on_wave_started)
	game_manager.wave_complete.connect(_on_wave_complete)
	game_manager.powerup_loadout_changed.connect(_on_powerup_loadout_changed)

func _on_score_changed(new_score: int):
	# Update score label (spendable score)
	if score_label:
		score_label.text = "Score: " + str(new_score)

func _on_total_score_changed(new_total_score: int):
	# Update total score label in wave complete panel
	if total_score_label:
		total_score_label.text = "Total Score: " + str(new_total_score)

func _on_health_changed(new_health: int):
	# Update health bar to reflect current player health
	if health_bar:
		health_bar.value = new_health

func _on_powerup_loadout_changed():
	# Refresh the 3 loadout slots to reflect currently equipped power-up types/levels
	if game_manager == null:
		return

	var equipped_types = game_manager.equipped_powerups.keys()  # Insertion order = equip order

	for i in range(3):
		if i < equipped_types.size():
			var type = equipped_types[i]
			var level = game_manager.equipped_powerups[type]
			powerup_slot_icons[i].color = game_manager.powerup_colors[type]
			powerup_slot_type_labels[i].text = game_manager.powerup_short_labels[type]
			powerup_slot_level_labels[i].text = "Lv" + str(level)
		else:
			powerup_slot_icons[i].color = POWERUP_EMPTY_SLOT_COLOR
			powerup_slot_type_labels[i].text = ""
			powerup_slot_level_labels[i].text = ""

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
