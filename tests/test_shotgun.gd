extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
var _failures := 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	await _test_police_fire_six_pellets_in_fixed_spread()
	await _test_police_blast_damages_once()
	await _test_police_cadence_and_unlimited_ammunition()
	await _test_player_six_blast_magazine_and_cadence()
	await _test_player_speed_kills_and_obstruction()
	await _test_closed_door_blocks_shotgun()
	quit(_failures)

func _test_police_fire_six_pellets_in_fixed_spread() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	_keep_only_enemy1(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	var gun := enemy.get_node("Gun")
	if gun.get("weapon_type") == null:
		_expect(false, "police can equip a shotgun and fire six fixed-spread pellets")
		level.queue_free()
		await process_frame
		return
	enemy.speed = 0.0
	player.global_position = Vector2(700, 450)
	enemy.global_position = Vector2(450, 450)
	gun.set("weapon_type", &"shotgun")
	gun.set("projectile_speed", 0.0)
	enemy.get_node("Vision").rotation = PI / 2.0
	await _frames(4)
	var pellets := get_nodes_in_group("enemy_projectiles")
	var directions: Array[float] = []
	for pellet in pellets:
		directions.append(rad_to_deg((pellet.get("direction") as Vector2).angle()))
	directions.sort()
	var spread_matches := directions.size() == 6
	var expected := [-10.0, -6.0, -2.0, 2.0, 6.0, 10.0]
	if spread_matches:
		for index in range(6):
			spread_matches = spread_matches and absf(directions[index] - expected[index]) < 1.0
	_expect(spread_matches, "initial police shotgun fire creates six fixed-spread pellets: %s" % [directions])
	level.queue_free()
	await process_frame

func _test_police_blast_damages_once() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	_keep_only_enemy1(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	enemy.speed = 0.0
	enemy.global_position = Vector2(450, 450)
	player.global_position = Vector2(525, 450)
	var gun := enemy.get_node("Gun")
	gun.set("weapon_type", "shotgun")
	enemy.get_node("Vision").rotation = PI / 2.0
	await _frames(15)
	_expect(player.motivation == 75 and not player.is_dead, "six connected pellets remove exactly 25 motivation (actual %d)" % player.motivation)
	await _frames(73)
	_expect(player.motivation == 50, "a later shotgun blast independently removes another 25 motivation")
	level.queue_free()
	await process_frame

func _test_police_cadence_and_unlimited_ammunition() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	_keep_only_enemy1(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	enemy.speed = 0.0
	enemy.global_position = Vector2(450, 450)
	player.global_position = Vector2(700, 450)
	var gun := enemy.get_node("Gun")
	gun.set("weapon_type", "shotgun")
	gun.set("projectile_speed", 0.0)
	enemy.get_node("Vision").rotation = PI / 2.0
	var fired := [0]
	var observe := func(node: Node) -> void:
		if node.is_in_group("enemy_projectiles"):
			fired[0] += 1
	node_added.connect(observe)
	await _frames(5)
	var initial: int = fired[0]
	await _frames(60)
	var before_cadence: int = fired[0]
	await _frames(14)
	var after_cadence: int = fired[0]
	await _frames(440)
	node_added.disconnect(observe)
	_expect(initial == 6 and before_cadence == 6 and after_cadence == 12 and fired[0] >= 42,
		"police fire immediately, repeat at 1.2 seconds, and continue beyond six blasts (%d/%d/%d/%d pellets)" % [initial, before_cadence, after_cadence, fired[0]])
	level.queue_free()
	await process_frame

func _equip_player(level: Node) -> Player:
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	enemy.set_physics_process(false)
	enemy.get_node("Gun").set_physics_process(false)
	enemy.global_position = Vector2(750, 550)
	var pickup := level.get_node_or_null("Pickups/Shotgun") as Node2D
	if pickup == null:
		_expect(false, "gameplay scene provides a shotgun pickup")
		return null
	player.global_position = pickup.global_position
	await _press("interact")
	player.global_position = Vector2(450, 450)
	await _frames(3)
	var motion := InputEventMouseMotion.new()
	motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300, 0)
	Input.parse_input_event(motion)
	await process_frame
	return player

func _press(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
	await _frames(2)

func _test_player_six_blast_magazine_and_cadence() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	_keep_only_enemy1(level)
	current_scene = level
	await process_frame
	var player := await _equip_player(level)
	if player == null:
		level.queue_free()
		await process_frame
		return
	_expect(player.shotgun_projectile_speed == 1200.0 and player.shotgun_firing_cadence == 0.8,
		"selected player shotgun defaults are speed1200 and cadence0.8 seconds")
	player.shotgun_projectile_speed = 0.0
	player.shotgun_firing_cadence = 0.2
	await _press("shoot")
	var first := get_nodes_in_group("player_projectiles").size()
	await _press("shoot")
	var during_cooldown := get_nodes_in_group("player_projectiles").size()
	await _frames(13)
	for blast in range(5):
		await _press("shoot")
		await _frames(13)
	await _press("shoot")
	_expect(player.active_weapon == &"shotgun" and first == 6 and during_cooldown == 6
		and get_nodes_in_group("player_projectiles").size() == 36 and player.shotgun_bullet == 0,
		"E equips shotgun; cadence blocks early shots; six rounds give six blasts then EMPTY")
	var hud := player.get_node("CanvasLayer/StatsLabel") as Label
	_expect(hud.text.contains("EMPTY"), "empty shotgun is observable in the HUD")
	level.queue_free()
	await process_frame

func _test_player_speed_kills_and_obstruction() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	_keep_only_enemy1(level)
	current_scene = level
	await process_frame
	var player := await _equip_player(level)
	if player == null:
		level.queue_free()
		await process_frame
		return
	player.shotgun_projectile_speed = 600.0
	player.shotgun_firing_cadence = 0.0
	await _press("shoot")
	var pellets := get_nodes_in_group("player_projectiles")
	var start := (pellets[0] as Node2D).global_position
	await _frames(6)
	var traveled := start.distance_to((pellets[0] as Node2D).global_position)
	_expect(absf(traveled - 60.0) < 0.2, "configured shotgun speed600 moves pellets60 pixels in six frames")
	for pellet in pellets:
		pellet.queue_free()
	await process_frame
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	enemy.global_position = Vector2(600, 450)
	var wall := StaticBody2D.new()
	wall.position = Vector2(550, 450)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 150)
	collision.shape = shape
	wall.add_child(collision)
	level.add_child(wall)
	await _frames(2)
	await _press("shoot")
	await _frames(30)
	_expect(enemy.life_state == &"living" and get_nodes_in_group("player_projectiles").is_empty(),
		"wall stops the entire shotgun spread before police (enemy=%s remaining=%s aim=%s player=%s)" % [enemy.life_state, get_nodes_in_group("player_projectiles").size(), player.get_node("AimPivot").rotation, player.global_position])
	wall.queue_free()
	await _frames(2)
	await _press("shoot")
	await _frames(30)
	_expect(enemy.life_state == &"dead", "unobstructed player shotgun pellets kill police in one hit (state=%s aim=%s)" % [enemy.life_state, player.get_node("AimPivot").rotation])
	level.queue_free()
	await process_frame

func _test_closed_door_blocks_shotgun() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	_keep_only_enemy1(level)
	current_scene = level
	await process_frame
	var player := await _equip_player(level)
	if player == null:
		level.queue_free()
		await process_frame
		return
	player.global_position = Vector2(200, 225)
	player.shotgun_firing_cadence = 0.0
	player.shotgun_projectile_speed = 600.0
	var motion := InputEventMouseMotion.new()
	motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300, 0)
	Input.parse_input_event(motion)
	await _frames(2)
	await _press("shoot")
	await _frames(25)
	_expect(get_nodes_in_group("player_projectiles").is_empty(), "closed automatic door stops all six shotgun pellets")
	player.global_position = Vector2(290, 225)
	await _frames(4)
	player.global_position = Vector2(200, 225)
	await _press("shoot")
	await _frames(14)
	var passed := false
	for pellet in get_nodes_in_group("player_projectiles"):
		passed = passed or (pellet as Node2D).global_position.x > 350.0
	_expect(passed, "opened automatic door permits the same shotgun blast")
	level.queue_free()
	await process_frame

func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures += 1
		push_error("FAIL: %s" % message)


## Story 16 posts 24 police in the level. This suite exercises one policeman's
## mechanics (or player navigation), so only Enemy1 is kept to stop the rest of
## the roster from seeing, shooting or blocking shots aimed at the subject.
func _keep_only_enemy1(level: Node) -> void:
	for policeman in get_nodes_in_group("police"):
		if level.is_ancestor_of(policeman) and policeman.name != &"Enemy1":
			policeman.get_parent().remove_child(policeman)
			policeman.free()
