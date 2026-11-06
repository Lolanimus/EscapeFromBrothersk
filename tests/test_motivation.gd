extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
const PoliceBullet := preload("res://scenes/enemy_projectile.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_start_and_police_damage()
	await _test_permanent_kill_restoration_and_cap()
	await _test_lower_motivation_has_no_penalties()
	await _test_death_at_zero()
	quit(failures)

func _level() -> Node2D:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	level.get_node("Enemies/Enemy1").set_physics_process(false)
	return level

func _hit(level: Node2D) -> void:
	var bullet := PoliceBullet.instantiate()
	bullet.speed = 0.0
	level.add_child(bullet)
	bullet.global_position = level.get_node("Player").global_position
	for frame in range(4):
		await physics_frame
	await process_frame

func _test_start_and_police_damage() -> void:
	var level := _level()
	await process_frame
	var player := level.get_node("Player")
	check(player.motivation == 100, "player starts with 100 motivation")
	await _hit(level)
	check(player.motivation == 75, "a real police bullet removes 25 motivation")
	var hud := player.get_node("CanvasLayer/StatsLabel") as Label
	check(hud.text.contains("75/100"), "HUD reflects the current motivation")
	level.queue_free()
	await process_frame

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _test_permanent_kill_restoration_and_cap() -> void:
	var level := _level()
	await process_frame
	var player := level.get_node("Player")
	var original := level.get_node("Enemies/Enemy1")
	var template := original.duplicate()
	await _hit(level)
	for index in range(4):
		var enemy: Node2D = original if index == 0 else template.duplicate()
		if index > 0:
			level.get_node("Enemies").add_child(enemy)
		enemy.set_physics_process(false)
		enemy.global_position = Vector2(600, 350)
		var bullet = load("res://scenes/pistol_projectile.tscn").instantiate()
		bullet.speed = 0.0
		level.add_child(bullet)
		bullet.global_position = enemy.global_position
		for frame in range(4):
			await physics_frame
		check(enemy.life_state == &"dead", "player projectile permanently kills policeman")
		if index == 0:
			check(player.motivation == 85, "a permanent kill restores 10 motivation")
	check(player.motivation == 100, "permanent-kill rewards cap at 100 motivation")
	template.free()
	level.queue_free()
	await process_frame

func _test_death_at_zero() -> void:
	var level := _level()
	await process_frame
	var player := level.get_node("Player")
	for hit in range(3):
		await _hit(level)
	check(player.motivation == 25 and player.is_physics_processing(), "player remains alive after three police hits")
	await _hit(level)
	var death_notice := player.get_node_or_null("CanvasLayer/DeathNotice") as Label
	check(player.motivation == 0 and death_notice != null and death_notice.visible,
		"fourth police hit displays the player-death state at zero motivation")
	var position_before: Vector2 = player.global_position
	Input.action_press("move_right")
	Input.action_press("shoot")
	for frame in range(6):
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("shoot")
	check(player.global_position.is_equal_approx(position_before), "dead player cannot move")
	await _hit(level)
	check(player.motivation == 0, "extra police hits cannot reduce motivation below zero")
	level.queue_free()
	await process_frame

func _test_lower_motivation_has_no_penalties() -> void:
	var level := _level()
	await process_frame
	var player := level.get_node("Player")
	var skin := player.get_node("skin") as AnimatedSprite2D
	var original_modulate := skin.modulate
	Input.action_press("move_right")
	await physics_frame
	await physics_frame
	var full_speed: Vector2 = player.velocity
	Input.action_release("move_right")
	await _hit(level)
	Input.action_press("move_right")
	await physics_frame
	await physics_frame
	Input.action_release("move_right")
	check(full_speed.x > 0 and player.velocity.is_equal_approx(full_speed) and skin.modulate == original_modulate,
		"lower motivation preserves movement speed and player presentation")
	var bar := player.get_node_or_null("CanvasLayer/MotivationBar") as ProgressBar
	check(bar != null and bar.value == 75 and bar.max_value == 100,
		"motivation bar shows 75 of 100 after a hit")
	level.queue_free()
	await process_frame
