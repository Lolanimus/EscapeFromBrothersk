# Demo Level Specification

## Problem Statement

The project needs a reusable gameplay foundation for concrete levels. The current Godot project provides a basic gameplay scene, player movement, an enemy that follows a visible target within range, a main menu, and lightweight automated tests. It does not yet provide the complete prison level, mandatory elimination objective, weapon and magazine systems, melee combat, motivation, persistent enemy pursuit, checkpoint restoration, feedback, or level-completion flow described by the approved intent.

## Solution

Create a Hotline Miami-like, top-down 2D prison demo in Godot 4.7 using GDScript. The level contains 6–8 rooms and 21–30 policemen. The player starts unarmed, navigates the prison, acquires weapons and magazines, and must permanently kill every policeman before the exit unlocks.

The gameplay combines three ranged weapons, fists, a katana, limited player magazines, persistent police pursuit after detection, motivation-based survivability, temporary knockdowns, interruptible choking, a level-start checkpoint, automatic doors, and clear visual, HUD, and audio feedback. The resulting systems must be reusable when constructing later levels.

## User Stories

The following Fibonacci estimates are provisional. No story exceeds 8 points; implementation planning may revise estimates without changing the specified behavior. Stories are ordered by dependency first and importance within the same dependency level.

1. As a player, I want to navigate the prison's rooms and alternate passage, so that I can choose how to approach each encounter. **Estimate: 5 points.**
2. As a player, I want police attacks to reduce my motivation and permanent kills to restore it, so that survival and the elimination objective reinforce the same combat loop. **Estimate: 5 points.**
3. As a player, I want to acquire and fire a pistol, so that I have a precise baseline ranged weapon. **Estimate: 5 points.**
4. As a player, I want automatic doors to respond to both me and policemen, so that doors consistently shape movement, projectiles, and sight lines. **Estimate: 3 points.**
5. As a player, I want visible police vision cones and clear detection feedback, so that I understand when an unalerted policeman can see me. **Estimate: 5 points.**
6. As a player, I want an alerted policeman to track, pursue, and shoot at me until one of us dies, so that detection creates a persistent threat. **Estimate: 8 points.**
7. As a player, I want to collect and retain full weapon-specific magazines, so that ammunition found for unequipped guns remains useful later. **Estimate: 5 points.**
8. As a player, I want reloading to consume the current magazine and load a retained full magazine, so that deciding when to reload has a cost. **Estimate: 5 points.**
9. As a player, I want to carry one ranged weapon and one katana and switch between them, so that I can change combat style without carrying an unrestricted arsenal. **Estimate: 8 points.**
10. As an unarmed player, I want to punch policemen unconscious and see when they are recovering, so that fists create a temporary opening rather than an immediate kill. **Estimate: 5 points.**
11. As a player, I want to choke a knocked-down policeman through an interruptible hold action, so that I can permanently eliminate him without ammunition while accepting close-range risk. **Estimate: 5 points.**
12. As a player, I want the exit to unlock after every policeman is permanently dead and then continue to a configured next level, so that completing the required objective produces an explicit level transition. **Estimate: 5 points.**
13. As a player, I want to acquire and fire a shotgun, so that I can use a close-range spread weapon with distinct ammunition behavior. **Estimate: 5 points.**
14. As a player, I want to acquire and fire an AK-47, so that I can use an automatic ranged weapon with its own magazine type. **Estimate: 5 points.**
15. As a player, I want permanently killed policemen to drop their guns with full magazines, so that combat can replenish my limited ranged ammunition. **Estimate: 5 points.**
16. As a player, I want placed magazines to provide a guaranteed ammunition surplus, so that completing the mandatory elimination objective does not depend on police drops. **Estimate: 3 points.**
17. As a player, I want the katana swing to kill every policeman in its unobstructed arc, so that the melee weapon can handle grouped enemies. **Estimate: 5 points.**
18. As a player, I want to throw my active weapon, so that guns can knock down a policeman and a katana can kill one at range. **Estimate: 5 points.**
19. As a player, I want death or manual restart to restore the complete level-start checkpoint quickly, so that each retry begins from a consistent state. **Estimate: 8 points.**
20. As a player, I want clear HUD and audio feedback for my current action and state, so that I can understand weapons, ammunition, motivation, combat states, and objectives. **Estimate: 8 points.**

## Implementation Decisions

- The implementation uses Godot 4.7 and GDScript.
- The demo is a top-down 2D prison level with 6–8 rooms and 21–30 policemen.
- The level contains a starting cell, cell block, central corridor, guard office, showers or storage area, exercise yard, exit, and one alternate side passage.
- The player starts unarmed in the cell.
- Every policeman must be permanently dead before the exit unlocks. A knocked-down policeman remains alive and continues to block completion.
- Reaching the unlocked exit displays Level Complete. Further input loads a configured next-level scene.
- WASD controls movement and the mouse controls aim. Left click performs the active attack. Right click throws the active weapon. E picks up or swaps the nearest weapon. Q switches between the carried melee and ranged weapons. R reloads the active ranged weapon. Backspace manually restarts from the checkpoint.
- The camera follows the player and shifts slightly toward the mouse cursor.
- There are five weapon types: fists, pistol, shotgun, AK-47, and katana.
- Fists are always available. The player may carry one katana and one ranged weapon simultaneously. Q changes which carried weapon is active.
- Police use only pistol, shotgun, or AK-47. Police have unlimited ammunition.
- Player ammunition is represented by three incompatible magazine types: pistol, shotgun, and AK-47.
- A full pistol magazine contains 12 bullets, a full shotgun magazine contains 6 shotgun blasts, and a full AK-47 magazine contains 31 bullets.
- The player retains magazines for all three ranged weapon types, including ammunition for a gun not currently carried.
- The player may retain at most four magazines of each type. The magazine currently loaded in a carried gun counts toward this limit.
- Every collected magazine is full. There are no loose or partially filled magazine pickups.
- Reloading destroys the currently loaded magazine and any ammunition remaining inside it, then inserts a full retained magazine. A magazine is also destroyed when its ammunition reaches zero.
- For the ranged weapon types deliberately placed in the level, placed full magazines provide at least 20% more rounds than the minimum number of rounds required to kill every policeman. The supply is rounded up to whole magazines.
- Police weapon drops do not count toward the guaranteed placed-ammunition supply.
- Every policeman drops his equipped gun with one full compatible magazine when permanently killed.
- If the player already carries the same ranged weapon as the dropped gun, interacting with it collects only the full magazine, subject to the four-magazine limit.
- Player and police weapons share weapon behavior definitions except for ammunition handling.
- The pistol fires one accurate, fast projectile.
- One shotgun magazine round produces one blast of six fast projectiles in a fixed spread.
- Player projectiles kill policemen in one hit.
- Projectiles stop at walls and closed doors. They do not penetrate, ricochet, use headshots, or apply damage falloff.
- Police projectiles pass through other policemen and do not damage them.
- A shotgun blast causes at most one motivation-damage event to the player, regardless of how many pellets from that blast connect.
- Police begin unalerted. An unalerted policeman detects the player only when the player is inside his forward-facing vision cone with unobstructed line of sight.
- The default vision cone angle is 90 degrees. Cone angle and range are configurable per policeman. The default range remains described as approximately one large room until an exact value is selected.
- Walls and closed doors block line of sight. Open doors do not.
- Vision cones are always visible. A cone is yellow before detection and red while its policeman is alerted.
- Once a policeman sees the player, he remains alerted until either the player or that policeman dies.
- An alerted policeman always knows the player's current location, including through walls, and continuously pathfinds toward that location without requiring line of sight.
- When an alerted policeman has a clear shot, he stops moving and fires from his current position.
- A policeman waits 0.5 seconds after initial detection before his first shot. A pistol-armed policeman then fires every 0.6 seconds, and a shotgun-armed policeman fires every 1.2 seconds.
- A policeman continuously updates his aim until each shot fires.
- Gunfire makes every unalerted policeman inside a configurable hearing radius turn toward the shot. Walls do not block or reduce sound.
- Hearing alone does not alert a policeman. Turning toward the sound may lead to visual detection if the player enters the policeman's vision cone with clear line of sight.
- The player starts with 100 motivation. Motivation is the player's health value under a thematic name; lower motivation does not cause any additional presentation or mechanical penalties.
- Every police bullet hit removes 25 motivation. A connected shotgun blast removes 25 motivation once.
- Permanently killing a policeman restores 10 motivation, capped at 100.
- The player dies when motivation reaches zero.
- An unarmed left-click attack punches the targeted policeman and knocks him down rather than killing him.
- A knocked-down policeman remains unconscious for 15 seconds. A visible warning appears during the final 3 seconds before he recovers.
- A knocked-down policeman can be permanently killed by shooting or choking.
- Choking requires the player to hold left click beside the knocked-down policeman for three uninterrupted seconds. The player cannot move during the choke.
- Releasing left click, attempting to move, or taking damage cancels the choke and resets its progress.
- The katana makes a short, forward-facing area swing. Every policeman inside the swing arc dies instantly, and walls block the swing.
- Throwing the katana kills the first policeman it hits.
- Throwing a ranged weapon knocks down only the first policeman it hits, then leaves the weapon on the floor with its remaining loaded ammunition.
- Living, knocked-down, and dead police have distinct placeholder presentation.
- Characters do not collide with or block one another.
- Automatic doors open when approached by either the player or a policeman. A closed door blocks sight and projectiles. Once opened, a door stays open for the remainder of the attempt.
- Each level has exactly one checkpoint, located at the beginning.
- The checkpoint represents a full snapshot of player position, motivation, carried weapons, retained magazines, police states, pickups, bodies, and doors.
- Player death and manual restart both restore the full checkpoint snapshot and respawn the player at the beginning in under one second.
- Placeholder visuals use a blue player with clear facing and weapon direction, red police with clear facing, translucent vision cones, distinct unconscious and dead appearances, a recovery indicator, and visible weapon and magazine pickups.
- The HUD displays a crosshair, motivation bar, active and carried weapons, rounds remaining in the loaded magazine, retained magazine counts, an EMPTY indicator, choke progress, and the Level Complete overlay.
- Audio feedback covers pistol, shotgun, and AK-47 fire; empty-gun use; reloads; weapon and magazine pickup; thrown-weapon impact; punches; katana swings; knockouts; choking; enemy detection; player death; level completion; and door opening.
- The current repository's main menu, gameplay scene, player movement, enemy range and ray-based visibility, enemy pursuit, and lightweight script-based tests are the starting point for this change.

## Testing Decisions

- Tests verify externally observable gameplay behavior rather than internal implementation details. Refactoring scripts or scene structure must not require test changes when player-visible behavior remains the same.
- The primary test seam is the complete gameplay scene. Tests instantiate the scene and drive behavior through input actions, character placement, collisions, elapsed time, signals, and observable scene state.
- Existing SceneTree-based tests provide the prior art for the harness. Current tests demonstrate scene instantiation, frame advancement, simulated signals, spatial setup, physics obstacles, and process exit codes.
- Existing player movement, main-menu transition, enemy range, obstacle visibility, and viewport behavior remain regression coverage where those behaviors are still applicable.
- Level-objective tests verify that the exit stays locked while any policeman is alive, that knocked-down policemen count as alive, and that the exit unlocks only after every policeman is permanently dead.
- Navigation tests verify the level's rooms, alternate route, automatic doors, door persistence, and the effect of closed and open doors on sight and projectiles.
- Detection tests verify cone angle and range, line-of-sight obstruction, yellow and red cone states, the initial reaction delay, and the transition from unalerted to permanently alerted.
- Pursuit tests verify that an alerted policeman continues tracking the player's current position through lost sight and walls, pathfinds toward the player, and stops to fire when a clear shot is available.
- Hearing tests verify that a nearby unalerted policeman turns toward gunfire, that walls do not suppress the event, and that hearing alone does not create the alerted state.
- Ranged-combat tests verify pistol, shotgun, and AK-47 firing; player one-hit kills against police; shared weapon behavior; unlimited police ammunition; wall and door collisions; police friendly-fire immunity; and a single motivation-damage event per shotgun blast.
- Magazine tests verify incompatible magazine types, full-magazine pickups, the capacities of 12, 6, and 31, retention for unequipped weapons, the four-magazine limit including the loaded magazine, destructive reloads, empty-magazine destruction, and HUD counts.
- Level-supply tests verify that guaranteed placed magazines provide at least the required 20% ammunition surplus after rounding to whole magazines, without counting police drops.
- Loot tests verify that every permanently killed policeman drops his gun with one full compatible magazine and that interacting with a duplicate carried weapon collects its magazine when capacity permits.
- Loadout tests verify the one-melee and one-ranged limits, Q switching, replacement behavior once the unresolved swap rule is decided, and fallback to fists.
- Melee tests verify fist knockdown, 15-second recovery, the final 3-second warning, shooting a downed policeman, the uninterrupted three-second choke, choke cancellation, katana area kills, wall-blocked swings, and lethal katana throws.
- Motivation tests verify the 100-point maximum, 25-point damage events, 10-point restoration after permanent kills, the 100-point restoration cap, and death at zero.
- Checkpoint tests verify that death and Backspace restore every captured system to the level-start state and complete in under one second.
- Feedback tests verify that the HUD and placeholder states reflect active gameplay state and that each required audio cue is triggered. Tests do not judge final asset quality.
- Completion tests verify the Level Complete state and transition to the configured next-level scene after input once that scene is selected.
- Exact assertions for unresolved tuning values are added only after those values are decided.

## Out of Scope

- Guard patrol routes
- Searching around a last-known player position
- Police cover-selection behavior
- Police melee weapons
- Keys and locked doors
- Secondary objectives
- Destructible scenery
- Procedural level generation
- Weapons beyond fists, pistol, shotgun, AK-47, and katana
- More than one checkpoint per level
- Checkpoints outside the beginning of a level
- Additional menus
- Progression systems beyond loading a configured next-level scene
- Polished final art
- Projectile penetration, ricochets, headshots, and damage falloff
- Character-to-character collision and blocking
- Loose bullets and partially filled magazine pickups
- Mechanical or presentation penalties caused by low motivation beyond proximity to death

## Further Notes

- The exact default vision range that represents one large room remains undecided.
- The gunfire hearing radius remains undecided.
- Pistol, shotgun, AK-47, and thrown-weapon projectile speeds remain undecided.
- The AK-47 firing cadence and the player's firing cadences for all ranged weapons remain undecided.
- The distribution of pistol-, shotgun-, and AK-47-armed police among the 21–30 policemen remains undecided.
- The ranged weapons deliberately placed in the level and the distribution of their compatible guaranteed magazines remain undecided.
- The result of swapping a carried ranged weapon, including what happens to its loaded magazine, remains undecided.
- The result of attempting to collect a magazine when that magazine type is already at its four-magazine limit remains undecided.
- The katana swing's exact reach, arc angle, and cadence remain undecided.
- The katana's level placement remains undecided.
- The scene loaded after Level Complete remains undecided.
- Exact room dimensions, geometry, and alternate-passage layout remain undecided.
- The intent says the existing player collides with surroundings, while the current player implementation directly updates position and clamps it to the viewport. Environmental collision behavior must be verified before implementation relies on it.
- The existing enemy implementation uses a distance check and ray test, not the required forward-facing cone or permanent alerted pathfinding behavior.
- The current gameplay scene contains only a basic player and one enemy rather than the required prison layout and population.
- No project glossary or architectural decision record is present, so this specification uses terminology from the intent and existing scripts.
- This specification is stored locally alongside the intent rather than published to an issue tracker, as requested.
