# 21: Animate the player and pistol with existing sprites

**Source story:** 21

**What to build:** As a player, I want movement, fist attacks, pistol attacks, pickups, and projectiles to use the artwork already available in the game, so that my actions have clear animated visual feedback without introducing unsupported or newly generated art.

**Blocked by:** 03: Acquire and fire the pistol; 10: Punch and recover knocked-down police.

**Status:** ready-for-agent

- [x] The static player visual is replaced by state-driven sprite animation without changing movement, collision, aiming, or combat behavior.
- [x] Horizontal movement cycles through the three existing side-facing walking frames and mirrors them for the opposite direction.
- [x] Upward movement cycles through the three existing rear-facing walking frames.
- [x] Downward movement animates the existing front-facing player sprite with a subtle walking bob because no dedicated downward walking sequence currently exists.
- [ ] Fist attacks play the existing three-frame side-facing or rear-facing attack sequence according to the player's facing, mirroring the side-facing sequence when appropriate.
- [x] Pistol fire plays the existing two-frame side-facing or rear-facing firing sequence according to the player's facing, mirroring the side-facing sequence when appropriate.
- [ ] Each attack animation plays once for the corresponding gameplay attack and then returns to the correct idle or walking presentation without changing attack timing.
- [x] The pistol pickup and fired projectile use the existing pistol and bullet artwork instead of placeholder polygons.
- [x] Sprite scale, alignment, filtering, and animation speed are consistent during gameplay.
- [x] No new or generated artwork is introduced; unsupported views use the closest existing static or mirrored presentation.
- [ ] Scene-level tests verify animation-state selection and confirm that existing movement, fist, and pistol behavior remains functional.
