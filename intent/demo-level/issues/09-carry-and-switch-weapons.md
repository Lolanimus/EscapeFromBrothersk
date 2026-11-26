# 09: Carry and switch the limited loadout

**Source story:** 9

**What to build:** As a player, I want to carry one ranged weapon and one katana and switch between them, so that I can change combat style without carrying an unrestricted arsenal.

**Blocked by:** 08: Reload from retained magazines.

**Status:** done

- [x] The player can carry at most one ranged weapon and one katana, with fists always available as the fallback.
- [x] E picks up or swaps the nearest weapon and Q switches between the carried ranged and melee weapons.
- [x] The active weapon alone responds to attack and throw input.
- [x] The fate of a replaced ranged weapon and its loaded magazine is selected, documented, and tested without violating ammunition limits.

## Implemented scope

- Jira: SCRUM-173.
- The player has one ranged slot (`carried_ranged_weapon`) and one melee slot
  (`carried_melee_weapon`); an empty melee slot means fists, which are always available.
  `active_weapon` is whichever side of the loadout is in use.
- E acquires the nearest weapon: a gun fills the ranged slot, a katana fills the melee
  slot without touching the carried gun. A second katana is ignored because the demo has
  only one. A duplicate of the carried gun still yields only its full magazine, even
  while fists or the katana are active.
- Q (`switch_weapon`) toggles between the carried gun and the melee side (katana, or
  fists when no katana is carried). Q does nothing without a carried gun.
- Only the active weapon reacts to left and right click. Throwing the active gun empties
  the ranged slot and falls back to the melee side (katana if carried, else fists).
- Selected swap rule: the replaced gun is dropped at the player's position as a weapon
  pickup with exactly its loaded rounds, and retained magazines stay with the player.
  A swap that would exceed four magazines of the incoming type is refused and the
  carried gun is kept. The loaded magazine of an inactive carried gun still counts
  toward its four-magazine limit. Recorded in `spec.md` and `intent.md`.
- `tests/test_weapon_loadout.gd` covers Q switching with the physical Q key, active-only
  attack and throw, duplicate magazine collection while the gun is inactive, the swap
  rule round trip, the refused swap at the magazine limit, the inactive gun's loaded
  magazine limit, and the melee slot using a bare katana pickup.
- Left for story 17: the katana's art, level placement, swing attack, and the katana
  side of Q/left click doing damage. Left for story 18: throwing the katana. With the
  katana active, left and right click currently do nothing.
