# 18: Throw the active weapon

**Source story:** 18

**What to build:** As a player, I want to throw my active weapon, so that guns can knock down a policeman and a katana can kill one at range.

**Blocked by:** 10: Punch and recover knocked-down police; 17: Kill grouped police with the katana.

**Status:** done

- [x] Right click throws the active carried weapon toward the mouse and removes it from the active carried slot.
- [x] A thrown ranged weapon hits only the first policeman, knocks him down, and remains on the floor with its remaining loaded ammunition.
- [x] A thrown katana kills only the first policeman it hits and remains recoverable according to the standard pickup behavior.
- [x] Thrown weapons obey environmental obstruction and produce observable impact feedback.
- [x] Thrown-weapon speed is selected as a configurable value and tested for ranged and katana outcomes.

## Implemented scope

- Jira: SCRUM-219.

Throwing covers every carried weapon: pistol, shotgun, AK-47, and katana. Right
click throws the active weapon toward the mouse and empties its slot of the
story 09 loadout; fists cannot be thrown.

- Throwing the carried gun empties the ranged slot and falls back to the melee
  side (the katana when carried, otherwise fists).
- Throwing the katana empties the melee slot, so fists become active; a carried
  gun stays carried with its loaded rounds and Q or 2 still reach it.
- `Player.thrown_weapon_speed` defaults to 800 pixels per second, is configurable,
  and applies to guns and the katana alike.
- A swept collision query stops flight at the first policeman, wall, or closed door.
- A thrown gun knocks the first policeman down. A thrown katana permanently kills
  him through the standard permanent-kill path (+10 motivation, police weapon drop).
  Police behind the first one are untouched.
- The landed weapon displays `IMPACT` briefly and rejoins the floor pickups; a
  katana stopped by a wall or door kills nobody. E recovers a gun with its exact
  loaded rounds (retained magazines stay with the player) and puts the katana back
  in the melee slot.
- Checkpoint restart removes thrown guns and a thrown katana and restores the
  placed katana.
- `tests/test_weapon_throw.gd` covers right-click input, first-hit knockdown and
  kill, partial/empty loaded ammunition, all three ranged types and the katana at
  configured flight speeds, walls, closed doors, visible impact, and recovery.
  `tests/test_weapon_loadout.gd` covers the loadout after each throw, and
  `tests/test_checkpoint_restart.gd` covers restart after throwing both weapons.
