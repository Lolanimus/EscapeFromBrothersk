# 17: Kill grouped police with the katana

**Source story:** 17

**What to build:** As a player, I want the katana swing to kill every policeman in its unobstructed rectangular hit area, so that the melee weapon can handle grouped enemies.

**Blocked by:** 02: Apply the motivation combat loop; 09: Carry and switch the limited loadout.

**Status:** done

- [x] The katana can be acquired at a selected and documented prison location and used as the active melee weapon.
- [x] Left click performs a short forward-facing swing that permanently kills every exposed policeman within the slash effect's rectangular footprint.
- [x] Walls prevent the katana swing from affecting police behind them.
- [x] The slash effect defines the hit rectangle. Swing cadence is configurable. Gameplay tests cover rectangle boundaries, grouped kills, obstruction, and motivation restoration.

## Implemented scope

- Jira: SCRUM-214.
- Implemented by Roy (commit a6d0aa8, branch `SCRUM-214-katana-aoe`) and merged onto the
  story 09/15/16/19/21 main afterwards.
- Placement: `Pickups/Katana` in `scenes/main.tscn`, in the starting cell at (225, 267),
  42 pixels below the player spawn and within E range. It uses `assets/sprites/weapon/Katana.png`
  and is a real placed pickup, so the checkpoint restart restores it.
- Swing: left click with the katana active plays a directional slash pose
  (`katana_right/left/up/down`) with a matching slash VFX. Every living policeman in front
  of the player whose center lies inside the visible sweep of that VFX (a rectangle measured
  from the effect's non-transparent pixels) dies permanently, unless a wall (layer 1) or a
  closed automatic door (layer 8) lies between him and the player. Each kill restores
  10 motivation, capped at 100. `katana_swing_cadence` (default 0.45 s) is exported on the
  player.
- Integration decisions: story 09's loadout is the single source of truth. The katana fills
  `carried_melee_weapon` without displacing the carried gun, Q (`switch_weapon`) toggles
  between the carried gun and the katana, and the story 09 swap rule is unchanged. Roy's
  own slot/switching/dropping state was dropped; his 1 (`equip_melee`) and 2
  (`equip_ranged`) keys stay as direct shortcuts to the melee side and the carried gun.
  His extra `Enemies/Enemy2` scene policeman was dropped because story 16 fixes the roster
  at 24; the grouped-kill test places its second policeman itself.
- Tests: `tests/test_katana.gd` (acquisition at the spawn, 1/2 shortcuts, grouped kill,
  pose and VFX, motivation restore and cap, wall and closed-door obstruction, rectangle
  edges, cooldown, katana kept through a gun swap, and the story 09 integration: katana
  joins the melee slot beside a carried gun, Q switches gun and katana, and only the active
  katana slashes). `tests/test_weapon_loadout.gd` uses the placed katana for the melee slot;
  `tests/test_level_supply.gd` and `tests/test_checkpoint_restart.gd` count it as a placed
  pickup.
- Left for story 18: throwing the katana.
