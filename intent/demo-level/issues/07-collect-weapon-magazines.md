# 07: Collect and retain weapon-specific magazines

**Source story:** 7

**What to build:** As a player, I want to collect and retain full weapon-specific magazines, so that ammunition found for unequipped guns remains useful later.

**Blocked by:** 03: Acquire and fire the pistol.

**Status:** done

- [x] Pistol, shotgun, and AK-47 magazines are incompatible and always collected full, with capacities of 12 bullets, 6 blasts, and 31 bullets respectively.
- [x] The player retains magazines for weapons that are not currently carried.
- [x] The player can hold at most four magazines of each type, including a magazine loaded in a carried gun.
- [x] The behavior when collecting at the four-magazine limit is selected, documented, and tested.
  - Selected behavior: reject an extra pickup without consuming or deleting it. The player can collect it later after freeing capacity.
- [x] Magazine pickups are visibly identifiable and expose observable pickup feedback.

