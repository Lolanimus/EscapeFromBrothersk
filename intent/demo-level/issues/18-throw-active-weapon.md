# 18: Throw the active weapon

**Source story:** 18

**What to build:** As a player, I want to throw my active weapon, so that guns can knock down a policeman and a katana can kill one at range.

**Blocked by:** 10: Punch and recover knocked-down police; 17: Kill grouped police with the katana.

**Status:** in-progress

- [x] Right click throws the active carried weapon toward the mouse and removes it from the active carried slot.
- [x] A thrown ranged weapon hits only the first policeman, knocks him down, and remains on the floor with its remaining loaded ammunition.
- [ ] A thrown katana kills only the first policeman it hits and remains recoverable according to the standard pickup behavior.
- [x] Thrown weapons obey environmental obstruction and produce observable impact feedback.
- [ ] Thrown-weapon speed is selected as a configurable value and tested for ranged and katana outcomes.

## Implemented scope

- Jira: SCRUM-219.

The user requested ranged-weapon throwing without stories 09 or 17 for now.
The completed criteria above apply to pistol, shotgun, and AK-47. Throwing clears
the current single active weapon to fists; carried melee/ranged slots remain
outside this implementation. Katana throwing and its speed test remain deferred,
so this story is not done.

- `Player.thrown_weapon_speed` defaults to 800 pixels per second and is configurable.
- A swept collision query stops flight at the first policeman, wall, or closed door.
- The landed gun displays `IMPACT` briefly and can be recovered with E.
- Recovery preserves exact loaded rounds, including an empty magazine, and does
  not grant a fresh magazine. Retained magazines stay with the player.
- `tests/test_weapon_throw.gd` covers right-click input, first-hit knockdown,
  partial/empty loaded ammunition, all three ranged types, configurable flight
  speed, walls, closed doors, visible impact, and recovery.

