# Tap Tap Defense - Design Document

---

## Current State

Tap Tap Defense is a wave-based defense game where players tap to shoot and reverse a rotating turret. The game features progressive difficulty scaling and multiple enemy types with different movement patterns.

---

## Completed Features

### Core Gameplay
- **Turret System**: Auto-rotating turret at bottom of screen
- **Shooting Mechanism**: Tap anywhere to shoot AND reverse turret direction
- **Bullet System**: Bullet spawning, movement, and collision detection
- **Enemy Destruction**: Collision detection between bullets and enemies

### Wave System
- **Count-Based Waves**: Each wave spawns a specific number of enemies
- **Player-Controlled Progression**: Click "Next Wave" button to start next wave
- **Wave Complete Screen**: Shows wave completed, next wave number, total score, and "Next Wave" button
- **Wave Counter**: Displays current wave number during gameplay
- **Progressive Difficulty**:
  - Spawn interval: Gets 5% faster each wave
  - Enemy speed: Gets 5% faster each wave  
  - Wave size: Starts at 10 enemies, +2 per wave

### Enemy System
- **Movement Pattern System**: Enum-based patterns (STRAIGHT, ZIGZAG)
- **Dynamic Configuration**: Enemy properties applied from configuration dictionary
- **Enemy Type Progression**: Different enemy types unlock at specific waves

#### Current Enemy Types

**1. Basic Enemy (Red)**
- Movement: Straight down
- Speed: 150 px/s (base)
- Size: 80x80 px
- Points: 10
- Health: 1 hit
- Available: All waves

**2. Zigzag Enemy (Blue)**
- Movement: Sine wave oscillation (100px amplitude, 1.5 frequency)
- Speed: 120 px/s (base)
- Size: 80x80 px
- Points: 20
- Health: 1 hit
- Available: Wave 4+

#### Current Wave Progression
- **Waves 1-3**: 100% Basic enemies
- **Waves 4-7**: 70% Basic, 30% Zigzag
- **Waves 8+**: 50% Basic, 50% Zigzag

### Game Systems
- **Lives System**: 3 lives, lose 1 when enemy escapes bottom of screen
- **Score System**: 
  - Spendable score (future currency for upgrades)
  - Total score (permanent achievement tracker)
- **Game Over**: Triggers when health reaches 0

### UI/Menus
- **Main Menu**: Start and Exit buttons
- **In-Game HUD**:
  - Score display
  - Lives display (hearts)
  - Wave counter
  - Pause/Resume button
- **Wave Complete Screen**:
  - Wave completed message
  - Next wave preview
  - Total score
  - "Next Wave" button
- **Game Over Screen**: Return to main menu option
- **Scene Transitions**: All menu flows working correctly

### Technical Architecture
- **Signal-Based Events**: game_started, enemy_killed, enemy_escaped, wave_started, wave_complete, total_score_changed
- **Enemy Configuration System**: Dictionary-based enemy type definitions
- **Difficulty Scaling Formulas**:
  ```gdscript
  # Spawn interval
  current_spawn_interval = base_spawn_interval * pow(0.95, current_wave - 1)
  
  # Enemies per wave
  enemies_in_wave = base_enemies + ((current_wave - 1) * enemy_increase_rate)
  
  # Enemy speed multiplier
  speed_multiplier = 1.0 + (current_wave * 0.05)
  ```

### File Structure
```
/scenes/
  - main.tscn (Main game scene)
  - main_menu.tscn (Main menu)
  - enemy.tscn (Enemy prefab - reused for all types)
  - bullet.tscn (Bullet prefab)

/scripts/
  - game_manager.gd (Wave system, spawning, score, health)
  - enemy.gd (Movement patterns, collision)
  - bullet.gd (Movement, collision)
  - turret.gd (Rotation, shooting, tap-to-reverse)
  - ui_controller.gd (UI management, wave screens)
  - main_menu.gd (Menu buttons)
```

---

## Next Milestone: Tank Enemy Implementation

### Tank Enemy Specifications

**Enemy Type: Tank (Green)**
- **Movement**: STRAIGHT (moves straight down)
- **Speed**: 100 px/s (base) - slower than other enemies
- **Size**: 120x120 px - larger than basic/zigzag enemies
- **Points**: 30 - higher reward for tougher enemy
- **Health**: 3 hits - requires 3 bullet hits to destroy
- **Difficulty Rating**: 6
- **Available**: Wave 8+
- **Visual**: Green ColorRect placeholder

### Implementation Tasks

**Phase 1: Health System Foundation**
- [ ] Add health tracking to enemy.gd
- [ ] Implement multi-hit detection (take damage instead of instant destroy)
- [ ] Add visual feedback for damage (color flash or opacity change)
- [ ] Test health system with modified basic enemy

**Phase 2: Tank Enemy Creation**
- [ ] Add Tank enemy configuration to game_manager.gd enemy_types array
- [ ] Update enemy.gd to handle larger enemy size (120x120)
- [ ] Create visual differentiation (green ColorRect)
- [ ] Test Tank enemy spawning independently

**Phase 3: Wave Progression Integration**
- [ ] Update enemy type weighting to include Tank
- [ ] New progression:
  - Waves 1-3: 100% Basic
  - Waves 4-7: 70% Basic, 30% Zigzag
  - Waves 8-12: 50% Basic, 30% Zigzag, 20% Tank
  - Waves 13+: 40% Basic, 30% Zigzag, 30% Tank
- [ ] Test enemy type distribution across waves 1-15

**Phase 4: Balance & Testing**
- [ ] Playtest waves 8-15 for Tank introduction
- [ ] Verify Tank enemies feel appropriately challenging
- [ ] Adjust health/speed/points if needed
- [ ] Test collision with larger enemy size (120x120)
- [ ] Ensure bullets properly hit larger hitbox

### Technical Implementation Details

#### Enemy Configuration Addition
```gdscript
# Add to game_manager.gd enemy_types array
{
	"name": "Tank",
	"scene_path": "res://scenes/enemy.tscn",
	"base_speed": 100.0,
	"size": 120,  # 120x120 px
	"points": 30,
	"health": 3,
	"movement_pattern": GameManager.MovementPattern.STRAIGHT,
	"difficulty_rating": 6,
	"min_wave": 8,
	"color": Color.GREEN
}
```

#### enemy.gd Updates Required
```gdscript
# Add health tracking
var max_health: int = 1
var current_health: int = 1

# Modify hit detection
func _on_area_entered(area):
	if area.is_in_group("bullet"):
		current_health -= 1
		# Visual feedback (flash or opacity)
		if current_health <= 0:
			emit_signal("enemy_killed", points)
			queue_free()
		else:
			# Damage feedback animation
			pass
		area.queue_free()
```

### Success Criteria
- Tank enemies spawn starting at wave 8
- Tank enemies require exactly 3 hits to destroy
- Tank enemies award 30 points when destroyed
- Tank enemies are visually distinct (green, larger size)
- Tank enemies move slower than basic/zigzag enemies
- Player can see damage feedback when hitting Tank
- Wave progression feels balanced with Tank introduction

---

## Balance Considerations

### Tank Enemy Balance Points
- **3 hits required**: Makes Tank significantly tougher than 1-hit enemies
- **100 px/s speed**: 33% slower than Basic, 17% slower than Zigzag
- **30 points**: Same value as 3 Basic enemies, encourages targeting
- **120x120 size**: Easier to hit but more threatening presence
- **Wave 8 introduction**: Player has experience with game before Tanks appear

### Expected Player Experience
- First Tank appearance should feel like a challenge spike
- Players should prioritize Tanks to prevent escapes
- Multi-hit feedback should feel satisfying (not frustrating)
- Tank + fast enemies mix creates tactical decisions

---

## Notes

- All visuals currently use ColorRect placeholders (sprites planned for future milestone)
- Reusing enemy.tscn scene for all enemy types keeps architecture clean
- Health system being added will be useful for future enemy types
- Visual feedback for damage is critical for player understanding
