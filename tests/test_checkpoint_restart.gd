extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
const START_POSITION := Vector2(225, 225)

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_backspace_discards_loot_thrown_guns_doors_and_exit_progress()
	await _test_backspace_after_death_restores_knocked_down_police()
	if _failures == 0:
		print("PASS: all checkpoint restart tests passed")
	else:
		push_error("FAIL: %d checkpoint restart test(s) failed" % _failures)
	quit(_failures)


func _test_backspace_discards_loot_thrown_guns_doors_and_exit_progress() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	# Every other posted policeman dies too, so the exit unlocks when Enemy1 is shot.
	for policeman in _police(level):
		if policeman != enemy:
			policeman.kill_permanently()
	await _press("interact")
	player.global_position = level.get_node("Pickups/Pistol").global_position
	await _press("interact")
	enemy.global_position = Vector2(650, 350)
	player.global_position = Vector2(550, 350)
	await physics_frame
	await _aim_right(player)
	await _press("shoot")
	for frame in range(10):
		await physics_frame
	await _throw_right()
	await create_timer(0.3).timeout
	player.global_position = Vector2(330, 225)
	for frame in range(6):
		await physics_frame
	var doors_opened := get_nodes_in_group("automatic_doors").any(func(door: Node) -> bool: return door.is_open)
	_expect(enemy.life_state == &"dead" and not get_nodes_in_group("police_drops").is_empty()
		and not level.has_node("Pickups/Pistol") and not level.has_node("Pickups/Katana")
		and player.carried_melee_weapon == &"katana" and doors_opened and level.exit_unlocked
		and player.pistol_bullet < 12,
		"the attempt takes the katana, kills police, drops loot, throws a gun, opens a door and unlocks the exit")
	await _restart_with_backspace(level, "Backspace while alive")


func _test_backspace_after_death_restores_knocked_down_police() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	enemy.knock_down()
	player.global_position = Vector2(400, 225)
	for hit in range(4):
		player.take_police_projectile_hit()
	await physics_frame
	_expect(player.is_dead and enemy.life_state == &"knocked_down",
		"the attempt ends with a dead player and a knocked-down policeman")
	await _restart_with_backspace(level, "Backspace after death")


func _restart_with_backspace(level: Node, label: String) -> void:
	var previous_instance := level.get_instance_id()
	var started := Time.get_ticks_msec()
	var key := InputEventKey.new()
	key.keycode = KEY_BACKSPACE
	key.pressed = true
	root.push_input(key)
	key = key.duplicate()
	key.pressed = false
	root.push_input(key)
	while (current_scene == null or current_scene.get_instance_id() == previous_instance
		or not current_scene.is_node_ready()) and Time.get_ticks_msec() - started < 2000:
		await process_frame
	await physics_frame
	var elapsed := Time.get_ticks_msec() - started
	_expect(current_scene != null and current_scene.get_instance_id() != previous_instance and elapsed < 1000,
		"%s restores the level start in under one second (%d ms)" % [label, elapsed])
	if current_scene != null and current_scene.get_instance_id() != previous_instance:
		_expect_level_start(current_scene, label)
		await _finish_level(current_scene)


func _expect_level_start(level: Node, label: String) -> void:
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	_expect(not player.is_dead and player.motivation == Player.MAX_MOTIVATION
		and player.global_position.is_equal_approx(START_POSITION) and player.active_weapon == &"fists"
		and player.carried_melee_weapon == &"" and player.carried_ranged_weapon == &""
		and player.pistol_magazines == 0 and player.shotgun_magazines == 0 and player.ak47_magazines == 0,
		"%s respawns the player at the start with full motivation, fists and no magazines" % label)
	_expect(enemy.life_state == &"living" and not enemy.is_alerted,
		"%s restores the policeman alive and unalerted" % label)
	var police := _police(level)
	_expect(police.size() == PrisonLevel.POLICE_POSTS.size() + 1
		and police.all(func(policeman: Enemy) -> bool: return policeman.life_state == &"living" and not policeman.is_alerted),
		"%s restores all %d posted policemen alive and unalerted" % [label, police.size()])
	_expect(level.has_node("Pickups/Pistol") and level.has_node("Pickups/Shotgun") and level.has_node("Pickups/AK47")
		and level.has_node("Pickups/Katana")
		and level.has_node("PistolMagazine") and level.has_node("ShotgunMagazine") and level.has_node("AK-47Magazine")
		and get_nodes_in_group("police_drops").is_empty() and get_nodes_in_group("thrown_weapons").is_empty()
		and get_nodes_in_group("weapon_pickups").size() == 4,
		"%s restores placed pickups and removes loot and thrown guns" % label)
	_expect(get_nodes_in_group("automatic_doors").all(func(door: Node) -> bool: return not door.is_open)
		and not level.exit_unlocked and not level.level_complete
		and level.get_node("Prison/ExitStatus").text == "EXIT LOCKED",
		"%s closes every door and relocks the exit" % label)


func _start_level() -> Node:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	level.get_node("Player/Camera2D").enabled = false
	for policeman in get_nodes_in_group("police"):
		policeman.set_physics_process(false)
	return level


func _aim_right(player: Player) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300, 0)
	motion.global_position = motion.position
	root.push_input(motion, true)
	await process_frame


func _throw_right() -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	await physics_frame
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	await process_frame


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await process_frame


func _police(level: Node) -> Array[Enemy]:
	var police: Array[Enemy] = []
	for policeman in get_nodes_in_group("police"):
		if level.is_ancestor_of(policeman):
			police.append(policeman as Enemy)
	return police


func _finish_level(level: Node) -> void:
	level.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
