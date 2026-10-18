# Intent: Demo level
Author: Artem Melnikov (Team Gengar); Status: draft.

## Problem

The project needs a basic gameplay demo that can be applied to concrete levels. Currently, the player and enemy can move and collide with the surroundings. The enemy has no sprite and follows the player as soon as the player is in sight.

## Proposed outcome

Create a Hotline Miami-like, top-down 2D prison level with 6–8 rooms and 21–30 policemen. The player starts unarmed in a cell, moves with WASD, aims with the mouse, and must permanently kill every policeman before the prison exit unlocks. Knocked-down policemen still count as alive. The level includes a cell block, central corridor, guard office, showers or storage area, exercise yard, exit, and one alternate side passage.

The player attacks with left click, throws the active weapon with right click, picks up or swaps the nearest weapon with E, switches between the carried melee and ranged weapons with Q, reloads with R, and restarts from the checkpoint with Backspace. The camera follows the player and shifts slightly toward the mouse cursor.

There are five weapon types: fists, pistol, shotgun, AK-47, and katana. Fists are always available. The player can carry one katana and one ranged weapon at the same time. Police use pistol, shotgun, or AK-47 and have unlimited ammunition.

The player retains magazines for all three ranged weapon types, including types for guns not currently carried. A pistol magazine contains 12 bullets, a shotgun magazine contains 6 shotgun blasts, and an AK-47 magazine contains 31 bullets. The player can hold at most four magazines of each type, including the magazine currently loaded in the gun. Every magazine is full when picked up. Reloading destroys the current magazine and all ammunition left inside it, then loads a full retained magazine. An empty magazine is destroyed.

For ranged weapons deliberately placed in the level, the map guarantees enough compatible full magazines to provide at least 20% more rounds than the minimum number required to kill every policeman. The total is rounded up to whole magazines. Police drops do not count toward this guaranteed supply.

Every policeman always drops his equipped gun with one full compatible magazine when killed. If the player already carries the same ranged weapon, interacting with the dropped weapon collects only its magazine, subject to the four-magazine limit. Player and police weapons share the same weapon behavior definitions except for ammunition handling.

The pistol fires one accurate, fast projectile. Each shotgun blast fires six fast projectiles in a fixed spread and consumes one shotgun magazine round. An entire shotgun blast removes motivation only once, regardless of how many pellets hit the player. Projectiles fired by the player kill policemen in one hit and stop at walls and closed doors, with no penetration, ricochets, headshots, or damage falloff. Police bullets pass through other policemen.

Police initially detect the player inside a visible, forward-facing vision cone when there is a clear line of sight. The cone uses a shared default of 90 degrees and a range of about one large room, while its range and angle remain configurable per policeman. Walls and closed doors block sight. The vision cone is yellow normally and red during detection.

Once a policeman sees the player, he remains alerted until either the player or policeman dies. An alerted policeman always knows the player's current location, including through walls, and continuously pathfinds toward the player even without line of sight. When he has a clear shot, he stops moving and fires. A policeman waits 0.5 seconds after first detection before firing, then fires a pistol every 0.6 seconds or a shotgun every 1.2 seconds. He aims continuously until each shot.

Gunfire makes every unalerted policeman within a configurable radius turn toward the shot. Walls do not block or reduce sound. Hearing alone does not alert the policeman unless turning places the player inside his vision cone with clear line of sight.

The player starts with 100 motivation, displayed as a motivation bar. Motivation is mechanically the player's health: lower motivation only means the player is closer to death and does not apply other penalties. Every police bullet hit removes 25 motivation, and a shotgun blast removes 25 motivation once. Permanently killing a policeman restores 10 motivation, capped at 100. The player dies when motivation reaches 0.

Fists knock down a policeman. A knocked-down policeman recovers after 15 seconds, with a visible warning during the final 3 seconds. The player can permanently kill him by shooting him or by holding left click to choke him for three uninterrupted seconds. The player cannot move while choking. Releasing the button, attempting to move, or taking damage cancels the choke and resets its progress.

The katana performs a short, forward-facing area swing that instantly kills every policeman inside the arc. Walls block the swing, while its exact reach and angle remain configurable. Throwing the katana kills the first policeman it hits. Throwing a ranged weapon hits only the first policeman, knocks him down, and leaves the weapon on the floor with its remaining ammunition. Dead and unconscious police look different. Characters do not block one another.

Automatic doors block sight while closed, open when approached by the player or a policeman, and remain open for the rest of the attempt.

Each level has exactly one checkpoint at its beginning. Reaching the start establishes a full snapshot of player position, motivation, carried weapons, retained magazines, police states, pickups, bodies, and doors. Player death or a manual restart restores that complete snapshot and respawns the player at the beginning in under one second.

Reaching the unlocked exit shows a Level Complete state and loads a configured next-level scene after input.

Use placeholder art: a blue player with clear facing and weapon direction; red police with clear facing direction; translucent vision cones; distinct knocked-down and dead states; a recovery indicator; visible weapon and magazine shapes; and nearby ammunition information. The HUD contains a crosshair, motivation bar, active and carried weapons, rounds in the loaded magazine, retained magazine counts, an EMPTY indicator, choke progress, and a Level Complete overlay. Audio includes distinct pistol, shotgun, and AK-47 shots, an empty-gun click, reload, weapon and magazine pickup, weapon impact, punch, katana swing, knockout, choking, enemy detection, player death, level completion, and door opening sounds.

## Affected users and systems

The player is affected by movement, aiming, mandatory combat, shooting, reloading, magazine collection and retention, two weapon slots, weapon swapping and throwing, melee attacks, knockdowns, choking, motivation, death, checkpoint restart, and level completion. Affected systems are player and enemy movement and collision, persistent enemy perception and pursuit, pathfinding, weapons and projectiles, magazines and ammunition, item interaction and drops, enemy states, automatic doors, camera, HUD, audio, checkpoint snapshots, level reset, and scene progression.

## Constraints

Use Godot 4.7 and GDScript. Use placeholder art rather than polished art. The demo is limited to fists, pistol, shotgun, AK-47, and katana. Police use only the three guns. Each level contains one checkpoint at its beginning. The demo excludes guard patrols, searching around last-known positions, cover behavior, keys, locked doors, secondary objectives, destructible scenery, procedural levels, additional weapons, additional checkpoints, additional menus, and progression systems beyond loading a configured next-level scene.

## Open questions

- What exact vision range should represent one large room?
- What is the gunfire hearing radius?
- What are the pistol, shotgun, AK-47, and thrown-weapon projectile speeds?
- What are the AK-47 firing cadence and the player's firing cadences for all ranged weapons?
- How are the three police gun types distributed among the 21–30 policemen?
- Which ranged weapons and compatible magazine types are deliberately placed in the level?
- What happens to a carried ranged weapon and its loaded magazine when the player swaps to a different ranged weapon?
- What happens when the player tries to collect a magazine type already at the four-magazine limit?
- What are the katana swing's exact reach, arc angle, and cadence?
- Where is the katana placed in the level?
- What scene should load after completing the demo level?
- What are the exact dimensions and geometry of the rooms and alternate passage?
