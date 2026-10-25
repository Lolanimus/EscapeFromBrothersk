extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_opening_a_door_emits_once()

	if _failures == 0:
		print("PASS: automatic door feedback tests passed")
	else:
		push_error("FAIL: %d automatic door feedback test(s) failed" % _failures)

	quit(_failures)


func _test_opening_a_door_emits_once() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var doors := get_nodes_in_group("automatic_doors")
	var door: Node = doors[0] if not doors.is_empty() else null
	var player := level.get_node("Player") as CharacterBody2D
	var has_opened_signal := door != null and door.has_signal(&"opened")
	var opened_event_count := [0]
	if has_opened_signal:
		door.connect(&"opened", func() -> void: opened_event_count[0] += 1)

	Input.action_press("move_right")
	for frame in range(25):
		await physics_frame
	Input.action_release("move_right")
	var opened_after_approach := door != null and bool(door.get("is_open"))

	Input.action_press("move_left")
	for frame in range(30):
		await physics_frame
	Input.action_release("move_left")
	Input.action_press("move_right")
	for frame in range(30):
		await physics_frame
	Input.action_release("move_right")

	_expect(
		has_opened_signal
		and opened_after_approach
		and opened_event_count[0] == 1,
		"opening a door emits its public opened signal once, including after later approaches"
	)

	level.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return

	_failures += 1
	push_error("FAIL: %s" % message)
