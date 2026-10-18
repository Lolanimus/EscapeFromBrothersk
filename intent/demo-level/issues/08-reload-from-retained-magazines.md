# 08: Reload from retained magazines

**Source story:** 8

**What to build:** As a player, I want reloading to consume the current magazine and load a retained full magazine, so that deciding when to reload has a cost.

**Blocked by:** 07: Collect and retain weapon-specific magazines.

**Status:** ready-for-agent

- [ ] Pressing R with a compatible retained magazine destroys the current magazine and all ammunition remaining inside it, then loads one full retained magazine.
- [ ] A magazine is destroyed when its ammunition reaches zero.
- [ ] Attempting to fire without ammunition produces an observable empty-gun state without firing a projectile.
- [ ] Loaded rounds, retained counts, destructive reloads, empty-magazine destruction, and the four-magazine limit are verified for each magazine type.

