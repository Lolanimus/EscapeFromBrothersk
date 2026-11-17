# 14: Acquire and fire the AK-47

**Source story:** 14

**Jira:** SCRUM-199

**What to build:** As a player, I want to acquire and fire an AK-47, so that I can use an automatic ranged weapon with its own magazine type.

**Blocked by:** 06: Pursue and shoot the detected player; 08: Reload from retained magazines.

**Status:** done

- [x] Holding the attack input fires the AK-47 automatically for the player, using the shared ranged-weapon behavior and 31-round magazines.
- [x] AK-47-equipped police fire automatically with unlimited ammunition while following the established detection, pursuit, aiming, and obstruction rules.
- [x] Player projectiles kill police in one hit, while police projectiles do not damage or stop on other police.
- [x] AK-47 projectile speed and player and police firing cadences are selected as configurable values and covered by observable gameplay tests.

## Implementation notes

- The storage room provides the AK-47 at `(1400, 225)`; E equips it as the single active weapon. Stories 09 and 17 remain outside this implementation.
- Player and police use the shared ranged-weapon shot definition. AK-47 projectile speed defaults to 1200 pixels/second; both firing cadences default to 0.1 seconds. Player exports and police gun exports allow overrides.
- Holding left click repeats fire until release or the 31-round magazine is empty. R destroys the loaded magazine and consumes a compatible retained full magazine. The HUD displays loaded rounds and EMPTY; a visible held gun follows the aim direction.
- New full gun pickups remain on the floor if their loaded magazine would exceed the four-magazine limit. Empty thrown guns preserve zero rounds when recovered.
- Gameplay coverage: `tests/test_ak47.gd`; pistol and player-animation suites provide regression coverage. Full story completion also depends on integration verification of story 06.


Validation: relevant gameplay suites pass; rendered smoke checks verify held guns, the ammunition HUD, and ranged throw impact feedback. The unavailable `code-review` skill was replaced by a manual review against the specification and project conventions.
