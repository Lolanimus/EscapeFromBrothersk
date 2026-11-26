# 15: Drop police weapons with full magazines

**Source story:** 15

**What to build:** As a player, I want permanently killed policemen to drop their guns with full magazines, so that combat can replenish my limited ranged ammunition.

**Blocked by:** 09: Carry and switch the limited loadout; 13: Acquire and fire the shotgun; 14: Acquire and fire the AK-47.

**Status:** done

- [x] Every permanently killed policeman drops his equipped pistol, shotgun, or AK-47 with one full compatible magazine.
- [x] A dropped weapon can be acquired or swapped through the standard interaction while preserving its specified ammunition state.
- [x] Interacting with the same ranged weapon already carried collects only its full compatible magazine when capacity permits.
- [x] Drops do not count toward the guaranteed placed-ammunition supply, and all weapon types are covered by observable loot tests.

## Implemented scope

- Jira: SCRUM-204.
- `Enemy.kill_permanently()` drops the policeman's equipped gun at his body with a
  fresh full magazine. Drops join the `police_drops` group and are added to the
  scene root, never under the level's placed `Pickups`, so story 16's guaranteed
  supply cannot count them.
- A dropped gun of a different type is acquired with E like any other gun pickup.
  What happens to the replaced gun is still the undecided swap rule owned by story 09.
- E on a dropped gun of the type already active moves only its full magazine into
  the retained magazines when the four-magazine limit (loaded magazine included)
  allows it. The gun stays on the floor with no magazine; at the limit the drop is
  left untouched.
- `tests/test_police_weapon_drops.gd` covers pistol, shotgun, and AK-47 drops from
  real bullet kills, full-magazine acquisition, duplicate magazine collection, and
  the four-magazine limit.
