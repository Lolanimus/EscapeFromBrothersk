extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
const ProjectileScene := preload("res://scenes/pistol_projectile.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_player_can_pick_up_the_pistol()
	await _test_left_click_fires_one_projectile_toward_the_cursor()
	await _test_pistol_projectile_kills_a_living_policeman_in_one_hit()
	await _test_pistol_projectile_kills_a_knocked_down_policeman_in_one_hit()
	await _test_wall_stops_projectile_before_it_reaches_policeman()
	await _test_closed_door_blocks_projectiles_and_open_door_allows_them()
	await _test_pistol_projectile_speed_is_configurable_and_observable()
	await _test_player_pistol_firing_cadence_is_configurable_and_observable()

	if _failures == 0:
		print("PASS: all pistol tests passed")
	else:
		push_error("FAIL: %d pistol test(s) failed" % _failures)

	quit(_failures)


func _test_player_can_pick_up_the_pistol() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var pistol_pickup := level.get_node_or_null("Pickups/Pistol") as Node2D
	if pistol_pickup == null:
		_expect(false, "the gameplay scene provides a pistol for the player to acquire")
		level.queue_free()
		await process_frame
		return

	player.global_position = pistol_pickup.global_position
	await physics_frame
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")
	await process_frame

	var skin := player.get_node("skin") as AnimatedSprite2D
	var equipped_texture := skin.sprite_frames.get_frame_texture(skin.animation, skin.frame)
	_expect(
		player.get("active_weapon") == &"pistol"
		and not is_instance_valid(pistol_pickup)
		and skin.animation == &"idle_pistol_side"
		and equipped_texture != null
		and equipped_texture.resource_path
		== "res://assets/sprites/main character/attack/pistol2.png",
		"pressing E beside the pistol visibly equips it and removes it from the floor"
	)

	level.queue_free()
	await process_frame


func _test_left_click_fires_one_projectile_toward_the_cursor() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var pistol_pickup := level.get_node("Pickups/Pistol") as Node2D
	player.set("pistol_projectile_speed", 0.0)
	player.global_position = pistol_pickup.global_position
	await physics_frame
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")

	var player_viewport_position: Vector2 = (
		player.get_global_transform_with_canvas() * Vector2.ZERO
	)
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = player_viewport_position + Vector2(300.0, 0.0)
	mouse_motion.global_position = mouse_motion.position
	Input.parse_input_event(mouse_motion)
	await process_frame
	var aim_pivot := player.get_node("AimPivot") as Node2D
	var muzzle := player.get_node_or_null("Muzzle") as Marker2D

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = false
	Input.parse_input_event(click)

	for frame in range(3):
		await physics_frame
	var projectiles := get_nodes_in_group("player_projectiles")
	var aimed_direction := Vector2.RIGHT.rotated(aim_pivot.global_rotation)

	var fired_toward_cursor := false
	var travel_direction := Vector2.ZERO
	var projectile_position := Vector2.ZERO
	var projectile_direction := Vector2.ZERO
	var projectile_rotation := 0.0
	var spawned_from_barrel := false
	if projectiles.size() == 1:
		var projectile := projectiles[0] as Node2D
		projectile_position = projectile.global_position
		projectile_direction = projectile.get("direction") as Vector2
		projectile_rotation = projectile.global_rotation
		travel_direction = player.global_position.direction_to(projectile.global_position)
		fired_toward_cursor = projectile_direction.dot(aimed_direction) > 0.99
		var expected_barrel_position := player.global_position + Vector2(21.0, -13.0)
		spawned_from_barrel = (
			muzzle != null
			and projectile.global_position.distance_to(muzzle.global_position) < 0.1
			and projectile.global_position.distance_to(expected_barrel_position) < 0.1
		)
	var bullet_faces_travel_direction := (
		absf(angle_difference(projectile_rotation, projectile_direction.angle())) < 0.001
	)
	_expect(
		projectiles.size() == 1
		and fired_toward_cursor
		and bullet_faces_travel_direction
		and spawned_from_barrel,
		"left click fires one pistol projectile from the barrel facing toward the cursor "
		+ "(projectiles: %d, player: %s, projectile: %s, stored direction: %s, rotation: %.3f, aim: %s, travel: %s, moved correctly: %s)" % [
			projectiles.size(),
			player.global_position,
			projectile_position,
			projectile_direction,
			projectile_rotation,
			aimed_direction,
			travel_direction,
			fired_toward_cursor,
		]
	)

	level.queue_free()
	await process_frame


func _test_pistol_projectile_kills_a_living_policeman_in_one_hit() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var enemy := level.get_node("Enemies/Enemy1") as CharacterBody2D
	var pistol_pickup := level.get_node("Pickups/Pistol") as Node2D
	player.global_position = pistol_pickup.global_position
	enemy.speed = 0.0
	await physics_frame
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")

	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300.0, 0.0)
	mouse_motion.global_position = mouse_motion.position
	Input.parse_input_event(mouse_motion)
	await process_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = false
	Input.parse_input_event(click)
	await physics_frame

	var projectiles := get_nodes_in_group("player_projectiles")
	if projectiles.size() == 1:
		var projectile := projectiles[0] as Node2D
		var direction := projectile.get("direction") as Vector2
		enemy.global_position = projectile.global_position + direction * 400.0
	for frame in range(50):
		await physics_frame

	var remaining_projectiles := get_nodes_in_group("player_projectiles")
	var projectile_position := Vector2.ZERO
	if not remaining_projectiles.is_empty():
		projectile_position = (remaining_projectiles[0] as Node2D).global_position
	_expect(
		enemy.get("life_state") == &"dead",
		"one pistol projectile permanently kills a distant living policeman without damage falloff "
		+ "(enemy: %s, projectile: %s, remaining projectiles: %d)" % [
			enemy.global_position,
			projectile_position,
			remaining_projectiles.size(),
		]
	)

	level.queue_free()
	await process_frame


func _test_pistol_projectile_kills_a_knocked_down_policeman_in_one_hit() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var enemy := level.get_node("Enemies/Enemy1") as CharacterBody2D
	var pistol_pickup := level.get_node("Pickups/Pistol") as Node2D
	player.global_position = pistol_pickup.global_position
	enemy.speed = 0.0
	enemy.set("life_state", &"knocked_down")
	await physics_frame
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")

	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300.0, 0.0)
	mouse_motion.global_position = mouse_motion.position
	Input.parse_input_event(mouse_motion)
	await process_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = false
	Input.parse_input_event(click)
	await physics_frame

	var projectiles := get_nodes_in_group("player_projectiles")
	if projectiles.size() == 1:
		var projectile := projectiles[0] as Node2D
		var direction := projectile.get("direction") as Vector2
		enemy.global_position = projectile.global_position + direction * 60.0
	for frame in range(15):
		await physics_frame

	_expect(
		enemy.get("life_state") == &"dead",
		"one pistol projectile permanently kills a knocked-down policeman"
	)

	level.queue_free()
	await process_frame


func _test_wall_stops_projectile_before_it_reaches_policeman() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var enemy := level.get_node("Enemies/Enemy1") as CharacterBody2D
	var pistol_pickup := level.get_node("Pickups/Pistol") as Node2D
	player.global_position = pistol_pickup.global_position
	enemy.speed = 0.0
	await physics_frame
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")

	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300.0, 0.0)
	mouse_motion.global_position = mouse_motion.position
	Input.parse_input_event(mouse_motion)
	await process_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = false
	Input.parse_input_event(click)
	await physics_frame

	var projectiles := get_nodes_in_group("player_projectiles")
	if projectiles.size() == 1:
		var projectile := projectiles[0] as Node2D
		var direction := projectile.get("direction") as Vector2
		var wall := StaticBody2D.new()
		wall.global_position = projectile.global_position + direction * 60.0
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(20.0, 120.0)
		collision.shape = shape
		wall.add_child(collision)
		level.add_child(wall)
		enemy.global_position = projectile.global_position + direction * 120.0
	for frame in range(20):
		await physics_frame

	_expect(
		get_nodes_in_group("player_projectiles").is_empty()
		and enemy.get("life_state") == &"living",
		"a wall stops the projectile without penetration or ricochet"
	)

	level.queue_free()
	await process_frame


func _test_closed_door_blocks_projectiles_and_open_door_allows_them() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var door: Node2D = null
	for candidate: Node in get_nodes_in_group("automatic_doors"):
		var candidate_door := candidate as Node2D
		if candidate_door != null and candidate_door.global_position == Vector2(350.0, 225.0):
			door = candidate_door
			break
	var player := level.get_node("Player") as CharacterBody2D
	player.global_position = Vector2(200.0, 225.0)
	var blocked_projectile := ProjectileScene.instantiate() as PistolProjectile
	blocked_projectile.global_position = Vector2(300.0, 225.0)
	blocked_projectile.direction = Vector2.RIGHT
	blocked_projectile.speed = 600.0
	level.add_child(blocked_projectile)
	for frame in range(12):
		await physics_frame
	var closed_door_stopped_projectile := not is_instance_valid(blocked_projectile)

	player.global_position = Vector2(290.0, 225.0)
	for frame in range(3):
		await physics_frame
	player.global_position = Vector2(200.0, 225.0)
	var open_projectile := ProjectileScene.instantiate() as PistolProjectile
	open_projectile.global_position = Vector2(300.0, 225.0)
	open_projectile.direction = Vector2.RIGHT
	open_projectile.speed = 600.0
	level.add_child(open_projectile)
	for frame in range(8):
		await physics_frame
	var open_door_allowed_projectile := (
		is_instance_valid(open_projectile) and open_projectile.global_position.x > 350.0
	)

	_expect(
		door != null and closed_door_stopped_projectile and open_door_allowed_projectile,
		"a closed door stops projectiles and the same open doorway allows them through"
	)

	level.queue_free()
	await process_frame


func _test_pistol_projectile_speed_is_configurable_and_observable() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var configured_speed = player.get("pistol_projectile_speed")
	if configured_speed == null:
		_expect(false, "pistol projectile speed is publicly configurable")
		level.queue_free()
		await process_frame
		return
	_expect(
		is_equal_approx(float(configured_speed), 1200.0),
		"the selected default pistol projectile speed is 1200 pixels per second"
	)
	player.set("pistol_projectile_speed", 600.0)

	var pistol_pickup := level.get_node("Pickups/Pistol") as Node2D
	player.global_position = pistol_pickup.global_position
	await physics_frame
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300.0, 0.0)
	mouse_motion.global_position = mouse_motion.position
	Input.parse_input_event(mouse_motion)
	await process_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = false
	Input.parse_input_event(click)
	await physics_frame

	var projectiles := get_nodes_in_group("player_projectiles")
	var start_position := Vector2.ZERO
	if projectiles.size() == 1:
		start_position = (projectiles[0] as Node2D).global_position
	for frame in range(6):
		await physics_frame
	projectiles = get_nodes_in_group("player_projectiles")
	var distance_traveled := 0.0
	if projectiles.size() == 1:
		distance_traveled = start_position.distance_to((projectiles[0] as Node2D).global_position)

	_expect(
		projectiles.size() == 1 and is_equal_approx(distance_traveled, 60.0),
		"a configured 600 pixel-per-second projectile travels 60 pixels in six physics frames "
		+ "(distance: %s)" % distance_traveled
	)

	level.queue_free()
	await process_frame


func _test_player_pistol_firing_cadence_is_configurable_and_observable() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var configured_cadence = player.get("pistol_firing_cadence")
	if configured_cadence == null:
		_expect(false, "player pistol firing cadence is publicly configurable")
		level.queue_free()
		await process_frame
		return
	_expect(
		is_equal_approx(float(configured_cadence), 0.25),
		"the selected default player pistol firing cadence is 0.25 seconds"
	)
	player.set("pistol_firing_cadence", 0.5)
	player.set("pistol_projectile_speed", 0.0)

	var pistol_pickup := level.get_node("Pickups/Pistol") as Node2D
	player.global_position = pistol_pickup.global_position
	await physics_frame
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300.0, 0.0)
	mouse_motion.global_position = mouse_motion.position
	Input.parse_input_event(mouse_motion)
	await process_frame

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = false
	Input.parse_input_event(click)
	await physics_frame

	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = false
	Input.parse_input_event(click)
	await physics_frame
	var projectiles_during_cooldown := get_nodes_in_group("player_projectiles").size()

	for frame in range(31):
		await physics_frame
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = false
	Input.parse_input_event(click)
	await physics_frame
	var projectiles_after_cooldown := get_nodes_in_group("player_projectiles").size()

	_expect(
		projectiles_during_cooldown == 1 and projectiles_after_cooldown == 2,
		"a configured 0.5-second cadence blocks an immediate shot and allows the next timed shot "
		+ "(during: %d, after: %d)" % [
			projectiles_during_cooldown,
			projectiles_after_cooldown,
		]
	)

	level.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return

	_failures += 1
	push_error("FAIL: %s" % message)
