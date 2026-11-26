extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_side_punch_plays_three_frame_side_attack_mirrored_by_facing()
	await _test_upward_punch_plays_three_frame_rear_attack()
	await _test_punch_returns_to_idle_presentation_after_playing_once()
	await _test_punch_while_walking_returns_to_walking_presentation()
	await _test_punch_animation_does_not_delay_knockdown_or_follow_up_punches()
	if _failures == 0:
		print("PASS: all fist attack animation tests passed")
	else:
		push_error("FAIL: %d fist attack animation test(s) failed" % _failures)
	quit(_failures)


func _test_side_punch_plays_three_frame_side_attack_mirrored_by_facing() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as CharacterBody2D
	var skin := player.get_node("skin") as AnimatedSprite2D

	await _aim(player, Vector2(300.0, 0.0))
	await _click()
	var right_animation := skin.animation
	var right_playing := skin.is_playing()
	var right_flipped := skin.flip_h
	await _release_click()
	for frame in range(30):
		await physics_frame

	await _aim(player, Vector2(-300.0, 0.0))
	await _click()
	var left_animation := skin.animation
	var left_flipped := skin.flip_h
	await _release_click()

	var frames := skin.sprite_frames
	_expect(
		right_animation == &"punch_side" and right_playing and right_flipped
		and left_animation == &"punch_side" and not left_flipped
		and frames.has_animation(&"punch_side")
		and frames.get_frame_count(&"punch_side") == 3
		and not frames.get_animation_loop(&"punch_side"),
		"an unarmed left click plays the three-frame side punch once, mirrored toward the aimed side "
		+ "(right: %s flip %s, left: %s flip %s)" % [right_animation, right_flipped, left_animation, left_flipped]
	)
	await _finish(level)


func _test_upward_punch_plays_three_frame_rear_attack() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as CharacterBody2D
	var skin := player.get_node("skin") as AnimatedSprite2D

	await _aim(player, Vector2(40.0, -300.0))
	await _click()
	var animation := skin.animation
	var playing := skin.is_playing()
	var flipped := skin.flip_h
	await _release_click()

	var frames := skin.sprite_frames
	_expect(
		animation == &"punch_up" and playing and not flipped
		and frames.has_animation(&"punch_up")
		and frames.get_frame_count(&"punch_up") == 3
		and not frames.get_animation_loop(&"punch_up"),
		"an unarmed left click aimed upward plays the unmirrored three-frame rear punch once "
		+ "(animation: %s, flip: %s)" % [animation, flipped]
	)
	await _finish(level)


func _test_punch_returns_to_idle_presentation_after_playing_once() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as CharacterBody2D
	var skin := player.get_node("skin") as AnimatedSprite2D

	await _aim(player, Vector2(300.0, 0.0))
	await _click()
	await _release_click()
	var during := skin.animation
	var finished := [0]
	skin.animation_finished.connect(func() -> void: finished[0] += 1)
	for frame in range(40):
		await physics_frame

	_expect(
		during == &"punch_side" and finished[0] == 1
		and skin.animation == &"idle_fists_side" and not skin.is_playing() and skin.flip_h,
		"a stationary punch plays once and returns to the right-facing fists idle pose "
		+ "(during: %s, finished: %d, now: %s, playing: %s, flip: %s)" % [during, finished[0], skin.animation, skin.is_playing(), skin.flip_h]
	)
	await _finish(level)


func _test_punch_while_walking_returns_to_walking_presentation() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as CharacterBody2D
	var skin := player.get_node("skin") as AnimatedSprite2D
	player.set("speed", 1.0)

	await _aim(player, Vector2(300.0, 0.0))
	Input.action_press("move_left")
	await physics_frame
	await physics_frame
	await _click()
	var during := skin.animation
	await _release_click()
	for frame in range(40):
		await physics_frame
	var after := skin.animation
	var after_playing := skin.is_playing()
	var after_flipped := skin.flip_h
	Input.action_release("move_left")

	_expect(
		during == &"punch_side" and after == &"walk_side" and after_playing and not after_flipped,
		"a punch while walking left returns to the left-facing walk cycle "
		+ "(during: %s, after: %s, playing: %s, flip: %s)" % [during, after, after_playing, after_flipped]
	)
	await _finish(level)


func _test_punch_animation_does_not_delay_knockdown_or_follow_up_punches() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as CharacterBody2D
	var skin := player.get_node("skin") as AnimatedSprite2D
	var first := level.get_node("Enemies/Enemy1") as CharacterBody2D
	var second := first.duplicate() as CharacterBody2D
	first.get_parent().add_child(second)
	second.set("speed", 0.0)
	await process_frame
	first.global_position = player.global_position + Vector2(36.0, 0.0)
	second.global_position = player.global_position + Vector2(0.0, -5000.0)

	await _aim(player, Vector2(300.0, 0.0))
	await _click()
	var first_down_on_click: bool = first.get("life_state") == &"knocked_down"
	var first_animation := skin.animation
	await _release_click()

	# Swap in a fresh living target while the first punch sequence is still playing.
	second.global_position = player.global_position + Vector2(36.0, 0.0)
	first.global_position = player.global_position + Vector2(0.0, -5000.0)
	var mid_sequence := skin.is_playing() and skin.animation == &"punch_side"
	await _click()
	var second_down_on_click: bool = second.get("life_state") == &"knocked_down"
	await _release_click()

	_expect(
		first_down_on_click and first_animation == &"punch_side"
		and mid_sequence and second_down_on_click,
		"punch knockdowns happen on the click frame and a follow-up punch mid-animation still lands "
		+ "(first: %s, anim: %s, mid: %s, second: %s)" % [first_down_on_click, first_animation, mid_sequence, second_down_on_click]
	)
	await _finish(level)


func _start_level() -> Node:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as CharacterBody2D
	player.set("speed", 0.0)
	for enemy in level.get_tree().get_nodes_in_group("police"):
		enemy.set("speed", 0.0)
	return level


func _aim(player: CharacterBody2D, offset: Vector2) -> void:
	var cursor_position: Vector2 = player.get_global_transform_with_canvas() * Vector2.ZERO + offset
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = cursor_position
	mouse_motion.global_position = cursor_position
	player.get_viewport().push_input(mouse_motion, true)
	await process_frame


func _click() -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	# physics_frame is emitted before nodes run _physics_process, so wait for one full step.
	await physics_frame
	await physics_frame


func _release_click() -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	Input.parse_input_event(click)
	await physics_frame


func _finish(level: Node) -> void:
	level.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failures += 1
	push_error("FAIL: %s" % message)
