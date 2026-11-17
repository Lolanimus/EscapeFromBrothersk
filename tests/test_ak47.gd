extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_player_acquires_ak47()
	await _test_holding_attack_fires_automatically_and_release_stops()
	await _test_31_round_magazine_empties_and_reloads_from_compatible_reserve()
	await _test_configurable_player_speed_and_cadence()
	await _test_player_bullet_kills_and_wall_blocks()
	await _test_police_automatic_fire_is_unlimited_and_configurable()
	await _test_police_bullets_pass_through_police()
	await _test_acquired_gun_is_visible_and_magazine_limit_survives_acquisition()
	if _failures == 0:
		print("PASS: all AK-47 tests passed")
	quit(_failures)


func _test_player_acquires_ak47() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as Player
	var pickup := level.get_node_or_null("Pickups/AK47") as Node2D
	if pickup == null:
		_expect(false, "the prison provides an AK-47 pickup")
	else:
		player.global_position = pickup.global_position
		await physics_frame
		Input.action_press("interact")
		await physics_frame
		Input.action_release("interact")
		await process_frame
		_expect(player.active_weapon == &"ak47" and not is_instance_valid(pickup),
			"E acquires the AK-47 and removes its floor pickup")
	level.queue_free()
	await process_frame


func _test_holding_attack_fires_automatically_and_release_stops() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as Player
	player.set("ak47_projectile_speed", 0.0)
	player.global_position = level.get_node("Pickups/AK47").global_position
	await physics_frame
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")
	await process_frame
	player.global_position = Vector2(500, 300)
	await _aim(player, Vector2.RIGHT)
	Input.action_press("shoot")
	for frame in range(20):
		await physics_frame
	Input.action_release("shoot")
	await physics_frame
	var shots := get_nodes_in_group("player_projectiles").size()
	for frame in range(15):
		await physics_frame
	_expect(shots >= 3 and get_nodes_in_group("player_projectiles").size() == shots,
		"holding attack repeats AK-47 shots at 0.1 seconds; releasing stops (shots %d)" % shots)
	level.queue_free()
	await process_frame


func _aim(player: Node2D, direction: Vector2) -> void:
	var camera := player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	camera.force_update_scroll()
	await process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + direction * 300.0
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await process_frame


func _test_31_round_magazine_empties_and_reloads_from_compatible_reserve() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	for enemy in level.get_node("Enemies").get_children():
		enemy.set_physics_process(false)
		enemy.get_node("Gun").set_physics_process(false)
	var player := level.get_node("Player") as Player
	player.ak47_projectile_speed = 0.0
	player.ak47_firing_cadence = 0.0
	player.global_position = level.get_node("Pickups/AK47").global_position
	await _press("interact")
	player.global_position = Vector2(500, 300)
	await _aim(player, Vector2.RIGHT)
	Input.action_press("shoot")
	for frame in range(36):
		await physics_frame
	Input.action_release("shoot")
	await process_frame
	_expect(get_nodes_in_group("player_projectiles").size() == 31,
		"one AK-47 magazine fires exactly 31 bullets and then stops")
	_expect(player.stats_label.text.contains("EMPTY"), "an empty AK-47 visibly reports EMPTY")
	var magazine := level.get_node("AK-47Magazine") as Node2D
	magazine.global_position = player.global_position
	await _press("interact")
	await _press("reload")
	await _press("shoot")
	_expect(get_nodes_in_group("player_projectiles").size() == 32
		and player.ak47_magazines == 0 and player.get_loaded_rounds() == 30,
		"R consumes a retained AK-47 magazine and permits firing again")
	level.queue_free()
	await process_frame


func _press(action: StringName) -> void:
	Input.action_press(action)
	await physics_frame
	await process_frame
	Input.action_release(action)
	await physics_frame
	await process_frame


func _armed_level() -> Node2D:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	for enemy in level.get_node("Enemies").get_children():
		enemy.set_physics_process(false)
		enemy.get_node("Gun").set_physics_process(false)
	var player := level.get_node("Player") as Player
	player.global_position = level.get_node("Pickups/AK47").global_position
	await _press("interact")
	player.global_position = Vector2(500, 300)
	await _aim(player, Vector2.RIGHT)
	return level


func _test_configurable_player_speed_and_cadence() -> void:
	var level := await _armed_level()
	var player := level.get_node("Player") as Player
	_expect(is_equal_approx(player.ak47_projectile_speed, 1200.0)
		and is_equal_approx(player.ak47_firing_cadence, 0.1),
		"AK-47 selected player defaults are 1200 pixels/second and 0.1 seconds")
	player.ak47_projectile_speed = 600.0
	player.ak47_firing_cadence = 0.5
	Input.action_press("shoot")
	await physics_frame
	await process_frame
	var bullets := get_nodes_in_group("player_projectiles")
	var bullet := bullets[0] as Node2D
	var origin := bullet.global_position
	for frame in range(6):
		await physics_frame
	await process_frame
	_expect(is_equal_approx(origin.distance_to(bullet.global_position), 60.0),
		"configured 600px/s AK-47 bullet travels 60 pixels over six physics frames")
	for frame in range(10):
		await physics_frame
	_expect(player.get_loaded_rounds() == 30, "configured 0.5-second cadence blocks early automatic shots")
	for frame in range(17):
		await physics_frame
	Input.action_release("shoot")
	await process_frame
	_expect(player.get_loaded_rounds() == 29, "automatic fire resumes after configured cadence")
	level.queue_free()
	await process_frame


func _test_player_bullet_kills_and_wall_blocks() -> void:
	for obstructed in [false, true]:
		var level := await _armed_level()
		var enemy := level.get_node("Enemies/Enemy1") as Enemy
		var player := level.get_node("Player") as Player
		var heading := Vector2.RIGHT.rotated(player.aim_pivot.global_rotation)
		enemy.global_position = player.global_position + heading * 200.0
		if obstructed:
			_add_wall(level, player.global_position + heading * 100.0)
		await _press("shoot")
		for frame in range(18):
			await physics_frame
		_expect(enemy.life_state == (&"living" if obstructed else &"dead"),
			"a wall blocks the AK-47 bullet" if obstructed else "one player AK-47 bullet permanently kills a policeman")
		level.queue_free()
		await process_frame


func _test_police_automatic_fire_is_unlimited_and_configurable() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	var gun := enemy.get_node("Gun") as Node2D
	player.global_position = Vector2(700, 300)
	enemy.global_position = Vector2(500, 300)
	enemy.speed = 0.0
	gun.set("weapon_type", &"ak47")
	gun.set("projectile_speed", 0.0)
	enemy.get_node("Vision").global_rotation = PI / 2.0
	var shots: Array[int] = [0]
	level.child_entered_tree.connect(func(child: Node) -> void:
		if child.is_in_group("enemy_projectiles"):
			shots[0] += 1
	)
	for frame in range(205):
		await physics_frame
	_expect(shots[0] > 31,
		"AK-47 police continue automatic fire beyond 31 rounds without ammunition limits")
	# Count new shots rather than live bullets because police bullets expire after three seconds.
	for bullet in get_nodes_in_group("enemy_projectiles"):
		bullet.queue_free()
	gun.set("fire_cadence", 0.3)
	for frame in range(30):
		await physics_frame
	var count := get_nodes_in_group("enemy_projectiles").size()
	_expect(count >= 1 and count <= 2, "configured police 0.3-second cadence controls automatic shots")
	level.queue_free()
	await process_frame


func _test_police_bullets_pass_through_police() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as Player
	var shooter := level.get_node("Enemies/Enemy1") as Enemy
	var other := shooter.duplicate() as Enemy
	other.name = "OtherPoliceman"
	level.get_node("Enemies").add_child(other)
	other.set_physics_process(false)
	other.get_node("Gun").set_physics_process(false)
	player.global_position = Vector2(740, 300)
	shooter.global_position = Vector2(500, 300)
	other.global_position = Vector2(620, 300)
	shooter.speed = 0.0
	var gun := shooter.get_node("Gun")
	gun.set("weapon_type", &"ak47")
	gun.set("projectile_speed", 600.0)
	gun.set("fire_cadence", 10.0)
	shooter.get_node("Vision").global_rotation = PI / 2.0
	for frame in range(35):
		await physics_frame
	_expect(other.life_state == &"living" and player.motivation == 75,
		"a police AK-47 bullet passes through another living policeman and hits the player")
	level.queue_free()
	await process_frame


func _add_wall(level: Node, position: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.position = position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 150)
	collision.shape = shape
	wall.add_child(collision)
	level.add_child(wall)


func _test_acquired_gun_is_visible_and_magazine_limit_survives_acquisition() -> void:
	var level := await _armed_level()
	var player := level.get_node("Player") as Player
	var held := player.get_node_or_null("AimPivot/HeldGun") as Sprite2D
	_expect(held != null and held.visible and held.texture != null
		and held.texture.resource_path == "res://assets/sprites/weapon/ak47.png",
		"acquired AK-47 appears in the player's hands facing the aim direction")
	# A fifth full magazine must remain on the floor alongside its new gun.
	player.shotgun_magazines = 4
	player.global_position = level.get_node("Pickups/Shotgun").global_position
	await _press("interact")
	_expect(player.active_weapon == &"ak47" and level.has_node("Pickups/Shotgun"),
		"four retained shotgun magazines prevent acquiring a fifth loaded magazine")
	level.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		_failures += 1
		push_error("FAIL: " + message)
