extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
var failures := 0
var police_shots := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_unlimited_sight_chases_and_shoots()
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	level.child_entered_tree.connect(func(node: Node):
		if node is EnemyProjectile:
			police_shots += 1
	)
	await process_frame
	var player = level.get_node("Player")
	var enemy = level.get_node("Enemies/Enemy1")
	player.get_node("Camera2D").enabled = false
	player.global_position = Vector2(600, 350)
	enemy.global_position = Vector2(600, 250)
	enemy.speed = 0.0
	enemy.get_node("Vision").global_rotation = PI
	var body := enemy.get_node("PoliceVisual") as Polygon2D
	check(body.is_visible_in_tree() and body.polygon.size() >= 3, "police have a visible body")
	check(not enemy.get_node("Gun").is_in_group("weapon_pickups"), "equipped police gun is not a floor pickup")
	var starting_motivation: int = player.motivation
	await create_timer(1.2).timeout
	check(player.motivation < starting_motivation, "visible policeman shoots and hits the player")
	enemy.global_position = player.global_position + Vector2(36, 0)
	player.get_node("Camera2D").force_update_scroll()
	await process_frame
	var motion := InputEventMouseMotion.new()
	motion.global_position = enemy.get_global_transform_with_canvas() * Vector2.ZERO
	motion.position = enemy.get_global_transform_with_canvas() * Vector2.ZERO
	Input.parse_input_event(motion)
	await process_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = motion.position
	click.global_position = motion.position
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	await physics_frame
	click.pressed = false
	Input.parse_input_event(click)
	check(enemy.life_state == &"knocked_down", "shoot input while unarmed knocks the armed policeman down")
	await create_timer(0.2).timeout
	var downed_motivation: int = player.motivation
	var shots_after_knockdown := police_shots
	await create_timer(1.2).timeout
	check(police_shots == shots_after_knockdown and player.motivation == downed_motivation, "knocked-down policeman stops shooting")
	var old_time_scale := Engine.time_scale
	Engine.time_scale = 15.0
	await create_timer(15.1).timeout
	Engine.time_scale = old_time_scale
	check(enemy.life_state == &"living" and enemy.get_node("Gun").visible,
		"recovered policeman stands up with his gun")
	var shots_before_recovery := police_shots
	await create_timer(1.2).timeout
	check(police_shots > shots_before_recovery, "recovered policeman resumes shooting")
	enemy.take_player_projectile_hit()
	var shots_after_death := police_shots
	await create_timer(1.2).timeout
	check(police_shots == shots_after_death and not enemy.get_node("Gun").visible,
		"dead policeman stops shooting and leaves a distinct body")
	level.queue_free()
	await process_frame
	quit(failures)

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _test_unlimited_sight_chases_and_shoots() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player = level.get_node("Player")
	var enemy = level.get_node("Enemies/Enemy1")
	enemy.set_physics_process(false)
	player.global_position = Vector2(13000, 3000)
	enemy.global_position = Vector2(3000, 3000)
	enemy.get_node("Vision").rotation = PI / 2
	var wall := StaticBody2D.new()
	wall.position = Vector2(8000, 3000)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 200)
	collision.shape = shape
	wall.add_child(collision)
	level.add_child(wall)
	await physics_frame
	await physics_frame
	enemy.set_physics_process(true)
	await physics_frame
	await physics_frame
	check(not enemy.is_alerted and enemy.velocity.is_zero_approx(), "walls block distant visual detection")
	wall.collision_layer = 8
	await physics_frame
	await physics_frame
	check(not enemy.is_alerted, "closed-door collision layer blocks police detection")
	enemy.get_node("Vision").global_rotation = 0.0
	await create_timer(0.3).timeout
	check(is_zero_approx(enemy.get_node("Vision").global_rotation),
		"unalerted policeman does not aim his cone at a hidden player")
	enemy.get_node("Vision").global_rotation = PI / 2
	wall.queue_free()
	await physics_frame
	await physics_frame
	await physics_frame
	check(enemy.is_alerted and enemy.velocity.x > 0, "enemy detects and chases a visible player ten thousand pixels away")
	var bullets := 0
	for child in level.get_children():
		if child is EnemyProjectile:
			bullets += 1
	check(bullets > 0, "enemy fires immediately while chasing")
	level.queue_free()
	await process_frame
