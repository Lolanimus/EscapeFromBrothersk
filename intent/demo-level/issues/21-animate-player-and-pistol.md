# 21: Animate the player and pistol with existing sprites

**Source story:** 21

**What to build:** As a player, I want movement, fist attacks, pistol attacks, pickups, and projectiles to use the artwork already available in the game, so that my actions have clear animated visual feedback without introducing unsupported or newly generated art.

**Blocked by:** 03: Acquire and fire the pistol; 10: Punch and recover knocked-down police.

**Status:** done

- [x] The static player visual is replaced by state-driven sprite animation without changing movement, collision, aiming, or combat behavior.
- [x] Horizontal movement cycles through the three existing side-facing walking frames and mirrors them for the opposite direction.
- [x] Upward movement cycles through the three existing rear-facing walking frames.
- [x] Downward movement animates the existing front-facing player sprite with a subtle walking bob because no dedicated downward walking sequence currently exists.
- [x] Fist attacks play the existing three-frame side-facing or rear-facing attack sequence according to the player's facing, mirroring the side-facing sequence when appropriate.
- [x] Pistol fire plays the existing two-frame side-facing or rear-facing firing sequence according to the player's facing, mirroring the side-facing sequence when appropriate.
- [x] Each attack animation plays once for the corresponding gameplay attack and then returns to the correct idle or walking presentation without changing attack timing.
- [x] The pistol pickup and fired projectile use the existing pistol and bullet artwork instead of placeholder polygons.
- [x] Sprite scale, alignment, filtering, and animation speed are consistent during gameplay.
- [x] No new or generated artwork is introduced; unsupported views use the closest existing static or mirrored presentation.
- [x] Scene-level tests verify animation-state selection and confirm that existing movement, fist, and pistol behavior remains functional.

**Implementation note:** Fist attacks use the existing `punch_side` sequence (`attack/1.png`, `attack/2.png`, `attack/3.png`, mirrored when aiming right) and `punch_up` sequence (`attack/backsideAttack/backpunch1.png`-`backpunch3.png`), both non-looping at 12 FPS. Pistol fire and punches share one one-shot attack path that faces the aim direction and returns to idle or walking presentation when the sequence finishes; the knockdown and pistol cadence are unchanged. Covered by `tests/test_player_fist_attack_animation.gd`, `tests/test_player_animation.gd`, `tests/test_player_rear_pistol_animation.gd`, plus the `test_pistol`, `test_punch_recovery`, and `test_choking` regressions.
