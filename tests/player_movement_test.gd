extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	var player: Node2D = scene.get_node("Player")
	player.set_process(false)
	var cases := [
		[KEY_A, Vector2.LEFT], [KEY_LEFT, Vector2.LEFT],
		[KEY_D, Vector2.RIGHT], [KEY_RIGHT, Vector2.RIGHT],
		[KEY_W, Vector2.UP], [KEY_UP, Vector2.UP],
		[KEY_S, Vector2.DOWN], [KEY_DOWN, Vector2.DOWN],
	]
	var failures := 0
	for test_case in cases:
		player.position = Vector2(300, 300)
		var event := InputEventKey.new()
		event.device = 0
		event.physical_keycode = test_case[0]
		event.keycode = test_case[0]
		event.pressed = true
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		player._process(0.1)
		var expected: Vector2 = Vector2(300, 300) + test_case[1] * 28.0
		if not player.position.is_equal_approx(expected):
			printerr("Movement failed for key ", test_case[0], ": ", player.position, " expected ", expected)
			failures += 1
		event = event.duplicate()
		event.pressed = false
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	if failures == 0:
		print("PASS: all eight movement keys move the player correctly.")
	quit(1 if failures else 0)
