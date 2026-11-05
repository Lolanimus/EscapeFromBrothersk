extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_unarmed_left_click_knocks_down_a_targeted_policeman()
	await _test_knocked_down_policeman_shows_warning_during_final_three_seconds()
	await _test_unfinished_policeman_recovers_to_living_after_fifteen_seconds()
	await _test_living_knocked_down_recovering_and_dead_police_look_distinctly_different()
	if _failures == 0:
		print("PASS: all punch and recovery tests passed")
	else:
		push_error("FAIL: %d punch and recovery test(s) failed" % _failures)
	quit(_failures)


func _test_unarmed_left_click_knocks_down_a_targeted_policeman() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as CharacterBody2D
	var enemy := level.get_node("Enemies/Enemy1") as CharacterBody2D
	enemy.speed = 0.0
	enemy.global_position = player.global_position + Vector2(36.0, 0.0)
	await _click_toward_enemy(player, enemy)
	_expect(player.get("active_weapon") == &"fists" and enemy.get("life_state") == &"knocked_down",
		"left click while unarmed knocks down the targeted policeman without killing him")
	level.queue_free()
	await process_frame


func _test_knocked_down_policeman_shows_warning_during_final_three_seconds() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as CharacterBody2D
	var enemy := level.get_node("Enemies/Enemy1") as CharacterBody2D
	enemy.speed = 0.0
	enemy.global_position = player.global_position + Vector2(36.0, 0.0)
	await _click_toward_enemy(player, enemy)
	var previous_time_scale := Engine.time_scale
	Engine.time_scale = 15.0
	await create_timer(12.1, true, false, false).timeout
	var warning := enemy.get_node_or_null("RecoveryWarning") as Label
	_expect(enemy.get("life_state") == &"recovering" and warning != null and warning.visible,
		"the policeman displays a visible recovery warning during the final three seconds")
	Engine.time_scale = previous_time_scale
	level.queue_free()
	await process_frame


func _test_unfinished_policeman_recovers_to_living_after_fifteen_seconds() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as CharacterBody2D
	var enemy := level.get_node("Enemies/Enemy1") as CharacterBody2D
	enemy.speed = 0.0
	enemy.global_position = player.global_position + Vector2(36.0, 0.0)
	await _click_toward_enemy(player, enemy)
	var previous_time_scale := Engine.time_scale
	Engine.time_scale = 15.0
	await create_timer(15.1, true, false, false).timeout
	var warning := enemy.get_node("RecoveryWarning") as Label
	_expect(enemy.get("life_state") == &"living" and not warning.visible and enemy.is_physics_processing(),
		"an un-killed policeman recovers to living after fifteen seconds")
	Engine.time_scale = previous_time_scale
	level.queue_free()
	await process_frame


func _test_living_knocked_down_recovering_and_dead_police_look_distinctly_different() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as CharacterBody2D
	var enemy := level.get_node("Enemies/Enemy1") as CharacterBody2D
	enemy.speed = 0.0
	var visual := enemy.get_node_or_null("PoliceVisual") as Polygon2D
	if visual == null:
		_expect(false, "police have a visible body with distinct state presentation")
		level.queue_free()
		await process_frame
		return
	var living_color := visual.color
	enemy.global_position = player.global_position + Vector2(36.0, 0.0)
	await _click_toward_enemy(player, enemy)
	var knocked_color := visual.color
	var previous_time_scale := Engine.time_scale
	Engine.time_scale = 15.0
	await create_timer(12.1, true, false, false).timeout
	var recovering_color := visual.color
	var warning := enemy.get_node("RecoveryWarning") as Label
	var states_are_distinct := living_color != knocked_color and knocked_color != recovering_color and warning.visible
	enemy.take_player_projectile_hit()
	var dead_color := visual.color
	_expect(states_are_distinct and dead_color != living_color and dead_color != knocked_color
		and dead_color != recovering_color,
		"living, knocked-down, recovering, and dead police have distinct visible states")
	Engine.time_scale = previous_time_scale
	level.queue_free()
	await process_frame


func _click_toward_enemy(player: CharacterBody2D, enemy: CharacterBody2D) -> void:
	var cursor_position: Vector2 = enemy.get_global_transform_with_canvas() * Vector2.ZERO
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = cursor_position
	mouse_motion.global_position = cursor_position
	Input.parse_input_event(mouse_motion)
	await process_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = cursor_position
	click.global_position = cursor_position
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	click.pressed = false
	Input.parse_input_event(click)
	await physics_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failures += 1
	push_error("FAIL: %s" % message)
