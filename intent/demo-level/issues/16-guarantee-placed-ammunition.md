# 16: Guarantee a placed-ammunition surplus

**Source story:** 16

**What to build:** As a player, I want placed magazines to provide a guaranteed ammunition surplus, so that completing the mandatory elimination objective does not depend on police drops.

**Blocked by:** 01: Navigate the prison and alternate passage; 07: Collect and retain weapon-specific magazines; 13: Acquire and fire the shotgun; 14: Acquire and fire the AK-47.

**Status:** done

- [x] The prison contains 21–30 policemen with a selected and documented distribution of pistol, shotgun, and AK-47 users.
- [x] Deliberately placed ranged weapons and their compatible magazine types and locations are selected and documented.
- [x] For every deliberately placed ranged weapon type, placed full magazines contain at least 20% more rounds than the minimum required to kill every policeman, rounded up to whole magazines.
- [x] The guaranteed-supply calculation excludes police drops and is enforced by an automated level-supply test.

## Implemented scope

- Jira: SCRUM-209.
- Police roster: 24 policemen, 13 pistol, 7 shotgun, and 4 AK-47. `Enemies/Enemy1`
  (pistol, cell block at 673,490) is placed in `scenes/main.tscn`; the other 23 are
  copies of it posted by `PrisonLevel._post_police()` from the documented
  `PrisonLevel.POLICE_POSTS` table (name, position, weapon, vision facing).
  The starting cell stays empty. No policeman stands inside a door trigger, so
  every door is closed at the start of each attempt.

  | Area | Pistol | Shotgun | AK-47 |
  | --- | --- | --- | --- |
  | Cell block | 3 (incl. Enemy1) | 1 | 0 |
  | Guard office | 2 | 0 | 1 |
  | Storage | 1 | 1 | 1 |
  | Central corridor | 2 | 1 | 0 |
  | Exercise yard | 3 | 2 | 1 |
  | Exit | 1 | 1 | 1 |
  | Alternate passage | 1 | 1 | 0 |
  | **Total** | **13** | **7** | **4** |

- Placed ranged weapons (under the level's `Pickups`): pistol at (290,225) in the
  starting cell, shotgun at (1000,225) in the guard office, and AK-47 at
  (1400,225) in storage.
- Placed full magazines, all on room floors and reachable from the player start:

  | Type | Locations |
  | --- | --- |
  | Pistol (12) | cell block (759,219), guard office (1150,160), exercise yard (1250,820) |
  | Shotgun (6) | cell block (388,391), guard office (1080,330), storage (1330,180), central corridor (1200,520), exercise yard (1100,900) |
  | AK-47 (31) | central corridor (969,521) |

- Supply calculation: a player projectile, and a single shotgun blast, kills a
  policeman in one hit, so the minimum for every placed weapon type is one round
  per policeman: 24 rounds. Plus 20% gives ceil(28.8) = 29 rounds, then rounded up
  to whole magazines:

  | Type | Required | Magazines required | Placed |
  | --- | --- | --- | --- |
  | Pistol | 29 | ceil(29 / 12) = 3 | 3 (36 rounds) |
  | Shotgun | 29 | ceil(29 / 6) = 5 | 5 (30 blasts) |
  | AK-47 | 29 | ceil(29 / 31) = 1 | 1 (31 bullets) |

- `tests/test_level_supply.gd` reads the real gameplay scene: it counts the
  policemen and their equipped weapon types, checks that they stand in prison
  areas outside the starting cell without overlapping walls or each other and
  cannot see the player at the start, finds the placed weapon types under
  `Pickups`, and sums the capacities of the placed `MagazinePickup` nodes. It
  checks each magazine lies on a room floor, clear of walls and doors, with a
  navigation path from the player start. Nodes in the `police_drops` group are
  excluded, and killing every policeman is shown not to change the placed supply.
- Existing level suites that exercise a single policeman remove the posted
  roster after the level loads, restoring the one-policeman level they were
  written against. The objective and restart suites keep the full roster:
  `tests/test_level_completion.gd` kills every other policeman before proving the
  last one still locks the exit, and `tests/test_checkpoint_restart.gd` kills the
  whole roster during the attempt and checks every policeman is restored.
