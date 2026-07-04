extends Node2D

# Turret auto-rotation and shooting controller
# Connected to: TurretBarrel node (child ColorRect that rotates)

# Rotation settings
@export var rotation_speed: float = 2.0  # Radians per second
@export var min_angle: float = -60.0  # Degrees - left limit
@export var max_angle: float = 60.0  # Degrees - right limit

# Bullet settings
var bullet_scene = preload("res://scenes/Bullet.tscn")  # Load the bullet scene

# Internal state
var rotation_direction: int = 1  # 1 for clockwise, -1 for counter-clockwise
var barrel: ColorRect  # Reference to the TurretBarrel ColorRect
var bullets_container: Node2D  # Reference to the Bullets container node

func _ready():
	# Get reference to the barrel node (connects to TurretBarrel ColorRect)
	barrel = get_node("TurretBarrel")
	if barrel == null:
		push_error("TurretBarrel node not found!")

	# Get reference to the Bullets container in Main scene
	bullets_container = get_node("../Bullets")
	if bullets_container == null:
		push_error("Bullets container node not found!")

func _process(delta):
	if barrel == null:
		return

	# Auto-rotate the barrel
	var rotation_amount = rotation_speed * rotation_direction * delta
	barrel.rotation += rotation_amount

	# Check if we've hit the rotation limits and reverse if needed
	var angle_degrees = rad_to_deg(barrel.rotation)
	if angle_degrees >= max_angle and rotation_direction == 1:
		rotation_direction = -1
		barrel.rotation = deg_to_rad(max_angle)  # Clamp to max
	elif angle_degrees <= min_angle and rotation_direction == -1:
		rotation_direction = 1
		barrel.rotation = deg_to_rad(min_angle)  # Clamp to min

func _input(event):
	# Handle tap/click to reverse direction and shoot
	if event is InputEventScreenTouch and event.pressed:
		reverse_direction()
		shoot()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		reverse_direction()
		shoot()

func reverse_direction():
	# Reverse the rotation direction
	rotation_direction *= -1

func shoot():
	# Spawn a bullet at the turret barrel's position and angle
	if bullets_container == null:
		return

	# Create new bullet instance
	var bullet = bullet_scene.instantiate()

	# Calculate barrel tip position (where bullet should spawn)
	# Barrel is 100 pixels tall, so tip is 100 pixels from pivot in the direction it's pointing
	var barrel_length = 100.0
	var spawn_offset = Vector2(sin(barrel.rotation), -cos(barrel.rotation)) * barrel_length
	bullet.position = global_position + spawn_offset

	# Set bullet direction to match barrel rotation
	bullet.set_direction(barrel.rotation)

	# Add bullet to the scene
	bullets_container.add_child(bullet)
