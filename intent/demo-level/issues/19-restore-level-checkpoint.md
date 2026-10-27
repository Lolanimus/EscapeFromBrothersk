# 19: Restore the complete level-start checkpoint

**Source story:** 19

**What to build:** As a player, I want death or manual restart to restore the complete level-start checkpoint quickly, so that each retry begins from a consistent state.

**Blocked by:** 04: Operate automatic doors; 06: Pursue and shoot the detected player; 08: Reload from retained magazines; 11: Choke a knocked-down policeman; 12: Unlock and leave the cleared prison; 15: Drop police weapons with full magazines; 16: Guarantee a placed-ammunition surplus; 18: Throw the active weapon.

**Status:** ready-for-agent

- [ ] The single checkpoint at the level beginning captures player position, motivation, carried weapons, loaded ammunition, retained magazines, police states, pickups, bodies, doors, and objective state.
- [ ] Player death and Backspace both restore the same complete level-start snapshot and respawn the player at the beginning.
- [ ] Restoring removes all mutations from the previous attempt, including alert, knockdown, death, loot, thrown weapons, opened doors, and completion progress.
- [ ] A full restore completes in under one second and is verified through the complete gameplay scene.

