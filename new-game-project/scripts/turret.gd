extends Node2D

# Turret auto-rotation and shooting controller
# Connected to: TurretBarrel node (child ColorRect that rotates)

# Rotation settings
@export var rotation_speed: float = 2.0  # Radians per second
@export var min_angle: float = -60.0  # Degrees - left limit
@export var max_angle: float = 60.0  # Degrees - right limit

# Bullet settings
var bullet_scene = preload("res://scenes/bullet.tscn")  # Load the bullet scene

# Double Shot power-up state - set by game_manager based on equipped level
@export var shot_count: int = 1  # Number of bullets fired per tap
@export var shot_spread_degrees: float = 8.0  # Angular spread between simultaneous bullets

# Laser power-up state - set by game_manager based on equipped level
@export var pierce_count: int = 1  # Number of enemies each bullet can hit before being destroyed

# Bouncing Ball power-up state - set by game_manager based on equipped level
@export var bounce_count: int = 0  # Number of times each bullet can bounce off the left/right edges

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
	# Spawn one bullet per shot_count (Double Shot power-up), fanned around the barrel's aim
	if bullets_container == null:
		return

	var barrel_length = 100.0  # Barrel is 100 pixels tall, so tip is 100 pixels from pivot

	for angle in _get_shot_angles():
		var bullet = bullet_scene.instantiate()
		var spawn_offset = Vector2(sin(angle), -cos(angle)) * barrel_length
		bullet.position = global_position + spawn_offset
		bullet.set_direction(angle)
		bullet.pierce_count = pierce_count
		bullet.bounces_remaining = bounce_count
		bullets_container.add_child(bullet)

func _get_shot_angles() -> Array:
	# Returns one angle per bullet to fire, evenly fanned around the barrel's current rotation
	if shot_count <= 1:
		return [barrel.rotation]

	var angles: Array = []
	var total_spread = shot_spread_degrees * (shot_count - 1)
	var start_angle = barrel.rotation - deg_to_rad(total_spread / 2.0)
	for i in range(shot_count):
		angles.append(start_angle + deg_to_rad(shot_spread_degrees * i))
	return angles
