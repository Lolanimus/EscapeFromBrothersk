extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_player_cannot_walk_through_a_wall()
	await _test_camera_shifts_toward_the_mouse_cursor()
	await _test_player_can_move_through_another_character()
	await _test_player_aims_toward_the_mouse_cursor()

	if _failures == 0:
		print("PASS: all demo-level navigation tests passed")
	else:
		push_error("FAIL: %d demo-level navigation test(s) failed" % _failures)

	quit(_failures)


func _test_player_cannot_walk_through_a_wall() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var wall := StaticBody2D.new()
	wall.position = player.position + Vector2(80.0, 0.0)

	var wall_collision := CollisionShape2D.new()
	var wall_shape := RectangleShape2D.new()
	wall_shape.size = Vector2(20.0, 200.0)
	wall_collision.shape = wall_shape
	wall.add_child(wall_collision)
	level.add_child(wall)
	await physics_frame

	Input.action_press("move_right")
	for frame in range(45):
		await physics_frame
	Input.action_release("move_right")

	_expect(
		player.global_position.x < wall.global_position.x,
		"the player remains on the near side of a wall while moving toward it"
	)

	level.queue_free()
	await process_frame


func _test_camera_shifts_toward_the_mouse_cursor() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var camera := player.get_node("Camera2D") as Camera2D
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = level.get_viewport().get_screen_transform() * Vector2(900.0, 324.0)
	mouse_motion.global_position = mouse_motion.position
	Input.parse_input_event(mouse_motion)
	await process_frame

	_expect(
		camera.offset.x > 0.0,
		"the camera shifts right when the mouse cursor is right of the player"
	)

	level.queue_free()
	await process_frame


func _test_player_can_move_through_another_character() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var enemy := level.get_node("Enemies/Enemy1") as CharacterBody2D
	enemy.speed = 0.0
	await physics_frame

	Input.action_press("move_right")
	for frame in range(45):
		await physics_frame
	Input.action_release("move_right")

	_expect(
		player.global_position.x > enemy.global_position.x,
		"the player can move through another character without being blocked"
	)

	level.queue_free()
	await process_frame


func _test_player_aims_toward_the_mouse_cursor() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = level.get_viewport().get_screen_transform() * Vector2(576.0, 100.0)
	mouse_motion.global_position = mouse_motion.position
	Input.parse_input_event(mouse_motion)
	await process_frame

	_expect(
		player.rotation < -1.0 and player.rotation > -2.0,
		"the player aims upward when the mouse cursor is above the player (rotation: %s)" % player.rotation
	)

	level.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return

	_failures += 1
	push_error("FAIL: %s" % message)
