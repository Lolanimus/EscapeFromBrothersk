extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_right_click_throws_and_removes_the_active_gun()
	await _test_gun_knocks_down_only_first_police_and_preserves_ammo()
	await _test_environment_stops_guns_with_visible_impact()
	await _test_configured_speed_and_empty_gun_recovery()
	quit(_failures)


func _test_right_click_throws_and_removes_the_active_gun() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	await _acquire_pistol(level)
	await _aim_and_throw(player)
	var thrown := get_nodes_in_group("thrown_weapons")
	_expect(player.active_weapon == &"fists" and thrown.size() == 1,
		"right click removes the active gun and throws it toward the cursor")
	await _finish_level(level)


func _test_gun_knocks_down_only_first_police_and_preserves_ammo() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	level.get_node("Pickups/Pistol").set("loaded_rounds", 3)
	await _acquire_pistol(level)
	var first := level.get_node("Enemies/Enemy1") as Enemy
	var second := first.duplicate() as Enemy
	first.get_parent().add_child(second)
	second.set_physics_process(false)
	first.global_position = player.global_position + Vector2(120, 0)
	second.global_position = player.global_position + Vector2(220, 0)
	await physics_frame
	await _aim_and_throw(player)
	await create_timer(0.35).timeout
	var floor_guns: Array[Node] = []
	for pickup in get_nodes_in_group("weapon_pickups"):
		if pickup.get("weapon_type") == &"pistol":
			floor_guns.append(pickup)
	_expect(first.life_state == &"knocked_down" and second.life_state == &"living"
		and get_nodes_in_group("thrown_weapons").is_empty() and floor_guns.size() == 1,
		"a thrown gun knocks down only the first policeman and rests on the floor")
	if floor_guns.size() == 1:
		player.global_position = floor_guns[0].global_position
		await _press("interact")
		_expect(player.active_weapon == &"pistol" and player.get_loaded_rounds() == 3,
			"E recovers the thrown gun with its exact remaining loaded ammunition")
	await _finish_level(level)


func _test_environment_stops_guns_with_visible_impact() -> void:
	for path_y in [350.0, 225.0]:
		var level := await _start_level()
		var player := level.get_node("Player") as Player
		await _acquire_pistol(level)
		player.global_position = Vector2(550, path_y)
		var enemy := level.get_node("Enemies/Enemy1") as Enemy
		enemy.global_position = Vector2(950, path_y)
		await physics_frame
		await _aim_and_throw(player)
		await create_timer(0.45).timeout
		var floor_guns := get_nodes_in_group("weapon_pickups")
		var visible_impact := false
		for pickup in floor_guns:
			var cue := pickup.get_node_or_null("ImpactFeedback") as Label
			if pickup.get("weapon_type") == &"pistol" and cue != null:
				visible_impact = cue.visible and cue.text == "IMPACT" and pickup.global_position.x < 860
		_expect(enemy.life_state == &"living" and visible_impact,
			"a %s stops the thrown gun before police and displays impact feedback" % (
				"wall" if path_y == 350.0 else "closed door"))
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


func _test_configured_speed_and_empty_gun_recovery() -> void:
	for setup in [{"path": "Pistol", "type": &"pistol", "speed": 400.0},
		{"path": "Shotgun", "type": &"shotgun", "speed": 800.0},
		{"path": "AK47", "type": &"ak47", "speed": 1200.0}]:
		var level := await _start_level()
		var player := level.get_node("Player") as Player
		var pickup := level.get_node("Pickups/" + setup.path)
		pickup.set("loaded_rounds", 0)
		player.global_position = pickup.global_position
		player.set("thrown_weapon_speed", setup.speed)
		await _press("interact")
		player.global_position = Vector2(550, 350)
		var enemy := level.get_node("Enemies/Enemy1") as Enemy
		enemy.global_position = Vector2(800, 350)
		await physics_frame
		await _aim_and_throw(player)
		var flying := get_nodes_in_group("thrown_weapons")
		_expect(flying.size() == 1, "an empty %s remains throwable" % setup.type)
		if flying.size() == 1:
			var gun := flying[0] as Node2D
			await physics_frame
			var before := gun.global_position
			for frame in range(4):
				await physics_frame
			var distance := gun.global_position.distance_to(before)
			_expect(absf(distance - float(setup.speed) * 4.0 / Engine.physics_ticks_per_second) < 2.0,
				"%s flight uses its configured speed of %s pixels per second" % [setup.type, setup.speed])
			await create_timer(0.8).timeout
			player.global_position = gun.global_position
			await _press("interact")
			_expect(player.active_weapon == setup.type and player.get_loaded_rounds() == 0
				and enemy.life_state == &"knocked_down",
				"the empty %s knocks police down and stays empty after pickup" % setup.type)
		await _finish_level(level)


func _acquire_pistol(level: Node) -> void:
	var player := level.get_node("Player") as Player
	player.global_position = level.get_node("Pickups/Pistol").global_position
	await _press("interact")
	player.global_position = Vector2(550, 350)
	await physics_frame


func _aim_and_throw(player: Player) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300, 0)
	motion.global_position = motion.position
	root.push_input(motion, true)
	await process_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.position = motion.position
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	await physics_frame
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.position = motion.position
	click.pressed = false
	Input.parse_input_event(click)
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
