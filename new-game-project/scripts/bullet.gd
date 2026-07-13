extends Area2D

# Bullet movement and collision handler
# Connected to: Area2D with CollisionShape2D for detecting hits

@export var speed: float = 800.0  # Pixels per second
@export var pierce_count: int = 1  # Number of enemies this bullet can hit before being destroyed (Laser power-up)
@export var bounces_remaining: int = 0  # Number of times this bullet can bounce off the left/right edges (Bouncing Ball power-up)

const PLAY_AREA_LEFT: float = 0.0
const PLAY_AREA_RIGHT: float = 1080.0

var direction: Vector2 = Vector2.UP  # Default direction (will be set by turret)

func _ready():
	# Connect collision signal to detect when bullet hits something
	area_entered.connect(_on_area_entered)

func _process(delta):
	# Move the bullet in its direction
	position += direction * speed * delta

	# Bounce off the left/right play area edges if bounces remain (Bouncing Ball power-up)
	if bounces_remaining > 0:
		if position.x <= PLAY_AREA_LEFT and direction.x < 0:
			direction.x = -direction.x
			position.x = PLAY_AREA_LEFT
			bounces_remaining -= 1
		elif position.x >= PLAY_AREA_RIGHT and direction.x > 0:
			direction.x = -direction.x
			position.x = PLAY_AREA_RIGHT
			bounces_remaining -= 1

	# Destroy bullet if it goes off screen
	if position.y < -50 or position.y > 2000 or position.x < -50 or position.x > 1130:
		queue_free()

func set_direction(angle_radians: float):
	# Convert angle to direction vector
	direction = Vector2(sin(angle_radians), -cos(angle_radians))

func _on_area_entered(area):
	# Handle collision with enemies
	if area.is_in_group("enemies"):
		if area.has_method("die"):
			area.die()  # Call enemy's die method (handles points and cleanup)
		pierce_count -= 1
		if pierce_count <= 0:
			queue_free()  # Destroy the bullet - out of pierces
	elif area.is_in_group("powerups"):
		if area.has_method("collect"):
			area.collect()  # Apply the power-up's effect
		queue_free()  # Destroy the bullet
