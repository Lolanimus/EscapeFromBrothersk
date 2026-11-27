# 19: Restore the complete level-start checkpoint

**Source story:** 19

**What to build:** As a player, I want death or manual restart to restore the complete level-start checkpoint quickly, so that each retry begins from a consistent state.

**Blocked by:** 04: Operate automatic doors; 06: Pursue and shoot the detected player; 08: Reload from retained magazines; 11: Choke a knocked-down policeman; 12: Unlock and leave the cleared prison; 15: Drop police weapons with full magazines; 16: Guarantee a placed-ammunition surplus; 18: Throw the active weapon.

**Status:** done

- [x] The single checkpoint at the level beginning captures player position, motivation, carried weapons, loaded ammunition, retained magazines, police states, pickups, bodies, doors, and objective state.
- [x] Player death and Backspace both restore the same complete level-start snapshot and respawn the player at the beginning.
- [x] Restoring removes all mutations from the previous attempt, including alert, knockdown, death, loot, thrown weapons, opened doors, and completion progress.
- [x] A full restore completes in under one second and is verified through the complete gameplay scene.

## Implemented scope

- Jira: SCRUM-225.

The checkpoint is the level-start state of the level scene itself. Each level has
exactly one: the state `res://scenes/main.tscn` builds when it loads, with the
player at the starting cell. Backspace (`PrisonLevel._input`) and the death restart
button (`Player._restart_level`) both call `reload_current_scene()`, which discards
the whole attempt and rebuilds that state, so player position, motivation, carried
weapons, loaded ammunition, retained magazines, the 24-police roster, placed pickups,
bodies, doors and the exit objective all return to the level beginning. Nothing is
captured later in the level, so it is the single checkpoint at the beginning and
both restart paths restore the same state.

- The restore gap found: magazine pickup feedback was added to the scene tree root
  and its expiry tween was bound to the player, so a restart within 1.5 seconds of
  collecting a magazine left "Magazine collected!" on screen permanently. The
  feedback now belongs to the player and is discarded with the attempt.
- `tests/test_checkpoint_restart.gd` observes the fresh level start, then plays four
  attempts through the real gameplay scene and input: Backspace mid-fight (with an
  alerted policeman shooting the player), Backspace after killing every policeman,
  unlocking the exit and leaving, the death restart button, and Backspace after
  death. Each attempt takes the katana and pistol into the story 09 slots, collects
  placed magazines, fires rounds that kill a policeman who drops his gun, throws the
  pistol to knock a policeman down, opens a door and throws the katana. After every
  restore the player, all 24 policemen, weapon and magazine pickups, loot, doors,
  exit objective and nodes outside the level must equal the observed level start,
  and the full 24-police level must be restored in under one second (about 30-45 ms
  headless).
- `tests/test_restart_level.gd` continues to cover the death restart button UI.
