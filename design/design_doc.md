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

## Next Milestone: Player Health & Damage Rework + Power-Ups

This milestone replaces the Lives System described in Completed Features above with a depletable health bar, reworks how enemies threaten the player, and adds four power-ups. It's fine if this milestone spans multiple sessions — log progress in session notes as we go.

### Phase 1: Player Health & Damage Rework

**Core Concept Change**
Enemies no longer escape off the bottom of the screen. Instead, once an enemy descends to a "hover line" just above the turret, it stops there (keeping whatever x it arrived at) and periodically "bumps" the player for damage until it is destroyed. Enemies that aren't killed pile up indefinitely — this is the primary difficulty-scaling mechanic for the milestone (waves get harder as more unkilled enemies accumulate and stack damage-per-second on the player), not a bug to guard against.

**Player Health**
- Replace integer lives (`max_health`/`current_health`, currently 3) with a numeric health pool.
- Proposed default: `max_health = 100` (exported/tunable in Inspector, matching the pattern already used for wave-scaling variables).
- `health_changed(new_health)` signal is kept, but now carries current HP out of `max_health` instead of a lives count (0-3).
- Game over still triggers when `current_health <= 0`.

**Enemy Hover State**
- New internal enemy state: `DESCENDING` → `HOVERING`. Movement pattern (STRAIGHT/ZIGZAG) governs descent as today; once `position.y` reaches a `hover_line_y` (a tunable value on `game_manager.gd`, proposed default ~270px above the turret), the enemy stops descending and enters `HOVERING`.
- The escape check (`position.y > 1920` in `enemy.gd`) is removed entirely — there is no more escaping.

**Bump Damage**
- While `HOVERING`, each enemy runs its own damage-tick timer and emits `enemy_bumped(damage)` on each tick. `game_manager.gd` listens (same pattern as `enemy_killed`) and subtracts from `current_health`.
- Damage is a **discrete chunk per tick**, not continuous drain.
- Values are per-enemy-type (added to the existing `enemy_types` config dictionary alongside `speed`/`points`), so future enemy types can have their own damage/interval profile without new systems:
  - Basic: `bump_damage = 5`, `bump_interval = 1.0s`
  - Zigzag: `bump_damage = 4`, `bump_interval = 0.75s`
- Multiple hovering enemies tick independently — damage scales naturally with how many enemies are alive, which is the intended pile-up difficulty curve.
- Simple visual feedback on each bump tick (e.g. a small lunge/nudge tween on the enemy's placeholder ColorRect) — no new art or nodes required.

**Wave Completion**
- Unchanged in structure: a wave completes once every spawned enemy for that wave has been destroyed. Since enemies can no longer escape, this naturally means the player must clear the full hover-pile (not just survive it) before advancing — consistent with "wave ends when all spawned enemies are destroyed, or the player dies."

**UI**
- Replace the `LivesContainer` heart icons with a health bar (`ProgressBar`).
- `ui_controller.gd`'s `_on_health_changed` is rewritten to set the bar's value instead of rebuilding heart nodes.

**Implementation Tasks**
- [x] `game_manager.gd`: replace lives int with `max_health`/`current_health` HP pool
- [x] `game_manager.gd`: add `hover_line_y` export, `bump_damage`/`bump_interval` fields to enemy_types config
- [x] `enemy.gd`: add hover state, remove escape logic, add bump-tick timer + `enemy_bumped` signal, add bump visual nudge
- [x] `game_manager.gd`: connect `enemy_bumped` per spawned enemy, implement `_on_enemy_bumped`
- [x] `ui_controller.gd`: rewrite `_on_health_changed` to drive the `HealthBar` instead of hearts
- [x] Create `HealthBar` UI node in `main.tscn`
- [x] Playtest: confirm hover line is reachable across the turret's full rotation arc, tune `max_health`/damage values so early waves feel fair and later waves feel overwhelming

**Phase 1 status: Complete.** Playtested and confirmed working — hover/bump behavior feels smooth, wave completion and game over both trigger correctly. Health bar resized to 400x44 with a dark background/red fill for visibility.

**Success Criteria**
- Enemies stop and hover just above the turret instead of escaping
- Player takes periodic chunk damage from each hovering enemy until it's killed
- Health bar accurately reflects remaining HP and drives game over at 0
- Waves only complete when every spawned enemy is destroyed
- Difficulty visibly ramps as unkilled enemies accumulate

### Phase 2: Power-Ups

Four power-ups from the backlog are in scope: **Double Shot**, **Bouncing Ball**, **Laser** (pierces multiple enemies), **Slow Turret Rotation**. Mechanics below are an initial proposal — we'll confirm/adjust specifics for each when we reach it, since none of this infrastructure (pickups, timed effects) exists yet.

- **Double Shot**: turret fires two bullets per tap (slight angular spread) for a limited duration/shot count after pickup.
- **Bouncing Ball**: bullet variant that bounces off the play area's left/right edges instead of being destroyed, up to N bounces or until it hits an enemy.
- **Laser**: bullet variant that pierces through multiple enemies instead of being destroyed on first hit.
- **Slow Turret Rotation**: temporarily reduces turret `rotation_speed` for easier aiming.
- Acquisition method (drop from killed enemies vs. periodic field spawn) and collection method (auto-collect near turret vs. tap-collect) still need to be decided — to be scoped when Phase 1 is stable.

**Pickup Mechanic (decided & implemented)**
- Enemies have a chance to drop a power-up on death (`powerup_drop_chance`, currently 15%) at the kill position.
- Pickups float straight down slowly (`fall_speed`, currently 100 px/s) — each type has a distinct placeholder color and a short text label so they're identifiable at a glance:
  - Double Shot = Yellow, "2X"
  - Bouncing Ball = Cyan, "BB"
  - Laser = Magenta, "LZ"
  - Slow Turret Rotation = Orange, "SLW"
- The player must shoot a pickup to collect it (reuses existing bullet collision, new `"powerups"` group). If it reaches the hover line uncollected, it's destroyed with no effect — collection is not automatic/proximity-based.
- `game_manager.gd`'s `_on_powerup_collected(type)` currently just prints which type was collected — actual gameplay effects are implemented one at a time below.
- **Future balance note**: drop rate may eventually need to scale with wave number and/or time-since-last-drop so power-ups stay meaningful late-game — flagged for tuning later, not designed yet.

**Progression System (decided & implemented)**
Power-ups are permanent stacking upgrades, not timed pickups (superseding the earlier timed-buff proposal above):
- Player has **3 slots**; each slot holds one *distinct* power-up type (`equipped_powerups` dict in `game_manager.gd`, capped at `MAX_EQUIPPED_POWERUPS = 3`). No stacking 3 copies of the same type into separate slots.
- Shooting a pickup for a **new type** with a free slot → equips it at level 1.
- Shooting a pickup for a type **already equipped** → levels it up by 1, up to that type's max level (`powerup_max_level`, currently 5 for all types — placeholder, will differ per type as we tune).
- Shooting a pickup for a type **already at max level** → triggers a temporary **super-boost** (`super_boost_extra_levels` above max, currently +3, lasting `super_boost_duration` seconds, currently 8s), then reverts to the permanent max-level effect when the timer runs out. Re-triggering while already boosted refreshes the timer.
- Shooting a pickup for an **unequipped type with all 3 slots full** → awards `powerup_bonus_points` (currently 50) instead of doing nothing.
- Pickups keep spawning/dropping at the normal rate regardless of slot/level state.

**Implementation Tasks**
- [x] Design and implement pickup spawn/collection mechanic
- [x] Design and implement the shared power-up progression system (slots, leveling, super-boost, bonus points)
- [x] Implement Double Shot: `turret.gd` fires `shot_count` bullets in a fan spread (`shot_spread_degrees`); single level (2 balls), super-boost = 3 balls for 3s. Originally allowed a 2nd permanent level (3 balls) but that felt too strong in playtest, so it was cut back to one level plus the temporary boost.
- [x] Implement Bouncing Ball: `bullet.gd` adds `bounces_remaining`, reflecting horizontal direction when it reaches the play area's left/right edge (x=0 or x=1080) instead of a physics collision body - consistent with the script-driven movement style used everywhere else in the project. Level 1 = 1 bounce, level 2 = 3 bounces, level 3 (max) = 4 bounces, super-boost = 5 bounces for 5s.
- [x] Implement Laser: `bullet.gd`/`turret.gd` add `pierce_count` (bullets survive hitting up to that many enemies instead of dying on first hit); level 1 = pierce 2, level 2 (max) = pierce 3, super-boost = pierce 5 for 5s
- [x] Implement Slow Turret Rotation: `game_manager.gd` scales `turret.rotation_speed` from its captured base value; level 1 = 25% slower, level 2 (max) = 50% slower, super-boost = 75% slower for 5s
- [ ] Playtest power-up balance, pickup frequency, and per-type max levels/super-boost numbers (all currently placeholder defaults)

**QoL: Power-Up Loadout Display**
Added a 3-slot HUD readout (`PowerUpDisplay` in `main.tscn`, bottom-right, mirroring the Pause button) showing which power-ups are currently equipped and at what level, for testing/player visibility. Each slot shows a colored icon with the type's short label ("2X"/"BB"/"LZ"/"SLW") and a level number below. Empty slots show as a dim gray box. Driven by a new `powerup_loadout_changed` signal on `game_manager.gd`, emitted whenever `equipped_powerups` changes.
