extends Area2D

# Power-up pickup - floats down the screen after an enemy drops it.
# The player must shoot it with a bullet to collect it (see bullet.gd).
# If it reaches the destroy line uncollected, it's destroyed with no effect.

enum PowerUpType {
	DOUBLE_SHOT,
	BOUNCING_BALL,
	LASER,
	SLOW_TURRET
}

@export var fall_speed: float = 100.0  # Pixels per second downward
@export var destroy_y: float = 1550.0  # Y position where an uncollected power-up is destroyed
@export var powerup_type: PowerUpType = PowerUpType.DOUBLE_SHOT

signal powerup_collected(type)  # Emitted when the player shoots this power-up

func _ready():
	add_to_group("powerups")

func _process(delta):
	position.y += fall_speed * delta

	# Destroyed without effect if it reaches the player without being shot
	if position.y >= destroy_y:
		queue_free()

func collect():
	# Called by a bullet on hit - applies the power-up instead of just destroying it
	powerup_collected.emit(powerup_type)
	queue_free()
