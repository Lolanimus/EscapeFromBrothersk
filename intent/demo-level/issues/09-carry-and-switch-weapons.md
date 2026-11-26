# 09: Carry and switch the limited loadout

**Source story:** 9

**What to build:** As a player, I want to carry one ranged weapon and one katana and switch between them, so that I can change combat style without carrying an unrestricted arsenal.

**Blocked by:** 08: Reload from retained magazines.

**Status:** ready-for-agent

- [x] The player can carry at most one ranged weapon and one katana, with fists always available as the fallback.
- [x] E picks up or swaps the nearest weapon. 1 selects the melee slot and 2 selects the ranged slot.
- [ ] The active weapon alone responds to attack and throw input.
- [x] The fate of a replaced ranged weapon and its loaded magazine is selected, documented, and tested without violating ammunition limits.

Picking up a replacement gun drops the previous gun at the pickup spot with its loaded rounds. Press E to pick it back up. Spare magazines stay with the player.

