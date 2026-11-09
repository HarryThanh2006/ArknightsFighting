# Smoke Test: Critical Paths

**Purpose**: Run these 10-15 checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file)
**Update**: Add new entries when new core systems are implemented.

## Core Stability (always run)

1. Game launches to main menu without crash
2. A match can be started from the main menu (Versus or Quick Match)
3. Main menu responds to all inputs without freezing

## Core Mechanic (update per sprint)

<!-- Add the primary mechanic for each sprint here as it is implemented -->
4. [Primary mechanic — update when first core system is implemented, e.g. "Both fighters move, attack and land hits; HP drops only on hitbox/hurtbox overlap"]

## Data Integrity

5. Replaying a recorded input file produces the same per-tick checksum every run (once the replay system is implemented)
6. Rematch resets both fighters, timer and round count to their start values (once the match flow is implemented)

## Performance

7. No visible frame rate drops on target hardware (60fps target)
8. No memory growth over 5 minutes of play (once core loop is implemented)
