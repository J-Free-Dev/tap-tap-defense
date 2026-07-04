extends Area2D

# Bullet movement and collision handler
# Connected to: Area2D with CollisionShape2D for detecting hits

@export var speed: float = 800.0  # Pixels per second

var direction: Vector2 = Vector2.UP  # Default direction (will be set by turret)

func _ready():
	# Connect collision signal to detect when bullet hits something
	area_entered.connect(_on_area_entered)

func _process(delta):
	# Move the bullet in its direction
	position += direction * speed * delta

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
		queue_free()  # Destroy the bullet
