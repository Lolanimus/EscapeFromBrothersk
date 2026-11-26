# 17: Kill grouped police with the katana

**Source story:** 17

**What to build:** As a player, I want the katana swing to kill every policeman in its unobstructed rectangular hit area, so that the melee weapon can handle grouped enemies.

**Blocked by:** 02: Apply the motivation combat loop; 09: Carry and switch the limited loadout.

**Status:** ready-for-agent

- [x] The katana can be acquired at a selected and documented prison location and used as the active melee weapon.
- [x] Left click performs a short forward-facing swing that permanently kills every exposed policeman within the slash effect's rectangular footprint.
- [x] Walls prevent the katana swing from affecting police behind them.
- [x] The slash effect defines the hit rectangle. Swing cadence is configurable. Gameplay tests cover rectangle boundaries, grouped kills, obstruction, and motivation restoration.

In the demo's starting cell, press E to pick up the katana at (225, 267), 42 pixels below the spawn. Press 1 to equip the katana or 2 to equip the carried gun.

The hit rectangle covers the visible sweep of the selected directional slash effect in front of the player. The default cooldown is 0.45 seconds. Each permanent kill restores 10 motivation up to 100. Walls and closed doors block individual targets.

Run `godot --headless --path . --script tests/test_katana.gd` for gameplay coverage.

