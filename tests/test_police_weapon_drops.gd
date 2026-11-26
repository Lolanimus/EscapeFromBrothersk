extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
const CAPACITIES := {&"pistol": 12, &"shotgun": 6, &"ak47": 31}
const PLACED_PICKUPS := {&"pistol": "Pistol", &"shotgun": "Shotgun", &"ak47": "AK47"}
const KILL_POSITION := Vector2(650, 350)

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_shot_policeman_drops_his_gun_outside_placed_supply()
	await _test_dropped_gun_is_acquired_with_one_full_magazine()
	await _test_duplicate_carried_gun_collects_only_its_magazine()
	await _test_duplicate_at_magazine_limit_leaves_the_drop_untouched()
	if _failures == 0:
		print("PASS: all police weapon drop tests passed")
	else:
		push_error("FAIL: %d police weapon drop test(s) failed" % _failures)
	quit(_failures)


func _test_shot_policeman_drops_his_gun_outside_placed_supply() -> void:
	for weapon_type in CAPACITIES:
		var level := await _start_level()
		var player := level.get_node("Player") as Player
		var enemy := _arm_policeman(level, weapon_type)
		await _acquire_placed(level, &"pistol")
		var placed_supply := level.get_node("Pickups").get_child_count()
		player.global_position = KILL_POSITION - Vector2(100, 0)
		await physics_frame
		await _aim_right(player)
		await _press("shoot")
		for frame in range(10):
			await physics_frame
		var drops := _police_drops()
		_expect(enemy.life_state == &"dead" and drops.size() == 1,
			"a policeman shot with his %s drops exactly one gun" % weapon_type)
		if drops.size() == 1:
			var drop := drops[0] as Node2D
			_expect(StringName(drop.get("weapon_type")) == weapon_type
				and drop.global_position.distance_to(enemy.global_position) < 1.0,
				"the dropped %s lies where its policeman died" % weapon_type)
		_expect(not drops.is_empty() and level.get_node("Pickups").get_child_count() == placed_supply
			and drops.all(func(drop: Node) -> bool: return not level.get_node("Pickups").is_ancestor_of(drop)),
			"the dropped %s is not added to the placed ammunition supply" % weapon_type)
		await _finish_level(level)


func _test_dropped_gun_is_acquired_with_one_full_magazine() -> void:
	for weapon_type in CAPACITIES:
		var level := await _start_level()
		var player := level.get_node("Player") as Player
		var enemy := _arm_policeman(level, weapon_type)
		enemy.kill_permanently()
		await process_frame
		player.global_position = KILL_POSITION
		await _press("interact")
		_expect(player.active_weapon == weapon_type and player.get_loaded_rounds() == CAPACITIES[weapon_type]
			and _police_drops().is_empty(),
			"E acquires the dropped %s loaded with one full %d-round magazine" % [weapon_type, CAPACITIES[weapon_type]])
		await _finish_level(level)


func _test_duplicate_carried_gun_collects_only_its_magazine() -> void:
	for weapon_type in CAPACITIES:
		var level := await _start_level()
		var player := level.get_node("Player") as Player
		var enemy := _arm_policeman(level, weapon_type)
		await _acquire_placed(level, weapon_type)
		player.set("%s_bullet" % weapon_type, 2)
		enemy.kill_permanently()
		await process_frame
		player.global_position = KILL_POSITION
		await _press("interact")
		var drops := _police_drops()
		_expect(player.active_weapon == weapon_type and player.get_loaded_rounds() == 2
			and player.get("%s_magazines" % weapon_type) == 1,
			"E on a dropped %s while carrying one keeps the loaded rounds and retains its full magazine" % weapon_type)
		_expect(drops.size() == 1 and int(drops[0].get("loaded_rounds")) == 0,
			"the duplicate %s stays on the floor without its magazine" % weapon_type)
		await _press("interact")
		_expect(player.get("%s_magazines" % weapon_type) == 1,
			"the emptied duplicate %s cannot be collected again" % weapon_type)
		await _finish_level(level)


func _test_duplicate_at_magazine_limit_leaves_the_drop_untouched() -> void:
	for weapon_type in CAPACITIES:
		var level := await _start_level()
		var player := level.get_node("Player") as Player
		var enemy := _arm_policeman(level, weapon_type)
		await _acquire_placed(level, weapon_type)
		player.set("%s_magazines" % weapon_type, 3)
		enemy.kill_permanently()
		await process_frame
		player.global_position = KILL_POSITION
		await _press("interact")
		var drops := _police_drops()
		_expect(player.active_weapon == weapon_type and player.get_loaded_rounds() == CAPACITIES[weapon_type]
			and player.get("%s_magazines" % weapon_type) == 3
			and drops.size() == 1 and int(drops[0].get("loaded_rounds")) != 0,
			"at four %s magazines the duplicate drop and its magazine stay on the floor" % weapon_type)
		await _finish_level(level)


func _start_level() -> Node:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	level.get_node("Player/Camera2D").enabled = false
	for policeman in get_nodes_in_group("police"):
		policeman.set_physics_process(false)
	return level


func _arm_policeman(level: Node, weapon_type: StringName) -> Enemy:
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	enemy.gun.weapon_type = String(weapon_type)
	enemy.global_position = KILL_POSITION
	return enemy


func _acquire_placed(level: Node, weapon_type: StringName) -> void:
	var player := level.get_node("Player") as Player
	player.global_position = level.get_node("Pickups/" + PLACED_PICKUPS[weapon_type]).global_position
	await _press("interact")


func _police_drops() -> Array[Node]:
	var drops: Array[Node] = []
	for pickup in get_nodes_in_group("police_drops"):
		if pickup.is_in_group("weapon_pickups"):
			drops.append(pickup)
	return drops


func _aim_right(player: Player) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300, 0)
	motion.global_position = motion.position
	root.push_input(motion, true)
	await process_frame


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await process_frame


func _finish_level(level: Node) -> void:
	level.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
