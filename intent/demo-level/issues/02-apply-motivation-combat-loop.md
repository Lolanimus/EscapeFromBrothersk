# 02: Apply the motivation combat loop

**Source story:** 2

**What to build:** As a player, I want police attacks to reduce my motivation and permanent kills to restore it, so that survival and the elimination objective reinforce the same combat loop.

**Blocked by:** 03: Acquire and fire the pistol; 06: Pursue and shoot the detected player.

**Status:** done

- [x] The player starts with 100 motivation, loses 25 motivation from each police bullet damage event, and dies at zero.
- [x] Permanently killing a policeman restores 10 motivation up to a maximum of 100.
- [x] Lower motivation introduces no additional mechanical or presentation penalty beyond proximity to death.
- [x] Motivation changes, the cap, permanent-kill restoration, and death are verified through observable gameplay tests.


## Implementation and verification

- Jira: SCRUM-157 (Jira retains the original story number 06).
- The gameplay scene displays a motivation bar and a death notice at zero. Dead players cannot move, aim, attack, reload, collect pickups, or regain motivation; police stop attacking the dead player.
- Checkpoint restoration belongs to story 19.
- Scene tests: `godot --headless --path . --script tests/test_motivation.gd` exercise real police/player projectile collisions, restoration, the cap, unchanged movement and presentation, HUD state, and death.
- Regression suites passed: combined enemy, pistol, punch/recovery, enemy navigation, prison navigation/doors, player animation, and main menu.
- Rendered and inspected the motivation bar at 75 and the death notice at zero.
