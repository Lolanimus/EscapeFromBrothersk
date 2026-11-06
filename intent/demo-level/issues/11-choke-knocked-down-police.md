# 11: Choke a knocked-down policeman

**Source story:** 11

**What to build:** As a player, I want to choke a knocked-down policeman through an interruptible hold action, so that I can permanently eliminate him without ammunition while accepting close-range risk.

**Blocked by:** 02: Apply the motivation combat loop; 10: Punch and recover knocked-down police.

**Status:** done

- [x] Holding left click beside a knocked-down policeman for three uninterrupted seconds permanently kills him.
- [x] The player cannot move while choking, and visible progress communicates the hold duration.
- [x] Releasing left click, attempting to move, or taking damage cancels the choke and resets its progress.
- [x] A completed choke produces the same permanent-death and motivation-restoration outcomes as other permanent kills.


## Implementation and verification

- Jira: SCRUM-183. This branch includes completed story 02 / SCRUM-157 as its prerequisite.
- With fists active, hold left click beside the nearest unconscious policeman within 64 pixels and an unobstructed reach. A continuous hold can follow the initial punch. Recovering police remain eligible while they are still unconscious.
- The HUD displays a three-second choke progress bar and hold instruction. The player stays stationary while choking.
- Release, any movement input (including opposing keys), damage, lost reach, an obstruction, target removal, or recovery cancels the hold and resets progress. After an interruption while left click remains held, release and press again to begin a fresh hold.
- Completion uses the same permanent-death operation as player projectiles: the body remains distinct, collision and gunfire stop, and 10 motivation is restored once, capped at 100.
- Scene coverage: `godot --headless --path . --script tests/test_choking.gd`. Tests use real mouse/movement inputs, real police projectiles, elapsed time, and visible HUD/enemy state.
- Existing motivation, combined combat, punch/recovery, pistol, enemy routing, prison navigation/doors, player animation, rear pistol animation, and main-menu suites were checked alongside the new suite.
- Rendered and inspected the in-progress choke instruction and progress bar.

## Playtest addition

The death screen includes a Restart level button that reloads the current scene from its beginning. `tests/test_restart_level.gd` verifies the button through viewport mouse input and checks the restored player, pickups, and police. Full checkpoint snapshots remain part of story 19.
