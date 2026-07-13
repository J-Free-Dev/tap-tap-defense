# Tap Tap Defense - Claude Development Guide

This is a video game development project being done in the GODOT engine. Your job is to help me create my vision for the video game I'm calling 'Tap Tap Defense'. This document defines how we work together, what tools you use, and how our conversations should be structured.

This document should also be iterative, meaning we should be looking for patterns of things you regularly have to ask for permission to do and adjust our doc to allow you better access to appropriate tools. The idea is to start with a finely tuned scope of how you help me develop, and then iterate into a wider scope over time to speed up our process.

---

## Project Scope

**Current Focus:** Work only on the NEXT milestone. The design document should contain everything completed so far, plus detailed steps for the immediate next milestone only.

**Future Planning:** All planning beyond the very next milestone should be kept out of scope of this project. We focus on one milestone at a time.

---

## Feature Backlog (Reference Only — Asana is source of truth)

This is a non-authoritative list of features on the roadmap, tracked and sequenced in Asana. It exists here only so architectural decisions during the current milestone don't paint us into a corner against known future work. **This is not a plan.** Never expand this list into tasks, phases, or design detail — that only happens once a feature becomes the active "Next Milestone" in design_doc.md.

- Health bar
- Enemy damage rework (attack health instead of lives)
- All Enemies: Teleport, Slow Tank, updated Zigzag, Shield
- Bosses: Boss1, Boss2, (stretch) Boss3+
- Persistent Progress: Tower Rewards
- Power-Ups: Double Shot, Bouncing Ball, Laser (pierces multiple enemies), Slow Turret Rotation
- Art Update
- Music
- Menu
- Combat (stretch: multiple combat)

---

## Design Document Maintenance

The project uses a single living design document at `/design/design_doc.md` that is updated after each milestone completion.

### Document Structure
The design_doc.md contains two main sections:
1. **Current State / Completed Features** - Everything that has been implemented and is working
2. **Next Milestone** - The single immediate task we're working on next

### Session Notes

At the end of each working session, create a new dated file in `/design/session_notes/` (e.g. `session_notes_7-12-26.md`) following the same structure as the most recent existing file in that folder. Session notes are a running log — never overwrite a prior session's file, always add a new one. This keeps a full history of progress/decisions without cluttering design_doc.md, which only ever reflects the current state.

### When to Update the Design Document
Update the design document when:
- A milestone is completed (all tasks checked off)
- Moving to a new milestone
- User requests a design doc update

### How to Update the Design Document

**Step 1: Move completed milestone to "Completed Features"**
- Take the completed "Next Milestone" section
- Summarize what was implemented
- Add it to the "Completed Features" section in appropriate place
- Remove implementation tasks/checkboxes (keep only what was built)

**Step 2: Add new "Next Milestone" section**
- Ask user what the next milestone is
- Create detailed implementation plan with:
  - Specifications for the feature
  - Phase-by-phase tasks with checkboxes
  - Technical implementation details
  - Code examples where helpful
  - Success criteria
  - Balance/design considerations

**Step 3: Remove all future planning**
- Delete any mentions of features beyond the next milestone
- Keep document focused on: completed work + next immediate step
- No "Future Plans", "Milestone 3 Preview", or "What's Next" sections

### Example Update Flow

```
User: "I finished implementing the Tank enemy. Let's work on power-ups next."

Claude: 
1. Reads current design_doc.md
2. Moves "Tank Enemy Implementation" details into "Completed Features"
3. Asks clarifying questions about power-ups scope
4. Creates new "Next Milestone: Power-Up System" section
5. Ensures no future plans are mentioned beyond power-ups
6. Overwrites design_doc.md with updated version
```

### Key Principles
- **One milestone at a time** - Never include multiple future milestones
- **Living document** - Same file gets updated, not versioned
- **Completed work grows** - Each update adds to completed features
- **Next step replaces** - New milestone replaces the old one entirely
- **No speculation** - Don't plan beyond what user has committed to working on

---

## General AI Development Rules

1) Always ask questions if it will improve your results
2) Only ask me one question at a time. Never ask multiple questions at once
3) Obey the directory setup when making new files
4) Always consider the documentation before making design choices or executing on a coding task
5) When tasks are failing repeatedly always double check that you're using the correct file names
6) Do not tell me my idea is good without actually thinking it's a good idea and having a reason you can give me

---

## CONVERSATION STRUCTURE RULES

### Workflow Overview
Our development process follows a structured loop:
1. **Review Current Milestone** - Start each session by reviewing the active design document and CLAUDE.md/Project files for rules on how to work.
2. **Create Assets** - I create UI nodes/scenes in Godot based on your instructions  
3. **Wire Code** - You write GDScript to connect the assets
4. **Test & Iterate** - Test functionality, fix issues, adjust as needed
5. **Update Documentation** - Update session notes when milestone tasks complete

### Response Formatting Standards

**1. Starting a New Task:**

Use clear headings and bold text for action items.

Example:
```
## Next Task: Create Power-Up UI Elements

**Please create the following nodes in your Main scene:**

1. **PowerUpContainer** (HBoxContainer)
   - Position: Top-right corner  
   - Add as child of: UI/HUD

2. **PowerUpIcon** (TextureRect)
   - Size: 64x64
   - Add as child of: PowerUpContainer

**Let me know when you've created these nodes.**
```

**2. Asking Questions:**

One question at a time, clearly formatted with bold.

Example:
```
**Question:** Would you prefer the obstacles to spawn randomly or in predefined patterns?
```

**3. Providing Code:**

Always reference file paths with line numbers when relevant.

Example:
```
I'll update the enemy spawning logic in game_manager.gd:

[code block here]

This adds obstacle collision detection to the spawn_enemy() function at line 95.
```

**4. Explaining Concepts:**

Use headings and bullet points for clarity.

Example:
```
## How Godot Signals Work

Signals are Godot's event system:
- **Emitter**: The node that sends the signal (e.g., enemy dies)
- **Receiver**: The node that listens for the signal (e.g., game manager)
- **Connection**: Links emitter to receiver function

In our case:
- Enemy emits `enemy_killed` signal
- GameManager connects to it with `_on_enemy_killed()` function
```

**5. Summarizing Progress:**

Use labels and checkmarks for completed work.

Example:
```
## Progress Summary

**[COMPLETED]** Power-up system foundation
- Power-up spawning ✓
- Pickup detection ✓
- Rapid fire effect ✓

**[IN PROGRESS]** Multi-shot power-up
- Waiting for UI nodes

**Next Step:** Create the multi-shot UI indicator
```

### Conversation Flow Examples

**Example 1: Beginning a Session**
```
User: "Let's start working on obstacles"