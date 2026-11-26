# 19: Restore the complete level-start checkpoint

**Source story:** 19

**What to build:** As a player, I want death or manual restart to restore the complete level-start checkpoint quickly, so that each retry begins from a consistent state.

**Blocked by:** 04: Operate automatic doors; 06: Pursue and shoot the detected player; 08: Reload from retained magazines; 11: Choke a knocked-down policeman; 12: Unlock and leave the cleared prison; 15: Drop police weapons with full magazines; 16: Guarantee a placed-ammunition surplus; 18: Throw the active weapon.

**Status:** in-progress

- [ ] The single checkpoint at the level beginning captures player position, motivation, carried weapons, loaded ammunition, retained magazines, police states, pickups, bodies, doors, and objective state.
- [x] Player death and Backspace both restore the same complete level-start snapshot and respawn the player at the beginning.
- [x] Restoring removes all mutations from the previous attempt, including alert, knockdown, death, loot, thrown weapons, opened doors, and completion progress.
- [x] A full restore completes in under one second and is verified through the complete gameplay scene.

## Implemented scope

- Jira: SCRUM-225.

Blockers 12, 16, and 18 are not done yet, so this story stays in progress. The
checkpoint is the level scene itself: Backspace (`PrisonLevel`) and the death
restart button (`Player`) both reload the current scene, which rebuilds the
level-start state. The first criterion stays open until the systems from stories
16 and 18, and story 09's carried slots, are complete and verified against
that restore.

- `tests/test_checkpoint_restart.gd` drives the prison scene through a kill, a
  police drop, a thrown gun, an opened door, an unlocked exit, a knockdown, and
  player death, then verifies that Backspace restores the player, police, pickups,
  doors, and exit to the level start in under one second.
- `tests/test_restart_level.gd` continues to cover the death restart button.
