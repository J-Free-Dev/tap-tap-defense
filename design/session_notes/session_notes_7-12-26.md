# Session Notes - Tap Tap Defense

## Session Date: 2026-07-12

---

## Completed This Session

### Project Housekeeping [COMPLETED]
- Committed and pushed prior uncommitted local changes to `origin/main`
- Added `.gitignore` for `new-game-project/.godot/` (editor cache should never be tracked)
- Consolidated design docs down to a single living `design_doc.md` per updated CLAUDE.md rules:
  - Removed the stale, never-implemented "Tank Enemy" milestone section
  - Removed superseded `design_doc_v2.0.md` (content already reflected in `design_doc.md`)
  - Moved session notes into `design/session_notes/`, one dated file per session going forward
- Updated `CLAUDE.md`:
  - Added a **Feature Backlog (Reference Only)** section listing the full complete feature list the user is tracking in Asana - explicitly non-authoritative, exists only so architecture decisions don't conflict with known future work
  - Documented the session notes workflow (new dated file per session, same structure as the prior one)
- Fixed `project.godot` window size: added `window_size/window_width_override` / `window_height_override` (540x960) so the game no longer launches at full 1080x1920 and needs manual resizing every run
- Fixed a latent case-sensitivity bug in `turret.gd`: was preloading `res://scenes/Bullet.tscn` (capital B) when the actual file is `bullet.tscn` - silently worked on Windows/NTFS, would have broken on a case-sensitive export target

### Player Health & Damage Rework (Milestone Phase 1) [COMPLETED - playtested and confirmed]
- Replaced the old 3-lives system with a depletable health bar (`max_health`/`current_health`, default 100)
- Enemies no longer escape off-screen. They now descend to a "hover line" just above the turret, stop, and periodically deal chunk damage ("bump") to the player until killed
- Bump damage/interval is per-enemy-type (Basic: 5 dmg/1.0s, Zigzag: 4 dmg/0.75s), with a small visual lunge animation on each tick
- Wave completion changed accordingly: a wave now only completes once every spawned enemy is destroyed (no more "escape" path) - unkilled enemies piling up and stacking damage is the intended late-wave difficulty ramp, not a bug to guard against
- New `HealthBar` (`ProgressBar`) UI node replacing the old heart icons, styled with a dark background and red fill

### Power-Up System (Milestone Phase 2) [COMPLETED - implemented, mid-playtest]
- **Pickup mechanic**: enemies have a chance (`powerup_drop_chance`, currently 50% for testing, normally 15%) to drop a power-up on death. Pickups float down slowly and must be **shot** to collect (not proximity-collected) - reuses the existing tap-to-shoot input model. Uncollected pickups are destroyed with no effect if they reach the hover line.
- **Progression system**: player has 3 loadout slots, each holding one distinct power-up type:
  - New type + free slot -> equips at level 1
  - Pickup of an already-equipped type -> permanent level up (to that type's max level)
  - Pickup of an already-maxed type -> temporary "super-boost" above max for a few seconds, then reverts
  - Pickup of an unequipped type with all 3 slots full -> converts to bonus score points instead of doing nothing
- **Double Shot**: fires `shot_count` bullets in a fan spread. Single permanent level (2 balls) - originally allowed a 2nd level (3 balls) but that felt too strong in playtest, so it was cut back. Super-boost: 3 balls for 3s.
- **Laser**: bullets gain `pierce_count`, surviving hits on multiple enemies instead of dying on the first. Level 1 = pierce 2, level 2 (max) = pierce 3. Super-boost: pierce 5 for 5s.
- **Bouncing Ball**: bullets reflect off the left/right play area edges (simple script-based x-boundary check, no physics collision bodies needed) instead of dying. Level 1 = 1 bounce, level 2 = 3 bounces, level 3 (max) = 4 bounces. Super-boost: 5 bounces for 5s.
- **Slow Turret Rotation**: scales `turret.rotation_speed` down from its captured base value. Level 1 = 25% slower, level 2 (max) = 50% slower. Super-boost: 75% slower for 5s.
- All 4 power-up types/levels are placeholder-tuned defaults, called out throughout as easy to retune via exported/dictionary values.

### QoL: Power-Up Loadout Display [COMPLETED]
- Added a 3-slot HUD readout (`PowerUpDisplay`, bottom-right of screen, mirroring the Pause button) showing currently equipped power-ups and their level, for testing/player visibility
- Each slot: colored icon with a short type label ("2X"/"BB"/"LZ"/"SLW", matching the pickup's own color/label) + a level number below it; empty slots show as a dim gray box
- Also added the same short label directly onto power-up pickups in the play field (they were hard to tell apart by color alone)
- Driven by a new `powerup_loadout_changed` signal on `game_manager.gd`

---

## Technical Implementation Details

### New/Modified Files
```
/scenes/
  - powerup.tscn (NEW - power-up pickup prefab: Area2D + ColorRect + Label + CollisionShape2D)
  - main.tscn (HealthBar, PowerUps container, PowerUpDisplay loadout UI added)

/scripts/
  - game_manager.gd (health pool, hover/bump wiring, power-up drop/progression system)
  - enemy.gd (hover state, bump-tick timer, removed escape logic)
  - bullet.gd (pierce_count, bounces_remaining)
  - turret.gd (shot_count, pierce_count, bounce_count; fixed Bullet.tscn path bug)
  - ui_controller.gd (health bar wiring, power-up loadout display)
  - powerup.gd (NEW)
```

### Key Design Patterns Introduced
- Power-up type config lives as parallel `Dictionary`s on `game_manager.gd` (`powerup_max_level`, `powerup_super_boost_duration`, `powerup_colors`, `powerup_short_labels`) keyed by an integer type - same "config dictionary" pattern already established for enemy types
- Effects are applied via `_apply_powerup_effect(type, level)` / `_trigger_super_boost(type)` / `_revert_super_boost(type)`, each a `match` on type that pushes a value onto the `turret` node (`shot_count`, `pierce_count`, `bounce_count`, `rotation_speed`) - the turret stays a passive "dumb" node that just reads exported tunables, all decision logic lives in `game_manager.gd`
- Super-boosts are tracked via a `super_boost_timers` dictionary counted down each `_process(delta)`, not Godot `Timer` nodes/async - keeps it consistent with the delta-accumulator style already used for enemy bump ticks

---

## Testing Notes

### Known Issues / Observations
- Power-up drop chance is currently set to 50% for active testing convenience - needs to be dialed back down (originally 15%) before real balance testing
- Bouncing Ball, Laser, and Slow Turret Rotation's exact numbers are first-pass guesses, not yet playtested as thoroughly as Double Shot was
- Haven't yet playtested all 4 power-ups equipped/interacting simultaneously in a long run

### Balance Observations
- Double Shot's original 2nd permanent level (3 balls) trivialized the game - cut back to a single level + temporary boost. Worth watching whether the other 3 power-ups need the same treatment once tested more.

---

## Code Quality Notes
- All new power-up logic follows existing conventions: exported tunables on `turret.gd`, signal-based communication, config dictionaries on `game_manager.gd`
- No physics bodies/collision layers were added for Bouncing Ball - kept it consistent with the project's existing script-driven movement style rather than introducing a new interaction pattern
- All visuals remain placeholder `ColorRect`/`Label` - no sprites yet, as established from the start of the project

---

## Next Session
- Playtest the full milestone (health/damage rework + all 4 power-ups) together in a longer run, at normal drop rate
- Tune remaining placeholder numbers (Bouncing Ball, Laser, Slow Turret max levels/boosts) based on how they actually feel
- Once satisfied, promote this milestone into `design_doc.md`'s Completed Features and scope the next milestone with the user (per the Asana backlog)
