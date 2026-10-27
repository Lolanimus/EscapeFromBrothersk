# 05: Show police vision and detection

**Source story:** 5

**What to build:** As a player, I want visible police vision cones and clear detection feedback, so that I understand when an unalerted policeman can see me.

**Blocked by:** 01: Navigate the prison and alternate passage; 04: Operate automatic doors.

**Status:** ready-for-agent

- [ ] Every unalerted policeman has an always-visible, forward-facing yellow vision cone with a 90-degree shared default angle and per-policeman configurable angle and range.
- [ ] Detection occurs only while the player is inside the cone with unobstructed line of sight.
- [ ] Walls and closed doors block detection, while open doors do not.
- [ ] Detection changes the cone to red and exposes clear observable feedback.
- [ ] The default range representing approximately one large room is selected, documented, configurable, and tested.

