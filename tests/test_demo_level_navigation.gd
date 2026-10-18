extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_player_cannot_walk_through_a_wall()
	await _test_camera_shifts_toward_the_mouse_cursor()
	await _test_player_can_move_through_another_character()
	await _test_player_body_stays_static_while_active_weapon_aims_at_cursor()
	await _test_player_starts_unarmed_with_fists_active()
	await _test_camera_eases_toward_its_mouse_look_ahead()
	await _test_player_and_camera_can_travel_beyond_the_initial_viewport()
	await _test_player_starts_inside_a_cell_with_solid_walls()
	await _test_player_can_leave_the_cell_for_the_cell_block()
	await _test_player_can_reach_the_guard_office_from_the_cell_block()
	await _test_player_can_reach_storage_from_the_guard_office()
	await _test_player_can_enter_the_central_corridor_from_storage()
	await _test_player_can_reach_the_exercise_yard_from_the_corridor()
	await _test_player_can_reach_the_exit_from_the_exercise_yard()
	await _test_player_can_use_the_alternate_side_passage_to_the_yard()
	await _test_prison_contains_exactly_the_seven_selected_rooms()

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
	enemy.global_position = player.global_position + Vector2(80.0, 0.0)
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


func _test_player_body_stays_static_while_active_weapon_aims_at_cursor() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var aim_pivot := player.get_node_or_null("AimPivot") as Node2D
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = level.get_viewport().get_screen_transform() * Vector2(576.0, 100.0)
	mouse_motion.global_position = mouse_motion.position
	Input.parse_input_event(mouse_motion)
	await process_frame

	_expect(
		is_zero_approx(player.rotation)
		and aim_pivot != null
		and aim_pivot.rotation < -1.0
		and aim_pivot.rotation > -2.0,
		"the player body stays static while the active weapon aims toward the cursor"
	)

	level.queue_free()
	await process_frame


func _test_player_starts_unarmed_with_fists_active() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	_expect(
		player.get("active_weapon") == &"fists",
		"the player starts unarmed with fists active"
	)

	level.queue_free()
	await process_frame


func _test_camera_eases_toward_its_mouse_look_ahead() -> void:
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
	await process_frame
	var far_cursor_offset: float = camera.offset.x
	var maximum_offset: float = float(camera.get("look_ahead_distance"))

	level.queue_free()
	await process_frame

	level = GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	player = level.get_node("Player") as CharacterBody2D
	camera = player.get_node("Camera2D") as Camera2D
	mouse_motion = InputEventMouseMotion.new()
	mouse_motion.position = level.get_viewport().get_screen_transform() * Vector2(596.0, 324.0)
	mouse_motion.global_position = mouse_motion.position
	Input.parse_input_event(mouse_motion)
	await process_frame
	await process_frame
	var near_cursor_offset: float = camera.offset.x

	_expect(
		near_cursor_offset > 0.0
		and far_cursor_offset > near_cursor_offset
		and far_cursor_offset < maximum_offset,
		"camera movement is gentler near the player and eases toward distant look-ahead"
	)

	level.queue_free()
	await process_frame


func _test_player_and_camera_can_travel_beyond_the_initial_viewport() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var camera := player.get_node("Camera2D") as Camera2D
	var initial_viewport_width: float = level.get_viewport_rect().size.x

	Input.action_press("move_right")
	for frame in range(240):
		await physics_frame
	Input.action_release("move_right")

	_expect(
		player.global_position.x > initial_viewport_width
		and is_equal_approx(camera.global_position.x, player.global_position.x),
		"the player and following camera can travel beyond the initial viewport"
	)

	level.queue_free()
	await process_frame


func _test_player_starts_inside_a_cell_with_solid_walls() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var starts_in_cell: bool = (
		level.has_method("get_area_id_at")
		and level.call("get_area_id_at", player.global_position) == &"starting_cell"
	)

	Input.action_press("move_up")
	for frame in range(40):
		await physics_frame
	Input.action_release("move_up")

	_expect(
		starts_in_cell and player.global_position.y > 120.0,
		"the player starts in the prison cell and its solid wall blocks movement"
	)

	level.queue_free()
	await process_frame


func _test_player_can_leave_the_cell_for_the_cell_block() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	Input.action_press("move_right")
	for frame in range(70):
		await physics_frame
	Input.action_release("move_right")

	_expect(
		level.call("get_area_id_at", player.global_position) == &"cell_block",
		"the player can leave the starting cell through its doorway for the cell block"
	)

	level.queue_free()
	await process_frame


func _test_player_can_reach_the_guard_office_from_the_cell_block() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	Input.action_press("move_right")
	for frame in range(170):
		await physics_frame
	Input.action_release("move_right")

	_expect(
		level.call("get_area_id_at", player.global_position) == &"guard_office",
		"the player can continue from the cell block into the guard office"
	)

	level.queue_free()
	await process_frame


func _test_player_can_reach_storage_from_the_guard_office() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	Input.action_press("move_right")
	for frame in range(250):
		await physics_frame
	Input.action_release("move_right")

	_expect(
		level.call("get_area_id_at", player.global_position) == &"storage",
		"the player can enter storage through the guard office"
	)

	level.queue_free()
	await process_frame


func _test_player_can_enter_the_central_corridor_from_storage() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	Input.action_press("move_right")
	for frame in range(270):
		await physics_frame
	Input.action_release("move_right")

	Input.action_press("move_down")
	for frame in range(60):
		await physics_frame
	Input.action_release("move_down")

	_expect(
		level.call("get_area_id_at", player.global_position) == &"central_corridor",
		"the player can enter the central corridor through storage"
	)

	level.queue_free()
	await process_frame


func _test_player_can_reach_the_exercise_yard_from_the_corridor() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	Input.action_press("move_right")
	for frame in range(270):
		await physics_frame
	Input.action_release("move_right")
	Input.action_press("move_down")
	for frame in range(60):
		await physics_frame
	Input.action_release("move_down")
	Input.action_press("move_left")
	for frame in range(83):
		await physics_frame
	Input.action_release("move_left")
	Input.action_press("move_down")
	for frame in range(70):
		await physics_frame
	Input.action_release("move_down")

	_expect(
		level.call("get_area_id_at", player.global_position) == &"exercise_yard",
		"the player can enter the exercise yard from the central corridor"
	)

	level.queue_free()
	await process_frame


func _test_player_can_reach_the_exit_from_the_exercise_yard() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	Input.action_press("move_right")
	for frame in range(270):
		await physics_frame
	Input.action_release("move_right")
	Input.action_press("move_down")
	for frame in range(60):
		await physics_frame
	Input.action_release("move_down")
	Input.action_press("move_left")
	for frame in range(83):
		await physics_frame
	Input.action_release("move_left")
	Input.action_press("move_down")
	for frame in range(74):
		await physics_frame
	Input.action_release("move_down")
	Input.action_press("move_right")
	for frame in range(100):
		await physics_frame
	Input.action_release("move_right")

	var final_area: StringName = level.call("get_area_id_at", player.global_position)
	_expect(
		final_area == &"exit",
		"the player can reach the exit room from the exercise yard (position: %s, area: %s)"
		% [player.global_position, final_area]
	)

	level.queue_free()
	await process_frame


func _test_player_can_use_the_alternate_side_passage_to_the_yard() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	Input.action_press("move_right")
	for frame in range(80):
		await physics_frame
	Input.action_release("move_right")
	Input.action_press("move_down")
	for frame in range(105):
		await physics_frame
	Input.action_release("move_down")
	var entered_passage: bool = (
		level.call("get_area_id_at", player.global_position) == &"alternate_passage"
	)
	Input.action_press("move_right")
	for frame in range(70):
		await physics_frame
	Input.action_release("move_right")

	_expect(
		entered_passage
		and level.call("get_area_id_at", player.global_position) == &"exercise_yard",
		"the alternate side passage connects the cell block to the exercise yard"
	)

	level.queue_free()
	await process_frame


func _test_prison_contains_exactly_the_seven_selected_rooms() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var expected_rooms: Array[StringName] = [
		&"starting_cell",
		&"cell_block",
		&"guard_office",
		&"storage",
		&"central_corridor",
		&"exercise_yard",
		&"exit",
	]
	var actual_rooms: Array = []
	if level.has_method("get_room_ids"):
		actual_rooms = level.call("get_room_ids")
	var contains_exact_rooms := actual_rooms.size() == expected_rooms.size()
	for room_id: StringName in expected_rooms:
		contains_exact_rooms = contains_exact_rooms and room_id in actual_rooms

	_expect(
		contains_exact_rooms,
		"the prison contains exactly the seven selected rooms"
	)

	level.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return

	_failures += 1
	push_error("FAIL: %s" % message)
