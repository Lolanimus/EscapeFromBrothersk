# 06: Pursue and shoot the detected player

**Source story:** 6

**What to build:** As a player, I want an alerted policeman to track, pursue, and shoot at me until one of us dies, so that detection creates a persistent threat.

**Blocked by:** 03: Acquire and fire the pistol; 05: Show police vision and detection.

**Status:** done

- [x] After detection, a policeman remains alerted until either the player or that policeman dies and always tracks the player's current position, including through walls.
- [x] An alerted policeman pathfinds through the prison, continuously aims and moves while firing, shoots immediately on detection when a clear shot exists, and then fires according to the equipped weapon's cadence.
- [x] Police use shared weapon behavior with unlimited ammunition; their projectiles pass through and do not damage other policemen.
- [x] Gunfire turns nearby unalerted police toward the sound through walls without alerting them by sound alone.
- [x] The gunfire hearing radius is selected, documented, configurable, and covered with pursuit, line-of-sight, and hearing tests.


## Implementation notes

- Jira: SCRUM-157 (verified against the current Jira story title).
- Persistent pursuit and navigation reuse the existing implementation. Alerted police fire whenever line of sight is clear, independently of the vision cone, and keep their red alert presentation through lost sight.
- Player and police share ranged-weapon definitions. Default police cadence is 0.6 seconds for pistol, 1.2 for shotgun, and 0.1 for AK-47, with immediate initial fire and unlimited police ammunition.
- Each shot notifies living, unalerted police within their exported `gunfire_hearing_radius`, default 800 pixels. Walls do not suppress hearing; hearing turns the cone but only unobstructed visual detection alerts police.
- Scene-level evidence: `tests/test_police_combat.gd`, existing enemy navigation and combined-combat suites, and shotgun/AK-47 suites cover hearing, configurable radius, visual detection after turning, persistent pursuit, aiming, obstruction, cadence, and friendly-fire immunity.

Validation: relevant gameplay suites pass; rendered smoke checks verify held guns, the ammunition HUD, and ranged throw impact feedback. The unavailable `code-review` skill was replaced by a manual review against the specification and project conventions.
