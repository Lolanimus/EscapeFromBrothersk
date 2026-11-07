# 12: Unlock and leave the cleared prison

**Source story:** 12

**What to build:** As a player, I want the exit to unlock after every policeman is permanently dead and then continue to a configured next level, so that completing the required objective produces an explicit level transition.

**Blocked by:** 03: Acquire and fire the pistol; 10: Punch and recover knocked-down police; 11: Choke a knocked-down policeman.

**Status:** ready-for-agent

- [ ] The exit remains locked while any policeman is living or knocked down and unlocks only after every policeman is permanently dead.
- [ ] Reaching the unlocked exit displays a Level Complete state and prevents normal gameplay from continuing unnoticed.
- [ ] Further input during Level Complete loads the configured next-level scene.
- [ ] The next-level scene is selected and documented, and objective behavior is tested for living, knocked-down, and permanently dead police.

## Implementation and verification

- Jira: SCRUM-188. Implemented in `scripts/prison_level.gd` with scene-level coverage in `tests/test_level_completion.gd`.
- The exterior opening on the east wall is physically gated while any police in this level remain living, unconscious, or recovering. The visible exit sign changes from EXIT LOCKED to EXIT OPEN after all permanent deaths.
- Crossing the open east-wall threshold displays LEVEL COMPLETE and disables gameplay processing, including characters, weapons, projectiles, and pickups.
- A fresh keyboard or mouse-button press continues. Mouse motion, releases, and key echoes do not dismiss the overlay. Scene changes are deferred and protected against duplicate input.
- Default destination: `res://scenes/next_level.tscn`, a static next-level placeholder. Override the exported `next_level_scene` PackedScene on the prison level to configure another destination. No additional progression system is introduced.
- Headless scene tests cover living and unconscious police, multiple police, the physical gate, normal movement through the opened exit, completion freeze, keyboard continuation, mouse-motion filtering, and a mouse-click transition to an alternative configured scene.
- Automated checks pass; visual/manual playtesting remains pending, so the story is not marked done yet. No commit, push, or merge was performed.

