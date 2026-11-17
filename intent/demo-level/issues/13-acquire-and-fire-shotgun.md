# 13: Acquire and fire the shotgun

**Source story:** 13

**What to build:** As a player, I want to acquire and fire a shotgun, so that I can use a close-range spread weapon with distinct ammunition behavior.

**Blocked by:** 06: Pursue and shoot the detected player; 08: Reload from retained magazines.

**Status:** done

- [x] One shotgun magazine round fires a fixed spread of six fast projectiles for both player and police users through shared weapon behavior.
- [x] Player pellets kill police in one hit and obey wall and closed-door obstruction rules.
- [x] A connected police shotgun blast removes exactly 25 motivation once, regardless of how many pellets connect.
- [x] Police fire shotguns immediately on detection with a clear shot, then every 1.2 seconds and retain unlimited ammunition.
- [x] Shotgun projectile speed and player firing cadence are selected as configurable values and tested alongside six-blast magazine behavior.


## Implementation notes

- Jira: SCRUM-193.
- Shared ranged-weapon definitions emit six pellets at fixed offsets of -10, -6, -2, 2, 6, and 10 degrees. Both player and police shotgun projectile speed defaults to 1200 pixels/second; the player cadence defaults to 0.8 seconds, and police cadence defaults to 1.2 seconds. Player exports and police overrides permit tuning.
- The placed shotgun is in the guard office at (1000, 225), with one six-blast loaded magazine. Shotgun magazines and reload use the shared ammunition handling.
- Each police shotgun blast carries a shared hit token so it can remove motivation only once; later blasts carry independent tokens.
- Gameplay-scene coverage: `tests/test_shotgun.gd` drives acquisition, shooting, ammunition exhaustion, configured speed/cadence, one-hit kills, walls, closed/open doors, police cadence/unlimited ammunition, and per-blast motivation damage.
- `tests/test_fast_projectile_obstruction.gd` proves player and police pellets stop at a two-pixel obstacle at 4000 pixels/second; projectile movement checks the swept segment as well as ordinary overlap collisions.

Validation: relevant gameplay suites pass; rendered smoke checks verify held guns, the ammunition HUD, and ranged throw impact feedback. The unavailable `code-review` skill was replaced by a manual review against the specification and project conventions.
