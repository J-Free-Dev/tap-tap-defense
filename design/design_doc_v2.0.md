# Tap Tap Defense - Design Document v2.0
## Milestone 2: Enhanced Gameplay - Wave System & Enemy Variety

---

## Overview
Version 2.0 focuses on implementing a robust wave system with difficulty scaling and introducing enemy variety. This foundation will determine the game's long-term replayability and challenge curve.

---

## 1. Wave System Architecture

### Core Concepts

#### Wave Structure
- **DECISION: Count-Based Waves** - Each wave spawns a specific number of enemies
- Wave ends when all enemies are either killed or escaped
- Progressive difficulty increase through multiple tunable parameters
- Endless waves - game continues until player loses all lives
- **Player-controlled progression** - Click "Next Wave" button to start next wave

#### Wave States
1. **Wave Start** - Player clicks "Next Wave" button, wave number displayed
2. **Wave Active** - Enemies spawning and gameplay in progress
3. **Wave Complete** - All enemies cleared/escaped, show "Wave Complete" screen
4. **Wave Transition** - Player on "Wave Complete" screen, can review stats and click "Next Wave"

#### Wave Transition System
- No automatic timer - player must click button to proceed
- "Wave Complete" screen shows:
  - Wave number completed
  - Total score
  - "Next Wave" button
- **Future expansion**: This screen will become the upgrade shop between waves
- Player can take a break, review progress, strategize before continuing

---

## 2. Enemy Type System

### Enemy Configuration Structure
Each enemy type will have the following properties:

```
Enemy Type Properties:
- speed: float - movement speed (pixels/second)
- size: Noted in px by px, basic enemy is 80px x 80px. Bigger enmies harder to hit
- points: int - score value when destroyed
- health: int - hits required to destroy (v1.0 = 1, future-proofing)
- movement_pattern: enum - STRAIGHT, ZIGZAG, HORIZONTAL, SINE_WAVE, etc.
- difficulty_rating: int (1-10) - used for spawn weighting
- sprite_color: Color - placeholder visual identifier
```

### Planned Enemy Types

#### Type 1: Basic (Current Implementation)
- **Speed**: 150 px/s
- **Size**: 80px x 80px 
- **Points**: 10
- **Health**: 1
- **Pattern**: STRAIGHT (moves straight down)
- **Difficulty**: 1
- **Description**: Standard enemy, moves in straight line down

#### Type 2: Zigzag
- **Speed**: 120 px/s (slightly slower due to horizontal movement)
- **Size**: 80px x 80px
- **Points**: 20
- **Health**: 1
- **Pattern**: ZIGZAG (moves down while oscillating left/right)
- **Difficulty**: 3
- **Description**: Harder to hit due to horizontal movement, worth more points
- **Parameters**: 
  - Zigzag amplitude: 100-150 pixels
  - Zigzag frequency: 1-2 cycles per second

#### Type 3: Speedy (Future)
- **Speed**: 250 px/s
- **Points**: 15
- **Health**: 1
- **Pattern**: STRAIGHT
- **Difficulty**: 4
- **Description**: Fast straight-moving enemy, requires quick reactions

#### Type 4: Tank (Future)
- **Speed**: 100 px/s
- **Points**: 30
- **Health**: 3
- **Pattern**: STRAIGHT
- **Difficulty**: 6
- **Description**: Slow but requires multiple hits to destroy

---

## 3. Difficulty Scaling System

### Scaling Parameters
The game gets harder over time by adjusting these parameters:

1. **Spawn Rate** - How quickly enemies spawn
2. **Enemy Speed** - How fast enemies move
3. **Enemy Mix** - Which enemy types appear and their probability
4. **Wave Size** - How many enemies per wave

### Scaling Formulas

#### Spawn Interval (seconds between spawns)
```
current_spawn_interval = base_spawn_interval * (0.95 ^ current_wave)
```
- Base: 2.0 seconds
- Gets 5% faster each wave
- Wave 1: 2.0s, Wave 5: 1.55s, Wave 10: 1.20s, Wave 20: 0.72s

#### Enemies Per Wave
```
enemies_in_wave = base_enemies + (current_wave * enemy_increase_rate)
```
- Base: 10 enemies
- Increase: 2 per wave
- Wave 1: 10, Wave 5: 18, Wave 10: 28, Wave 20: 48

#### Enemy Speed Multiplier
```
speed_multiplier = 1.0 + (current_wave * 0.05)
```
- Base: 1.0x speed
- Increases 5% per wave
- Wave 1: 1.0x, Wave 5: 1.25x, Wave 10: 1.5x, Wave 20: 2.0x

### Enemy Type Weighting by Wave

```
Waves 1-3: 
  - 100% Basic enemies

Waves 4-7:
  - 70% Basic
  - 30% Zigzag

Waves 8-12:
  - 50% Basic
  - 50% Zigzag

Waves 13-17:
  - 30% Basic
  - 40% Zigzag
  - 30% Speedy

Waves 18+:
  - 20% Basic
  - 30% Zigzag
  - 30% Speedy
  - 20% Tank
```

### Dynamic Spawn Selection Algorithm
```
1. Get available enemy types for current wave
2. Calculate weighted probability based on difficulty_rating
3. Use random weighted selection to pick enemy type
4. Apply wave speed multiplier to selected enemy
5. Spawn enemy with calculated properties
```

---

## 4. Implementation Plan

### Phase 1: Wave System Foundation
- [ ] Add wave tracking variables to game_manager.gd
- [ ] Implement wave state machine (start, active, complete, transition)
- [ ] Add wave counter to UI
- [ ] Test basic wave progression (using current enemy only)

### Phase 2: Enemy Type System
- [ ] Create enemy configuration dictionary/resource
- [ ] Refactor enemy.gd to accept configuration parameters
- [ ] Create second enemy scene with zigzag movement pattern
- [ ] Test both enemy types spawning independently

### Phase 3: Difficulty Scaling Integration
- [ ] Implement scaling formulas in game_manager.gd
- [ ] Create enemy type weighting system
- [ ] Implement dynamic spawn selection
- [ ] Apply speed multipliers to spawned enemies

### Phase 4: Testing & Balancing
- [ ] Playtest waves 1-10 for difficulty curve
- [ ] Adjust spawn rates, speeds, and weights
- [ ] Fine-tune formulas for optimal challenge
- [ ] Test edge cases (very high wave numbers)

---

## 5. Technical Implementation Details

### game_manager.gd New Variables
```gdscript
# Wave system
var current_wave: int = 1
var enemies_in_wave: int = 10
var enemies_spawned: int = 0
var wave_active: bool = false

# Difficulty scaling
var base_spawn_interval: float = 2.0
var base_enemies: int = 10
var enemy_increase_rate: int = 2

# Enemy type configuration
var enemy_types: Array[Dictionary] = []
```

### Enemy Type Configuration Example
```gdscript
{
	"name": "Zigzag",
	"scene_path": "res://scenes/EnemyZigzag.tscn",
	"base_speed": 120.0,
	"points": 20,
	"health": 1,
	"movement_pattern": "ZIGZAG",
	"difficulty_rating": 3,
	"min_wave": 4  # First wave this enemy can appear
}
```

### Movement Patterns Enum
```gdscript
enum MovementPattern {
	STRAIGHT,    # Move straight down
	ZIGZAG,      # Oscillate left/right while moving down
	HORIZONTAL,  # Move horizontally across screen
	SINE_WAVE,   # Smooth sine wave pattern
	SPIRAL       # Future: spiral pattern
}
```

---

## 6. UI Updates Required

### New UI Elements
- **Wave Counter**: Display "Wave X" at top of screen
- **Wave Transition Message**: "Wave X Complete!" during transitions
- **Enemy Kill Combo** (future): Track consecutive kills without missing

### Updated UI Elements
- Score display (already exists, may need repositioning)
- Lives display (already exists)

---

## 7. Balance Considerations

### Critical Balance Points
1. **Early Game** (Waves 1-5): Should feel easy, teach mechanics, build confidence
2. **Mid Game** (Waves 6-15): Introduce challenge, variety, test player skill
3. **Late Game** (Waves 16+): Intense, requires mastery, high stakes

### Tunable Parameters for Balancing
- Spawn interval base and scaling rate
- Enemy speed base and scaling rate
- Enemies per wave base and increase rate
- Enemy type introduction waves
- Enemy type weightings at each wave tier
- Points values for each enemy type

### Testing Metrics
- Average wave reached by playtesters
- Time to complete each wave
- Player accuracy (hits/misses ratio)
- Frustration points (where players consistently die)

---

## 8. Future Expansion Hooks

### Ready for Milestone 3
- Obstacles: Can be added to spawn in waves
- Power-ups: Can drop from specific enemy types
- Boss waves: Every 5th or 10th wave could be special
- Enemy formations: Spawn patterns beyond random positions

### Data-Driven Design
All enemy configurations and wave formulas should be easily tweakable without code changes, ideally through:
- Exported variables in Inspector
- JSON/Resource files (future)
- In-game debug menu for testing (future)

---

## 9. Open Questions & Decisions Needed

1. **Wave Type**: Time-based vs Count-based waves?
2. **Wave Transition**: How long should the pause between waves be?
3. **Difficulty Curve**: Should scaling be linear or exponential?
4. **Enemy Introduction Pace**: How quickly should new enemy types be introduced?
5. **Max Difficulty Cap**: Should difficulty cap at some point or scale infinitely?

---

## Notes
- Keep performance in mind - max enemies on screen at once?
- Mobile testing critical for spawn rate and difficulty
- Consider accessibility - should there be difficulty modes?
