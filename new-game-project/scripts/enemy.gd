extends Area2D

# Enemy movement and collision handler
# Connected to: Area2D with CollisionShape2D for detecting bullet hits

# Movement pattern types
enum MovementPattern {
	STRAIGHT,  # Move straight down
	ZIGZAG     # Oscillate left/right while moving down
}

# Enemy configuration
@export var speed: float = 150.0  # Pixels per second downward
@export var points: int = 10  # Points awarded when destroyed
@export var movement_pattern: MovementPattern = MovementPattern.STRAIGHT
@export var zigzag_amplitude: float = 100.0  # How far left/right for zigzag
@export var zigzag_frequency: float = 2.0  # How fast to oscillate (cycles per second)

# Hover/bump configuration - set by game_manager at spawn time
@export var hover_line_y: float = 1550.0  # Y position where enemy stops descending and starts bumping
@export var bump_damage: int = 5  # Damage dealt to player per bump
@export var bump_interval: float = 1.0  # Seconds between bumps

# Signals
signal enemy_killed(points_value, death_position)  # Emitted when enemy is destroyed by bullet
signal enemy_bumped(damage_value)  # Emitted periodically while hovering; damages the player

# Internal tracking for zigzag movement
var time_alive: float = 0.0  # Time since enemy spawned
var initial_x: float = 0.0  # Starting x position for zigzag

# Internal tracking for hover/bump state
var is_hovering: bool = false  # True once enemy has reached the hover line
var bump_timer: float = 0.0  # Time accumulated toward the next bump

func _ready():
	# Add to "enemies" group so bullets can detect collision with enemies
	add_to_group("enemies")

	# Store initial x position for zigzag pattern
	initial_x = position.x

func _process(delta):
	time_alive += delta

	if is_hovering:
		_process_bump(delta)
		return

	# Move based on movement pattern
	match movement_pattern:
		MovementPattern.STRAIGHT:
			_move_straight(delta)
		MovementPattern.ZIGZAG:
			_move_zigzag(delta)

	# Once the enemy reaches the hover line, stop descending and start bumping the player
	if position.y >= hover_line_y:
		position.y = hover_line_y
		is_hovering = true

func _move_straight(delta: float):
	# Simple downward movement
	position.y += speed * delta

func _move_zigzag(delta: float):
	# Move downward
	position.y += speed * delta

	# Oscillate left and right using sine wave
	# sin(time * frequency * 2π) gives smooth oscillation between -1 and 1
	var horizontal_offset = sin(time_alive * zigzag_frequency * TAU) * zigzag_amplitude
	position.x = initial_x + horizontal_offset

func _process_bump(delta: float):
	# Deal periodic chunk damage to the player while hovering, with a visual lunge
	bump_timer += delta
	if bump_timer >= bump_interval:
		bump_timer -= bump_interval
		enemy_bumped.emit(bump_damage)
		_play_bump_animation()

func _play_bump_animation():
	# Placeholder "lunge" toward the player and back, timed to the damage tick
	var tween = create_tween()
	tween.tween_property(self, "position:y", hover_line_y + 20.0, 0.1)
	tween.tween_property(self, "position:y", hover_line_y, 0.15)

func die():
	# Called when enemy is killed by bullet
	enemy_killed.emit(points, global_position)  # Notify game manager of points earned and where the kill happened
	queue_free()  # Remove the enemy
