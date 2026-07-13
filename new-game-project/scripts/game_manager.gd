extends Node2D

# Game manager - handles wave system, enemy spawning, score, health, and game state
# Connected to: Main scene root, references Enemies container node

# Enemy spawning settings
@export var min_spawn_x: float = 100.0  # Leftmost spawn position
@export var max_spawn_x: float = 980.0  # Rightmost spawn position
@export var spawn_y: float = -50.0  # Y position where enemies spawn (above screen)

# Wave system settings - difficulty scaling parameters
@export var base_spawn_interval: float = 2.0  # Starting seconds between spawns
@export var base_enemies: int = 10  # Starting enemies per wave
@export var enemy_increase_rate: int = 2  # Additional enemies per wave
@export var spawn_interval_scale: float = 0.95  # Spawn rate multiplier per wave (0.95 = 5% faster)
@export var enemy_speed_scale: float = 0.05  # Speed increase per wave (0.05 = 5% faster)

# Hover line - y position where enemies stop descending and start bumping the player
@export var hover_line_y: float = 1550.0

# Power-up drop settings
@export var powerup_drop_chance: float = 0.5  # Chance an enemy drops a power-up on death

# Power-up progression settings
const MAX_EQUIPPED_POWERUPS = 3  # Player can equip at most 3 distinct power-up types at once
@export var powerup_bonus_points: int = 50  # Points awarded for shooting an unequipped type once slots are full
var powerup_max_level: Dictionary = {
	0: 1,  # DOUBLE_SHOT - single level, 2 balls permanently
	1: 3,  # BOUNCING_BALL - levels give 1 / 3 / 4 bounces (see bouncing_ball_bounces_by_level)
	2: 2,  # LASER - caps at pierce 3 (level + 1)
	3: 2   # SLOW_TURRET - caps at 50% rotation speed (see slow_turret_multiplier_by_level)
}
var powerup_super_boost_duration: Dictionary = {
	0: 3.0,  # DOUBLE_SHOT
	1: 5.0,  # BOUNCING_BALL
	2: 5.0,  # LASER
	3: 5.0   # SLOW_TURRET
}
var bouncing_ball_bounces_by_level: Dictionary = {
	1: 1,
	2: 3,
	3: 4
}
var slow_turret_multiplier_by_level: Dictionary = {
	1: 0.75,  # 25% slower
	2: 0.5    # 50% slower (max)
}
var slow_turret_super_boost_multiplier: float = 0.25  # 75% slower, temporary
var powerup_colors: Array = [Color.YELLOW, Color.CYAN, Color.MAGENTA, Color.ORANGE]  # Placeholder color per type, indexed by type
var powerup_short_labels: Array = ["2X", "BB", "LZ", "SLW"]  # Short display label per type, indexed by type
var equipped_powerups: Dictionary = {}  # powerup_type(int) -> current permanent level(int)
var super_boost_timers: Dictionary = {}  # powerup_type(int) -> seconds remaining on an active super-boost

# Game state
@export var max_health: int = 100  # Maximum player health
var current_health: int = 100  # Current player health
var score: int = 0  # Current spendable score (can be used for upgrades later)
var total_score: int = 0  # Total score earned (never decreases)

# Wave tracking
var current_wave: int = 0  # Current wave number (starts at 0, first wave is 1)
var enemies_in_wave: int = 0  # Total enemies to spawn this wave
var enemies_spawned: int = 0  # Enemies spawned so far this wave
var enemies_alive: int = 0  # Enemies currently active in the scene
var wave_active: bool = false  # Is a wave currently running
var wave_score: int = 0  # Score earned in current wave

# Signals for UI updates
signal score_changed(new_score)
signal total_score_changed(new_total_score)
signal health_changed(new_health)
signal game_over
signal wave_started(wave_number)  # Emitted when a new wave begins
signal wave_complete(wave_number, wave_score_earned)  # Emitted when wave is cleared
signal powerup_loadout_changed  # Emitted when equipped_powerups changes (new equip or level up)

var enemy_scene = preload("res://scenes/enemy.tscn")  # Load the enemy scene
var powerup_scene = preload("res://scenes/powerup.tscn")  # Load the power-up scene
var enemies_container: Node2D  # Reference to Enemies container
var powerups_container: Node2D  # Reference to PowerUps container
var turret: Node2D  # Reference to Turret node
var base_turret_rotation_speed: float = 2.0  # Turret's configured rotation_speed before any Slow Turret power-up effect
var spawn_timer: float = 0.0  # Timer to track when to spawn next enemy
var current_spawn_interval: float = 2.0  # Current spawn interval (adjusted per wave)

# Enemy type configurations
var enemy_types: Array[Dictionary] = []

func _ready():
	# Get reference to the Enemies container node
	enemies_container = get_node("Enemies")
	if enemies_container == null:
		push_error("Enemies container node not found!")

	# Get reference to the PowerUps container node
	powerups_container = get_node("PowerUps")
	if powerups_container == null:
		push_error("PowerUps container node not found!")

	# Get reference to the Turret node (power-up effects like Double Shot apply here)
	turret = get_node("Turret")
	if turret == null:
		push_error("Turret node not found!")
	else:
		base_turret_rotation_speed = turret.rotation_speed

	# Initialize enemy type configurations
	_initialize_enemy_types()

	# Initialize game state
	current_health = max_health
	score = 0
	total_score = 0
	current_wave = 0
	wave_active = false

	# Emit initial values for UI
	health_changed.emit(current_health)
	score_changed.emit(score)
	total_score_changed.emit(total_score)

	# Start the first wave automatically
	start_next_wave()

func _process(delta):
	# Count down any active power-up super-boosts regardless of wave state
	_process_super_boosts(delta)

	# Only process spawning if wave is active
	if not wave_active:
		return

	# Check if we've spawned all enemies for this wave
	if enemies_spawned >= enemies_in_wave:
		return

	# Update spawn timer
	spawn_timer += delta

	# Spawn enemy when timer reaches interval
	if spawn_timer >= current_spawn_interval:
		spawn_enemy()
		spawn_timer = 0.0  # Reset timer

func _process_super_boosts(delta):
	var expired: Array = []
	for type in super_boost_timers.keys():
		super_boost_timers[type] -= delta
		if super_boost_timers[type] <= 0:
			expired.append(type)
	for type in expired:
		super_boost_timers.erase(type)
		_revert_super_boost(type)

func spawn_enemy():
	if enemies_container == null:
		return

	# Select enemy type based on current wave
	var enemy_type = _select_enemy_type()

	# Create new enemy instance
	var enemy = enemy_scene.instantiate()

	# Set random horizontal spawn position
	var random_x = randf_range(min_spawn_x, max_spawn_x)
	enemy.position = Vector2(random_x, spawn_y)

	# Apply enemy type configuration
	var speed_multiplier = 1.0 + (current_wave * enemy_speed_scale)
	enemy.speed = enemy_type["base_speed"] * speed_multiplier
	enemy.points = enemy_type["points"]
	enemy.movement_pattern = enemy_type["movement_pattern"]

	# Apply zigzag parameters if this is a zigzag enemy
	if enemy_type.has("zigzag_amplitude"):
		enemy.zigzag_amplitude = enemy_type["zigzag_amplitude"]
	if enemy_type.has("zigzag_frequency"):
		enemy.zigzag_frequency = enemy_type["zigzag_frequency"]

	# Apply hover/bump configuration
	enemy.hover_line_y = hover_line_y
	enemy.bump_damage = enemy_type["bump_damage"]
	enemy.bump_interval = enemy_type["bump_interval"]

	# Set visual color (placeholder - using ColorRect)
	if enemy.has_node("ColorRect"):
		var color_rect = enemy.get_node("ColorRect")
		color_rect.color = enemy_type["color"]

	# Connect enemy signals
	enemy.enemy_killed.connect(_on_enemy_killed)
	enemy.enemy_bumped.connect(_on_enemy_bumped)

	# Add enemy to the scene
	enemies_container.add_child(enemy)

	# Track spawned and alive enemies
	enemies_spawned += 1
	enemies_alive += 1

func _on_enemy_killed(points_value: int, death_position: Vector2):
	# Add points to spendable score, total score, and wave score
	score += points_value
	total_score += points_value
	wave_score += points_value
	score_changed.emit(score)
	total_score_changed.emit(total_score)

	# Decrease alive enemy count
	enemies_alive -= 1

	# Chance to drop a power-up where the enemy died
	_try_drop_powerup(death_position)

	# Check if wave is complete
	check_wave_complete()

func _try_drop_powerup(drop_position: Vector2):
	if powerups_container == null:
		return
	if randf() >= powerup_drop_chance:
		return

	var powerup = powerup_scene.instantiate()
	powerup.position = drop_position
	powerup.destroy_y = hover_line_y
	powerup.powerup_type = randi() % 4  # Random among the 4 power-up types

	# Set placeholder color and short label per type, so pickups are distinguishable at a glance
	if powerup.has_node("ColorRect"):
		var color_rect = powerup.get_node("ColorRect")
		color_rect.color = powerup_colors[powerup.powerup_type]
	if powerup.has_node("Label"):
		var label = powerup.get_node("Label")
		label.text = powerup_short_labels[powerup.powerup_type]

	powerup.powerup_collected.connect(_on_powerup_collected)
	powerups_container.add_child(powerup)

func _on_powerup_collected(type: int):
	if equipped_powerups.has(type):
		# Already equipped - level up, or trigger a temporary super-boost if already at max level
		var current_level = equipped_powerups[type]
		if current_level < powerup_max_level[type]:
			equipped_powerups[type] = current_level + 1
			_apply_powerup_effect(type, equipped_powerups[type])
			powerup_loadout_changed.emit()
		else:
			_trigger_super_boost(type)
	elif equipped_powerups.size() < MAX_EQUIPPED_POWERUPS:
		# New type and a slot is free - equip at level 1
		equipped_powerups[type] = 1
		_apply_powerup_effect(type, 1)
		powerup_loadout_changed.emit()
	else:
		# Not equipped and no slots free - award bonus points instead of doing nothing
		score += powerup_bonus_points
		total_score += powerup_bonus_points
		score_changed.emit(score)
		total_score_changed.emit(total_score)

func _apply_powerup_effect(type: int, level: int):
	# Applies a power-up's permanent effect at its current level
	match type:
		0:  # DOUBLE_SHOT
			if turret:
				turret.shot_count = level + 1  # Level 1 = 2 balls (max)
		1:  # BOUNCING_BALL
			if turret:
				turret.bounce_count = bouncing_ball_bounces_by_level[level]
		2:  # LASER
			if turret:
				turret.pierce_count = level + 1  # Level 1 = pierce 2, level 2 (max) = pierce 3
		3:  # SLOW_TURRET
			if turret:
				turret.rotation_speed = base_turret_rotation_speed * slow_turret_multiplier_by_level[level]
		_:
			print("Power-up %d - %s level %d (effect not yet implemented)" % [type, _get_powerup_name(type), level])

func _trigger_super_boost(type: int):
	# Starts (or refreshes) a temporary boost above max level; reverts after its duration
	super_boost_timers[type] = powerup_super_boost_duration.get(type, 8.0)
	match type:
		0:  # DOUBLE_SHOT
			if turret:
				turret.shot_count = 3  # Temporary super-boost: 3 balls
		1:  # BOUNCING_BALL
			if turret:
				turret.bounce_count = 5  # Temporary super-boost: 5 bounces
		2:  # LASER
			if turret:
				turret.pierce_count = 5  # Temporary super-boost: pierce 5
		3:  # SLOW_TURRET
			if turret:
				turret.rotation_speed = base_turret_rotation_speed * slow_turret_super_boost_multiplier
		_:
			print("Power-up %d - %s super-boost (effect not yet implemented)" % [type, _get_powerup_name(type)])

func _revert_super_boost(type: int):
	# Called when a super-boost's timer runs out; falls back to the type's permanent max-level effect
	match type:
		0:  # DOUBLE_SHOT
			if turret:
				turret.shot_count = equipped_powerups[type] + 1
		1:  # BOUNCING_BALL
			if turret:
				turret.bounce_count = bouncing_ball_bounces_by_level[equipped_powerups[type]]
		2:  # LASER
			if turret:
				turret.pierce_count = equipped_powerups[type] + 1
		3:  # SLOW_TURRET
			if turret:
				turret.rotation_speed = base_turret_rotation_speed * slow_turret_multiplier_by_level[equipped_powerups[type]]
		_:
			pass

func _get_powerup_name(type: int) -> String:
	match type:
		0:
			return "Double Shot"
		1:
			return "Bouncing Ball"
		2:
			return "Laser"
		3:
			return "Slow Turret Rotation"
		_:
			return "Unknown"

func _on_enemy_bumped(damage_value: int):
	# Reduce health when a hovering enemy bumps the player
	current_health = max(current_health - damage_value, 0)
	health_changed.emit(current_health)

	# Check for game over
	if current_health <= 0:
		game_over.emit()
		wave_active = false
		set_process(false)

func start_next_wave():
	# Increment wave number
	current_wave += 1

	# Calculate enemies for this wave
	enemies_in_wave = base_enemies + ((current_wave - 1) * enemy_increase_rate)

	# Calculate spawn interval for this wave (gets faster each wave)
	current_spawn_interval = base_spawn_interval * pow(spawn_interval_scale, current_wave - 1)

	# Reset wave tracking
	enemies_spawned = 0
	enemies_alive = 0
	wave_score = 0
	spawn_timer = 0.0

	# Activate wave
	wave_active = true

	# Emit signal for UI
	wave_started.emit(current_wave)

func check_wave_complete():
	# Wave is complete when all enemies have been spawned AND none are alive
	print("Check wave complete - Spawned: ", enemies_spawned, "/", enemies_in_wave, " Alive: ", enemies_alive)
	if enemies_spawned >= enemies_in_wave and enemies_alive <= 0:
		print("Wave complete!")
		wave_active = false
		wave_complete.emit(current_wave, wave_score)

# Called by UI when player clicks "Next Wave" button
func on_next_wave_button_pressed():
	start_next_wave()

# Initialize enemy type configurations with properties for each type
func _initialize_enemy_types():
	# Enemy types are defined with all their properties
	# According to design doc v2.0 enemy type weighting

	# Type 1: Basic (straight moving enemy)
	enemy_types.append({
		"name": "Basic",
		"base_speed": 150.0,
		"points": 10,
		"movement_pattern": 0,  # MovementPattern.STRAIGHT
		"difficulty_rating": 1,
		"min_wave": 1,  # Available from wave 1
		"color": Color.RED,  # Placeholder color
		"bump_damage": 5,
		"bump_interval": 1.0
	})

	# Type 2: Zigzag (oscillating enemy)
	enemy_types.append({
		"name": "Zigzag",
		"base_speed": 120.0,
		"points": 20,
		"movement_pattern": 1,  # MovementPattern.ZIGZAG
		"difficulty_rating": 3,
		"min_wave": 4,  # Available from wave 4
		"color": Color.BLUE,  # Placeholder color
		"zigzag_amplitude": 100.0,
		"zigzag_frequency": 1.5,
		"bump_damage": 4,
		"bump_interval": 0.75
	})

# Get available enemy types for current wave based on min_wave requirement
func _get_available_enemy_types() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for enemy_type in enemy_types:
		if current_wave >= enemy_type["min_wave"]:
			available.append(enemy_type)
	return available

# Select enemy type based on wave number and difficulty weighting
func _select_enemy_type() -> Dictionary:
	var available = _get_available_enemy_types()

	if available.size() == 0:
		push_error("No available enemy types for wave " + str(current_wave))
		return enemy_types[0]  # Fallback to basic

	# For waves 1-3: Only basic enemies (100%)
	if current_wave <= 3:
		return enemy_types[0]  # Basic only

	# For waves 4-7: 70% basic, 30% zigzag
	elif current_wave <= 7:
		if randf() < 0.3:
			return enemy_types[1]  # Zigzag
		else:
			return enemy_types[0]  # Basic

	# For waves 8+: 50% basic, 50% zigzag
	else:
		if randf() < 0.5:
			return enemy_types[1]  # Zigzag
		else:
			return enemy_types[0]  # Basic
