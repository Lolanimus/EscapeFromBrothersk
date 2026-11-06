extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
const PoliceBullet := preload("res://scenes/enemy_projectile.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_three_second_hold_kills()
	await _test_visible_progress_and_movement_lock()
	await _test_release_resets_progress()
	await _test_movement_cancels_choke()
	await _test_damage_cancels_and_completion_restores_motivation()
	await _test_choke_requires_a_reachable_down_policeman()
	await _test_opposing_movement_inputs_cancel()
	await _test_recovery_cancels_choke()
	await _test_target_removed_cancels()
	await _test_lethal_damage_cancels()
	if failures == 0:
		print("PASS: all choking tests passed")
	quit(failures)

func _prepare() -> Node2D:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	enemy.set_physics_process(false)
	enemy.global_position = player.global_position + Vector2(36, 0)
	var motion := InputEventMouseMotion.new()
	motion.position = enemy.get_global_transform_with_canvas() * Vector2.ZERO
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await process_frame
	await _mouse(true)
	await _mouse(false)
	check(enemy.life_state == &"knocked_down", "scene input punches policeman unconscious")
	return level

func _mouse(pressed: bool) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = pressed
	click.position = root.get_mouse_position()
	click.global_position = click.position
	Input.parse_input_event(click)
	await physics_frame
	await physics_frame

func _finish(level: Node2D) -> void:
	await _mouse(false)
	for action in ["move_left", "move_right", "move_up", "move_down", "interact"]:
		Input.action_release(action)
	level.queue_free()
	await process_frame

func _test_three_second_hold_kills() -> void:
	var level := await _prepare()
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	await _mouse(true)
	await create_timer(2.7).timeout
	check(enemy.life_state == &"knocked_down", "choke does not kill before three seconds")
	await create_timer(0.4).timeout
	check(enemy.life_state == &"dead", "three uninterrupted seconds of held left click permanently kill")
	check(level.get_node("Player").motivation == 100, "choke reward respects the motivation cap")
	await _finish(level)

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _test_visible_progress_and_movement_lock() -> void:
	var level := await _prepare()
	var player := level.get_node("Player") as Player
	var starting_position := player.global_position
	await _mouse(true)
	await create_timer(1.0).timeout
	var bar := player.get_node_or_null("CanvasLayer/ChokeProgress") as ProgressBar
	check(bar != null and bar.visible and bar.max_value == 3.0 and bar.value > 0.8 and bar.value < 1.3,
		"visible choke progress communicates elapsed time toward three seconds")
	check(player.global_position.is_equal_approx(starting_position) and player.velocity.is_zero_approx(),
		"player remains still during choking")
	await _finish(level)

func _test_release_resets_progress() -> void:
	var level := await _prepare()
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	var bar := level.get_node("Player/CanvasLayer/ChokeProgress") as ProgressBar
	await _mouse(true)
	await create_timer(1.8).timeout
	await _mouse(false)
	await process_frame
	check(bar.value == 0 and not bar.visible, "releasing left click hides and resets choke progress")
	await _mouse(true)
	await create_timer(1.5).timeout
	check(enemy.life_state != &"dead", "restarting a hold cannot reuse earlier progress")
	await create_timer(1.6).timeout
	check(enemy.life_state == &"dead", "a fresh uninterrupted hold still completes after release")
	await _finish(level)

func _test_movement_cancels_choke() -> void:
	var level := await _prepare()
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	await _mouse(true)
	await create_timer(0.8).timeout
	Input.action_press("move_right")
	await physics_frame
	await physics_frame
	Input.action_release("move_right")
	await process_frame
	var bar := player.get_node("CanvasLayer/ChokeProgress") as ProgressBar
	check(bar.value == 0 and not bar.visible, "attempting movement cancels and resets the choke")
	await create_timer(3.1).timeout
	check(enemy.life_state != &"dead", "holding the button after cancellation cannot silently resume choking")
	await _finish(level)

func _police_hit(level: Node2D) -> void:
	var bullet := PoliceBullet.instantiate()
	bullet.speed = 0.0
	level.add_child(bullet)
	bullet.global_position = level.get_node("Player").global_position
	for frame in range(4):
		await physics_frame
	await process_frame

func _test_damage_cancels_and_completion_restores_motivation() -> void:
	var level := await _prepare()
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	await _mouse(true)
	await create_timer(0.8).timeout
	await _police_hit(level)
	var bar := player.get_node("CanvasLayer/ChokeProgress") as ProgressBar
	check(player.motivation == 75 and bar.value == 0 and not bar.visible,
		"a real police bullet cancels choking and clears progress")
	await create_timer(3.1).timeout
	check(enemy.life_state != &"dead", "damage cancellation requires a new hold")
	await _mouse(false)
	await _mouse(true)
	await create_timer(3.1).timeout
	check(enemy.life_state == &"dead" and player.motivation == 85,
		"completed choke uses permanent death and restores 10 motivation")
	await create_timer(0.5).timeout
	check(player.motivation == 85 and enemy.collision_layer == 0,
		"continued holding cannot reward the same permanent kill twice")
	await _finish(level)

func _test_choke_requires_a_reachable_down_policeman() -> void:
	var level := await _prepare()
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	var bar := player.get_node("CanvasLayer/ChokeProgress") as ProgressBar
	enemy.global_position = player.global_position + Vector2(200, 0)
	await _mouse(true)
	await create_timer(0.2).timeout
	check(not bar.visible, "distant knocked-down police cannot be choked")
	await _mouse(false)
	enemy.global_position = player.global_position + Vector2(36, 0)
	var wall := StaticBody2D.new()
	wall.position = player.global_position + Vector2(18, 0)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(8, 80)
	collision.shape = shape
	wall.add_child(collision)
	level.add_child(wall)
	await physics_frame
	await physics_frame
	await _mouse(true)
	await create_timer(0.2).timeout
	check(not bar.visible, "walls block choking even within arm's reach")
	await _mouse(false)
	wall.queue_free()
	await physics_frame
	await _mouse(true)
	await create_timer(0.4).timeout
	enemy.global_position = player.global_position + Vector2(200, 0)
	await physics_frame
	await physics_frame
	await process_frame
	check(not bar.visible and bar.value == 0, "losing reach cancels an active choke")
	await _finish(level)

func _test_opposing_movement_inputs_cancel() -> void:
	var level := await _prepare()
	await _mouse(true)
	await create_timer(0.3).timeout
	Input.action_press("move_left")
	Input.action_press("move_right")
	await physics_frame
	await physics_frame
	await process_frame
	check(not level.get_node("Player/CanvasLayer/ChokeProgress").visible,
		"opposing movement inputs still count as an attempt to move and cancel choking")
	await _finish(level)

func _test_recovery_cancels_choke() -> void:
	var level := await _prepare()
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	var old_scale := Engine.time_scale
	Engine.time_scale = 10.0
	await create_timer(13.4).timeout
	Engine.time_scale = old_scale
	await _mouse(true)
	await create_timer(3.1).timeout
	check(enemy.life_state == &"living" and not level.get_node("Player/CanvasLayer/ChokeProgress").visible,
		"a policeman who recovers before completion cannot be choked as a living target")
	await _finish(level)

func _test_target_removed_cancels() -> void:
	var level := await _prepare()
	await _mouse(true)
	await create_timer(0.2).timeout
	level.get_node("Enemies/Enemy1").queue_free()
	await process_frame
	await physics_frame
	await physics_frame
	await process_frame
	check(not level.get_node("Player/CanvasLayer/ChokeProgress").visible,
		"removing the target safely cancels active choking")
	await _finish(level)

func _test_lethal_damage_cancels() -> void:
	var level := await _prepare()
	await _mouse(true)
	await create_timer(0.2).timeout
	for hit in range(4):
		await _police_hit(level)
	var player := level.get_node("Player") as Player
	check(player.is_dead and not player.get_node("CanvasLayer/ChokeProgress").visible,
		"lethal damage ends the choke and hides its progress")
	await _finish(level)
