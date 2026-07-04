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

# Signals
signal enemy_killed(points_value)  # Emitted when enemy is destroyed by bullet
signal enemy_escaped  # Emitted when enemy reaches bottom

# Internal tracking for zigzag movement
var time_alive: float = 0.0  # Time since enemy spawned
var initial_x: float = 0.0  # Starting x position for zigzag

func _ready():
	# Add to "enemies" group so bullets can detect collision with enemies
	add_to_group("enemies")

	# Store initial x position for zigzag pattern
	initial_x = position.x

func _process(delta):
	time_alive += delta

	# Move based on movement pattern
	match movement_pattern:
		MovementPattern.STRAIGHT:
			_move_straight(delta)
		MovementPattern.ZIGZAG:
			_move_zigzag(delta)

	# Check if enemy reached the bottom (damage player)
	if position.y > 1920:
		enemy_escaped.emit()  # Notify game manager
		queue_free()  # Remove the enemy

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

func die():
	# Called when enemy is killed by bullet
	enemy_killed.emit(points)  # Notify game manager of points earned
	queue_free()  # Remove the enemy
