# 20: Complete HUD, visual, and audio feedback

**Source story:** 20

**What to build:** As a player, I want clear HUD and audio feedback for my current action and state, so that I can understand weapons, ammunition, motivation, combat states, and objectives.

**Blocked by:** 19: Restore the complete level-start checkpoint.

**Status:** done

- [x] Placeholder visuals clearly show a blue player with facing and weapon direction, red police with facing, translucent vision cones, distinct unconscious and dead states, recovery warning, and visible weapon and magazine pickups.
- [x] The HUD displays a crosshair, motivation bar, active and carried weapons, loaded rounds, retained magazine counts, EMPTY state, choke progress, and Level Complete overlay when relevant.
- [x] Distinct audio cues cover pistol, shotgun, and AK-47 fire; empty use; reload; weapon and magazine pickup; thrown impact; punch; katana swing; knockout; choking; detection; player death; level completion; and door opening.
- [x] Scene-level feedback tests verify that every required cue is triggered by the corresponding observable gameplay event without judging final asset polish.
- [x] Existing main-menu, gameplay, movement, visibility, pursuit, and viewport behavior retains appropriate regression coverage.

## Implemented scope

- Jira: SCRUM-230.

All feedback is proven through the real gameplay scene `res://scenes/main.tscn`
driven by input in `tests/test_gameplay_feedback.gd` (only Enemy1 is kept of the
24-police roster so the rest cannot interfere).

- Visuals: most placeholder presentation already existed and is now covered. The
  player uses the story 21 sprite art, which supersedes the blue placeholder of the
  intent: the sprite turns toward the cursor and the held gun points at it. Police
  are red `PoliceVisual` polygons whose translucent vision cone is turned to their
  posted facing; knocked-down, recovering and dead police have distinct colours and
  a lying pose without a cone; `RecoveryWarning` shows in the final three seconds;
  weapon and magazine pickups are visible sprites.
- HUD: a drawn `Crosshair` in the player's HUD layer follows the mouse. The OS
  cursor is hidden while the gameplay scene runs and is restored (with the
  crosshair hidden) on the death screen, on the Level Complete overlay, and when
  the player leaves the tree (restart, next level, menu), so buttons stay usable.
  Headless runs cannot observe the OS cursor mode, so tests check the crosshair.
  The stats label now lists `Pistol/Shotgun/AK-47 magazines: n/4` for all three
  guns; the stale `MAX_MAG = 3` pistol limit and the duplicate pistol-only lines
  were removed in favour of `MAX_MAGAZINES_PER_WEAPON`. Motivation bar, active and
  carried weapons, `Loaded: x/y`, `EMPTY`, choke progress and the Level Complete
  overlay are asserted by the same suite.
- Audio: the repository has no audio assets, so `scripts/feedback_audio.gd`
  synthesises one short 16-bit `AudioStreamWAV` per cue the first time it is
  needed and caches it. Each cue layers seeded, low-pass-filtered noise (gun
  cracks, hits, swooshes, scrapes) with sine parts (body thumps, metal rings, a
  whistle, a completion chime) under fast exponential decays or swells, so the
  placeholders resemble real sounds and stay distinct (0.03-0.75 s). Samples are
  soft-limited at a modest master gain and played at -8 dB. The level adds one `FeedbackAudio` node;
  gameplay code calls `play_cue(context, cue, position)`, which finds the nearest
  ancestor's `FeedbackAudio`, plays the tone through `AudioStreamPlayer2D`
  (positional) or `AudioStreamPlayer` (interface cues), and emits
  `cue_played(cue, position)` for tests. The node keeps processing during Level
  Complete so the completion cue is not paused. It works with the dummy audio
  driver used headless.

| Cue | Gameplay event |
| --- | --- |
| `pistol_fire`, `shotgun_fire`, `ak47_fire` | any shot through `RangedWeapon.fire` (player and police) |
| `empty_click` | fresh left click with an empty active gun |
| `reload` | R loads a retained magazine |
| `weapon_pickup` | E acquires a gun or the katana |
| `magazine_pickup` | E collects a magazine pickup or a duplicate gun's magazine |
| `thrown_impact` | a thrown weapon lands on a wall, door or policeman |
| `punch` | a fist attack |
| `katana_swing` | a katana swing |
| `knockout` | a policeman is knocked down (punch or thrown gun) |
| `choking` | a choke takes hold of a downed policeman |
| `detection` | a policeman becomes alerted |
| `player_death` | motivation reaches zero |
| `level_complete` | the player leaves through the open exit |
| `door_open` | an automatic door opens |

- `tests/test_weapon_reload.gd` now expects the retained counts with the real
  four-magazine limit (`0/4`) for all three guns instead of the stale `0/3`.
