# 06: Pursue and shoot the detected player

**Source story:** 6

**What to build:** As a player, I want an alerted policeman to track, pursue, and shoot at me until one of us dies, so that detection creates a persistent threat.

**Blocked by:** 03: Acquire and fire the pistol; 05: Show police vision and detection.

**Status:** ready-for-agent

- [ ] After detection, a policeman remains alerted until either the player or that policeman dies and always tracks the player's current position, including through walls.
- [ ] An alerted policeman pathfinds through the prison, stops when a clear shot exists, continuously aims, waits 0.5 seconds after detection, and then fires according to the equipped weapon's cadence.
- [ ] Police use shared weapon behavior with unlimited ammunition; their projectiles pass through and do not damage other policemen.
- [ ] Gunfire turns nearby unalerted police toward the sound through walls without alerting them by sound alone.
- [ ] The gunfire hearing radius is selected, documented, configurable, and covered with pursuit, line-of-sight, and hearing tests.

