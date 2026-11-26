extends SceneTree
## Level-supply tests for story 16 (SCRUM-209): the prison's police roster and
## the guaranteed placed-ammunition surplus, read from the real gameplay scene.

const GameplayScene := preload("res://scenes/main.tscn")

## Selected police distribution, documented in issue 16.
const POLICE_DISTRIBUTION := {&"pistol": 13, &"shotgun": 7, &"ak47": 4}
## A player projectile kills a policeman in one hit, and one shotgun magazine
## round is one six-pellet blast that kills too, so the minimum is one round
## per policeman for every ranged weapon type.
const MIN_ROUNDS_PER_POLICEMAN := 1
## Placed magazines must hold at least 20% more rounds than that minimum.
const SURPLUS_PERCENT := 20
## Police must not stand closer than one body width to each other.
const MIN_POLICE_SPACING := 48.0

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_prison_holds_the_selected_police_distribution()
	await _test_police_are_spread_across_the_rooms_outside_the_starting_cell()
	await _test_placed_magazines_guarantee_a_twenty_percent_surplus()
	await _test_police_drops_never_change_the_guaranteed_supply()
	if _failures == 0:
		print("PASS: all level supply tests passed")
	else:
		push_error("FAIL: %d level supply test(s) failed" % _failures)
	quit(_failures)


func _test_prison_holds_the_selected_police_distribution() -> void:
	var level := await _start_level()
	var police := _police(level)
	_expect(police.size() >= 21 and police.size() <= 30,
		"the prison holds 21-30 policemen (found %d)" % police.size())
	var counts := {}
	for policeman in police:
		var weapon_type := StringName(policeman.gun.weapon_type)
		counts[weapon_type] = int(counts.get(weapon_type, 0)) + 1
	_expect(counts == POLICE_DISTRIBUTION,
		"police carry the selected distribution %s (found %s)" % [POLICE_DISTRIBUTION, counts])
	_expect(level.has_node("Enemies/Enemy1"), "the original Enemy1 is still part of the roster")
	await _finish_level(level)


func _test_police_are_spread_across_the_rooms_outside_the_starting_cell() -> void:
	var level := await _start_level()
	var police := _police(level)
	var occupied := {}
	for policeman in police:
		var area_id: StringName = level.get_area_id_at(policeman.global_position)
		_expect(area_id != &"" and area_id != &"starting_cell",
			"%s stands inside a prison area outside the starting cell (%s at %s)"
			% [policeman.name, area_id, policeman.global_position])
		occupied[area_id] = true
		_expect(not _overlaps_wall(policeman), "%s does not overlap a wall or door" % policeman.name)
	for area_id: StringName in level.AREA_RECTS:
		if area_id != &"starting_cell":
			_expect(occupied.has(area_id), "the %s is guarded by at least one policeman" % area_id)
	var crowded := false
	for first in range(police.size()):
		for second in range(first + 1, police.size()):
			if police[first].global_position.distance_to(police[second].global_position) < MIN_POLICE_SPACING:
				crowded = true
				push_error("%s and %s overlap" % [police[first].name, police[second].name])
	_expect(not crowded, "no two policemen stand on top of each other")

	for policeman in police:
		policeman.set_physics_process(true)
	for frame in range(10):
		await physics_frame
	_expect(police.all(func(policeman: Enemy) -> bool: return not policeman.is_alerted),
		"no policeman can see the player in the starting cell")
	await _finish_level(level)


func _test_placed_magazines_guarantee_a_twenty_percent_surplus() -> void:
	var level := await _start_level()
	var police_count := _police(level).size()
	var placed_weapons := _placed_weapon_types(level)
	_expect(placed_weapons == [&"ak47", &"pistol", &"shotgun"],
		"the pistol, shotgun and AK-47 are deliberately placed (found %s)" % [placed_weapons])
	var magazines := _placed_magazines(level)
	var player_start: Vector2 = level.get_node("Player").global_position
	for magazine in magazines:
		var area_id: StringName = level.get_area_id_at(magazine.global_position)
		_expect(level.get_room_ids().has(area_id), "placed %s magazine at %s lies on a room floor (%s)"
			% [magazine.weapon_type, magazine.global_position, area_id])
		_expect(not _overlaps_wall(magazine), "placed %s magazine at %s does not overlap a wall or door"
			% [magazine.weapon_type, magazine.global_position])
		var path: PackedVector2Array = level.get_navigation_path(player_start, magazine.global_position)
		_expect(path.size() >= 2 and path[0].is_equal_approx(player_start)
			and path[path.size() - 1].is_equal_approx(magazine.global_position),
			"placed %s magazine at %s is reachable from the player start"
			% [magazine.weapon_type, magazine.global_position])
	for weapon_type: StringName in placed_weapons:
		var minimum_rounds := police_count * MIN_ROUNDS_PER_POLICEMAN
		# Ceiling of minimum * 1.2 in whole rounds, then in whole magazines.
		var required_rounds := ceili(minimum_rounds * (100 + SURPLUS_PERCENT) / 100.0)
		var capacity := 0
		var placed_rounds := 0
		var placed_count := 0
		for magazine in magazines:
			if StringName(magazine.weapon_type) == weapon_type:
				capacity = magazine.get_magazine_capacity()
				placed_rounds += capacity
				placed_count += 1
		var required_magazines := ceili(float(required_rounds) / capacity) if capacity > 0 else 1
		print("SUPPLY: %s police=%d minimum=%d required(+%d%%)=%d capacity=%d required_magazines=%d placed_magazines=%d placed_rounds=%d"
			% [weapon_type, police_count, minimum_rounds, SURPLUS_PERCENT, required_rounds, capacity,
			required_magazines, placed_count, placed_rounds])
		_expect(capacity > 0 and placed_count >= required_magazines and placed_rounds >= required_rounds,
			"placed %s magazines (%d x %d = %d rounds) cover %d police plus %d%% (%d rounds, %d magazines)"
			% [weapon_type, placed_count, capacity, placed_rounds, police_count, SURPLUS_PERCENT,
			required_rounds, required_magazines])
	await _finish_level(level)


func _test_police_drops_never_change_the_guaranteed_supply() -> void:
	var level := await _start_level()
	var weapons_before := _placed_weapon_types(level)
	var magazines_before := _placed_magazines(level).size()
	for policeman in _police(level):
		policeman.kill_permanently()
	await process_frame
	await process_frame
	var drops := get_nodes_in_group("police_drops")
	_expect(drops.size() == _police(level).size(), "every killed policeman dropped his gun")
	_expect(_placed_weapon_types(level) == weapons_before and _placed_magazines(level).size() == magazines_before,
		"police drops are excluded from the placed weapons and magazines")
	await _finish_level(level)


func _police(level: Node) -> Array[Enemy]:
	var police: Array[Enemy] = []
	for policeman in get_nodes_in_group("police"):
		if level.is_ancestor_of(policeman):
			police.append(policeman as Enemy)
	return police


func _is_police_drop(node: Node) -> bool:
	while node != null:
		if node.is_in_group("police_drops"):
			return true
		node = node.get_parent()
	return false


## Distinct weapon types lying under the level's placed Pickups, sorted.
func _placed_weapon_types(level: Node) -> Array[StringName]:
	var types: Array[StringName] = []
	for pickup in level.get_node("Pickups").get_children():
		if pickup.is_in_group("weapon_pickups") and not _is_police_drop(pickup):
			var weapon_type := StringName(pickup.get("weapon_type"))
			if not types.has(weapon_type):
				types.append(weapon_type)
	types.sort_custom(func(first: StringName, second: StringName) -> bool: return String(first) < String(second))
	return types


func _placed_magazines(level: Node) -> Array[MagazinePickup]:
	var magazines: Array[MagazinePickup] = []
	for candidate in get_nodes_in_group("magazine_pickups"):
		if level.is_ancestor_of(candidate) and not _is_police_drop(candidate):
			magazines.append(candidate as MagazinePickup)
	return magazines


## True when the body's collision shape touches a wall (layer 1) or door (layer 8).
func _overlaps_wall(body: CollisionObject2D) -> bool:
	var collision := body.get_node("CollisionShape2D") as CollisionShape2D
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.collision_mask = 9
	query.collide_with_areas = false
	query.exclude = [body.get_rid()]
	return not body.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _start_level() -> Node:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	await physics_frame
	await physics_frame
	level.get_node("Player/Camera2D").enabled = false
	for policeman in get_nodes_in_group("police"):
		policeman.set_physics_process(false)
	return level


func _finish_level(level: Node) -> void:
	level.queue_free()
	for drop in get_nodes_in_group("police_drops"):
		drop.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		_failures += 1
		push_error("FAIL: " + message)
