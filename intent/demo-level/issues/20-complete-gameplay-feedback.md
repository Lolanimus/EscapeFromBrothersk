# 20: Complete HUD, visual, and audio feedback

**Source story:** 20

**What to build:** As a player, I want clear HUD and audio feedback for my current action and state, so that I can understand weapons, ammunition, motivation, combat states, and objectives.

**Blocked by:** 19: Restore the complete level-start checkpoint.

**Status:** ready-for-agent

- [ ] Placeholder visuals clearly show a blue player with facing and weapon direction, red police with facing, translucent vision cones, distinct unconscious and dead states, recovery warning, and visible weapon and magazine pickups.
- [ ] The HUD displays a crosshair, motivation bar, active and carried weapons, loaded rounds, retained magazine counts, EMPTY state, choke progress, and Level Complete overlay when relevant.
- [ ] Distinct audio cues cover pistol, shotgun, and AK-47 fire; empty use; reload; weapon and magazine pickup; thrown impact; punch; katana swing; knockout; choking; detection; player death; level completion; and door opening.
- [ ] Scene-level feedback tests verify that every required cue is triggered by the corresponding observable gameplay event without judging final asset polish.
- [ ] Existing main-menu, gameplay, movement, visibility, pursuit, and viewport behavior retains appropriate regression coverage.

