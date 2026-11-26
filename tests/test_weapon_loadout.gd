extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_q_switches_between_carried_gun_and_fists()
	await _test_only_the_active_weapon_responds_to_attack_and_throw()
	await _test_carried_duplicate_collects_magazine_while_fists_are_active()
	await _test_swapping_guns_drops_the_replaced_gun_with_its_loaded_rounds()
	await _test_swap_is_refused_when_it_would_exceed_the_magazine_limit()
	await _test_inactive_carried_gun_still_counts_its_loaded_magazine()
	await _test_katana_fills_the_melee_slot_beside_the_gun()
	if _failures == 0:
		print("PASS: all weapon loadout tests passed")
	else:
		push_error("FAIL: %d weapon loadout test(s) failed" % _failures)
	quit(_failures)


func _test_q_switches_between_carried_gun_and_fists() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	level.get_node("Pickups/Pistol").set("loaded_rounds", 5)
	await _acquire_placed(level, "Pistol")
	await _press_q()
	_expect(player.active_weapon == &"fists" and player.carried_ranged_weapon == &"pistol",
		"Q switches from the carried pistol to fists while keeping the pistol carried")
	await _press_q()
	_expect(player.active_weapon == &"pistol" and player.get_loaded_rounds() == 5,
		"Q switches back to the carried pistol with its loaded rounds intact")
	await _finish_level(level)


func _test_only_the_active_weapon_responds_to_attack_and_throw() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	level.get_node("Pickups/Pistol").set("loaded_rounds", 5)
	await _acquire_placed(level, "Pistol")
	await _press_q()
	await _aim_right(player)
	await _press("shoot")
	await _press("throw_weapon")
	_expect(get_nodes_in_group("player_projectiles").is_empty()
		and get_nodes_in_group("thrown_weapons").is_empty()
		and player.carried_ranged_weapon == &"pistol",
		"with fists active, left and right click neither fire nor throw the carried pistol")
	await _press_q()
	_expect(player.get_loaded_rounds() == 5, "the inactive pistol kept every loaded round")
	await _press("shoot")
	_expect(get_nodes_in_group("player_projectiles").size() == 1 and player.get_loaded_rounds() == 4,
		"after Q, left click fires the now-active pistol")
	await _press("throw_weapon")
	_expect(get_nodes_in_group("thrown_weapons").size() == 1 and player.active_weapon == &"fists"
		and player.carried_ranged_weapon == &"",
		"right click throws the active pistol and leaves fists as the fallback")
	await _finish_level(level)


func _test_carried_duplicate_collects_magazine_while_fists_are_active() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	var placed := level.get_node("Pickups/Pistol")
	var duplicate := placed.duplicate() as Node2D
	duplicate.position = Vector2(290, 600)
	level.get_node("Pickups").add_child(duplicate)
	placed.set("loaded_rounds", 5)
	await _acquire_placed(level, "Pistol")
	await _press_q()
	var magazines: int = player.pistol_magazines
	player.global_position = duplicate.global_position
	await _press("interact")
	_expect(player.carried_ranged_weapon == &"pistol" and player.active_weapon == &"fists"
		and player.pistol_magazines == magazines + 1 and is_instance_valid(duplicate)
		and int(duplicate.get("loaded_rounds")) == 0,
		"E on a duplicate of the carried pistol collects only its magazine even while fists are active")
	await _press_q()
	_expect(player.get_loaded_rounds() == 5, "the carried pistol was not replaced by the duplicate")
	await _finish_level(level)


func _test_swapping_guns_drops_the_replaced_gun_with_its_loaded_rounds() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	level.get_node("Pickups/Pistol").set("loaded_rounds", 5)
	level.get_node("Pickups/Shotgun").set("loaded_rounds", 4)
	await _acquire_placed(level, "Pistol")
	player.pistol_magazines = 2
	player.global_position = level.get_node("Pickups/Shotgun").global_position
	await _press("interact")
	await physics_frame
	var dropped := _floor_guns(&"pistol")
	_expect(player.active_weapon == &"shotgun" and player.carried_ranged_weapon == &"shotgun"
		and player.get_loaded_rounds() == 4,
		"E on a different gun replaces the single carried ranged weapon")
	_expect(dropped.size() == 1 and int(dropped[0].get("loaded_rounds")) == 5
		and (dropped[0] as Node2D).global_position.distance_to(player.global_position) < 1.0,
		"the replaced pistol is dropped at the player's feet with exactly its loaded rounds")
	_expect(player.pistol_magazines == 2, "retained pistol magazines stay with the player after the swap")
	await _press("interact")
	await physics_frame
	var dropped_shotguns := _floor_guns(&"shotgun")
	_expect(player.active_weapon == &"pistol" and player.get_loaded_rounds() == 5
		and dropped_shotguns.size() == 1 and int(dropped_shotguns[0].get("loaded_rounds")) == 4
		and _floor_guns(&"pistol").is_empty(),
		"swapping back restores the pistol's rounds and drops the shotgun with its own rounds")
	await _finish_level(level)


func _test_swap_is_refused_when_it_would_exceed_the_magazine_limit() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	level.get_node("Pickups/Pistol").set("loaded_rounds", 5)
	await _acquire_placed(level, "Pistol")
	player.shotgun_magazines = 4
	var shotgun := level.get_node("Pickups/Shotgun")
	player.global_position = shotgun.global_position
	await _press("interact")
	await physics_frame
	_expect(player.carried_ranged_weapon == &"pistol" and player.get_loaded_rounds() == 5
		and _floor_guns(&"pistol").is_empty() and is_instance_valid(shotgun)
		and not shotgun.is_queued_for_deletion() and player.shotgun_magazines == 4,
		"a swap that would give a fifth shotgun magazine is refused and keeps the carried pistol")
	await _finish_level(level)


func _test_inactive_carried_gun_still_counts_its_loaded_magazine() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	level.get_node("Pickups/Pistol").set("loaded_rounds", 5)
	await _acquire_placed(level, "Pistol")
	player.pistol_magazines = 3
	await _press_q()
	var magazine := level.get_node("PistolMagazine")
	player.global_position = magazine.global_position
	await _press("interact")
	_expect(player.pistol_magazines == 3 and not magazine.is_queued_for_deletion(),
		"the loaded magazine of the inactive carried pistol still counts toward the four-magazine limit")
	await _finish_level(level)


# Story 17 owns the real katana; a bare katana pickup is enough to prove the melee slot.
func _test_katana_fills_the_melee_slot_beside_the_gun() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	var katana := WeaponPickup.new()
	katana.weapon_type = &"katana"
	katana.position = Vector2(290, 600)
	katana.add_to_group("weapon_pickups")
	level.get_node("Pickups").add_child(katana)
	level.get_node("Pickups/Pistol").set("loaded_rounds", 5)
	await _acquire_placed(level, "Pistol")
	player.global_position = katana.global_position
	await _press("interact")
	await physics_frame
	_expect(player.active_weapon == &"katana" and player.carried_melee_weapon == &"katana"
		and player.carried_ranged_weapon == &"pistol" and _floor_guns(&"pistol").is_empty()
		and not is_instance_valid(katana),
		"E picks up the katana into the melee slot while the pistol stays carried")
	await _press_q()
	_expect(player.active_weapon == &"pistol" and player.get_loaded_rounds() == 5,
		"Q switches from the katana to the carried pistol")
	await _press_q()
	_expect(player.active_weapon == &"katana", "Q switches from the pistol back to the katana")
	player.global_position = Vector2(550, 350)
	await _aim_right(player)
	await _press("shoot")
	await _press("throw_weapon")
	_expect(get_nodes_in_group("player_projectiles").is_empty()
		and get_nodes_in_group("thrown_weapons").is_empty()
		and player.carried_ranged_weapon == &"pistol",
		"with the katana active, left and right click do not use the carried pistol")
	await _press_q()
	await _press("throw_weapon")
	_expect(player.active_weapon == &"katana" and player.carried_ranged_weapon == &""
		and player.carried_melee_weapon == &"katana",
		"throwing the pistol falls back to the carried katana")
	await _finish_level(level)


func _floor_guns(weapon_type: StringName) -> Array[Node]:
	var guns: Array[Node] = []
	for pickup in get_nodes_in_group("weapon_pickups"):
		if StringName(pickup.get("weapon_type")) == weapon_type and not pickup.is_queued_for_deletion():
			guns.append(pickup)
	return guns


func _aim_right(player: Player) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300, 0)
	motion.global_position = motion.position
	root.push_input(motion, true)
	await process_frame


func _start_level() -> Node:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	level.get_node("Player/Camera2D").enabled = false
	for policeman in get_nodes_in_group("police"):
		policeman.set_physics_process(false)
		policeman.get_node("Gun").set_physics_process(false)
	return level


func _acquire_placed(level: Node, pickup_name: String) -> void:
	var player := level.get_node("Player") as Player
	player.global_position = level.get_node("Pickups/" + pickup_name).global_position
	await _press("interact")
	player.global_position = Vector2(550, 350)
	await physics_frame


# Presses the physical Q key so the test also proves the input-map binding.
func _press_q() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_Q
	key.pressed = true
	Input.parse_input_event(key)
	await physics_frame
	await physics_frame
	key = InputEventKey.new()
	key.physical_keycode = KEY_Q
	key.pressed = false
	Input.parse_input_event(key)
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
