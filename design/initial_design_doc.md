# Tap Tap Defense - Initial Design Document

## Project Overview
Tap Tap Defense is a mobile-first arcade shooter inspired by Centipede, featuring a unique auto-rotating turret mechanic. The player taps the screen to shoot and reverse the turret's rotation direction, creating a rhythmic bouncing pattern for targeting descending enemies.

**Platform**: Mobile (Portrait Orientation), with browser support via itch.io  
**Engine**: Godot  
**Primary Input**: Single tap mechanic

---

## Milestone 1: Core Gameplay Prototype (MVP)

### Goal
Create a minimal playable version demonstrating the core mechanic: tap to shoot and reverse turret rotation, with simple enemies descending from the top of the screen.

### Core Components

#### 1. Player/Turret System
- **Turret Base**: Stationary sprite positioned at bottom center of screen
- **Turret Barrel**: Rotating sprite that auto-rotates back and forth
- **Rotation Behavior**:
  - Constant rotation speed in one direction
  - Rotation arc covers full enemy play area (angle TBD - needs testing)
  - On tap: fire bullet AND reverse rotation direction
- **Visual Feedback**: Clear indication of turret direction/aim point

#### 2. Shooting System
- **Bullet Spawning**: Instantiate bullet at turret barrel tip on tap
- **Bullet Movement**: Travel in straight line matching turret's current angle
- **Bullet Lifecycle**: Destroy on collision or when off-screen

#### 3. Enemy System
- **Enemy Type**: Single basic enemy for MVP
- **Spawn Behavior**: 
  - Spawn at random horizontal positions along top edge
  - Descend straight down at constant speed
- **Spawn Rate**: Simple timer-based spawning (configurable interval)
- **Health**: Single hit point (destroyed by one bullet)

#### 4. Collision Detection
- **Bullet vs Enemy**: Destroy both on collision
- **Enemy vs Bottom Screen**: Game over condition (for MVP)

#### 5. Game States
- **Playing**: Active gameplay
- **Game Over**: When enemy reaches bottom
- **Reset**: Ability to restart after game over

---

## Technical Requirements

### Project Settings
- **Resolution**: 1080x1920 (portrait 9:16 aspect ratio)
- **Stretch Mode**: Configure for multiple device sizes
- **Input**: Touch screen (tap) with mouse fallback for testing

### Scene Structure (MVP)
- **Main.tscn**: Root game scene
  - Turret node (with rotation logic)
  - Enemy spawn points
  - UI layer (minimal - score counter optional)
- **Bullet.tscn**: Bullet prefab with collision shape
- **Enemy.tscn**: Enemy prefab with collision shape and movement

### Scripts Required
- `turret.gd`: Handles rotation, direction reversal, bullet spawning
- `bullet.gd`: Handles movement and collision
- `enemy.gd`: Handles movement and collision
- `game_manager.gd`: Spawns enemies, tracks game state

---

## Key Design Questions to Test During MVP

1. **Rotation Speed**: What feels responsive but still challenging?
2. **Rotation Arc**: What angle range properly covers the play area? (Likely 120-180 degrees)
3. **Enemy Speed**: What creates engaging but fair difficulty?
4. **Spawn Rate**: How frequent should enemy spawns be?
5. **Bullet Speed**: Fast enough to feel responsive, balanced for challenge?

---

## Milestone 2: Enhanced Gameplay (Future)

### Features to Add Post-MVP
- **Obstacles**: Destructible blocks in the play area (Centipede-style)
- **Enemy Variety**: Enemies with different movement patterns
  - Zigzag movement
  - Horizontal movement
  - Variable speeds
- **Power-ups**: Collectible upgrades
  - Rapid fire
  - Multi-shot
  - Speed boost
- **Wave System**: Progressive difficulty with wave breaks
- **Scoring System**: Points for kills, combo bonuses

---

## Milestone 3: Full Game Experience (Future)

### Polish & Production Features
- **Main Menu**: Start, settings, credits
- **Settings Menu**: Sound volume, difficulty options
- **UI/UX Polish**: 
  - Score display
  - Health/lives system
  - Wave counter
  - Visual effects (particles, screen shake)
- **Audio**: 
  - Background music
  - Shooting sounds
  - Enemy destruction sounds
  - UI feedback sounds
- **Mobile Optimization**:
  - Touch input refinement
  - Performance optimization
  - Battery efficiency
- **Browser Deployment**: itch.io HTML5 export configuration
- **Visual Scaling**: Support for multiple device resolutions

---

## Development Approach

### Phase 1: Foundation
1. Set up project with correct resolution and input settings
2. Create turret rotation system
3. Implement tap-to-shoot-and-reverse mechanic
4. Test and tune rotation speed/arc

### Phase 2: Combat Loop
1. Create bullet system
2. Create basic enemy
3. Implement collision detection
4. Add enemy spawning system

### Phase 3: Game Loop
1. Add game over condition
2. Add restart functionality
3. Playtest and balance

### Phase 4: Iteration
1. Gather playtest feedback
2. Refine core mechanics
3. Prepare for Milestone 2 expansion

---

## Success Criteria for MVP
- [ ] Turret rotates smoothly and reverses on tap
- [ ] Bullets fire in the direction turret is facing
- [ ] Enemies spawn and descend predictably
- [ ] Collision detection works reliably
- [ ] Game can be played for 30+ seconds before game over
- [ ] Core mechanic feels satisfying and skill-based
- [ ] Game runs smoothly on mobile device (60 fps target)

---

## Notes
- Keep code modular for easy expansion to Milestone 2
- Document node connections and signals clearly in comments
- Test rotation arc angles early to ensure full coverage of play area
- Consider adding visual guide lines during development to tune rotation arc
