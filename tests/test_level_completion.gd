extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var police := level.get_node("Enemies/Enemy1") as Enemy
	police.set_physics_process(false)
	var sign := level.get_node_or_null("Prison/ExitStatus") as Label
	check(sign != null, "exit has visible objective status")
	if sign == null:
		level.queue_free()
		await process_frame
		quit(failures)
		return
	check(sign.text == "EXIT LOCKED", "living police lock the exit")
	var player := level.get_node("Player") as Player
	player.global_position = Vector2(1600, 875)
	Input.action_press("move_right")
	for frame in range(30):
		await physics_frame
	Input.action_release("move_right")
	check(player.global_position.x < 1640, "locked exit physically blocks departure")
	var other := police.duplicate() as Enemy
	level.get_node("Enemies").add_child(other)
	other.set_physics_process(false)
	police.knock_down()
	await physics_frame
	await physics_frame
	check(sign.text == "EXIT LOCKED", "unconscious police still lock the exit")
	police.kill_permanently()
	await physics_frame
	await physics_frame
	check(sign.text == "EXIT LOCKED", "one surviving policeman prevents unlock")
	other.kill_permanently()
	await physics_frame
	await physics_frame
	check(sign.text == "EXIT OPEN", "permanent elimination unlocks the exit")
	Input.action_press("move_right")
	for frame in range(30):
		await physics_frame
	Input.action_release("move_right")
	var overlay := level.get_node_or_null("CompletionLayer/LevelComplete") as Control
	check(overlay != null and overlay.visible, "leaving displays Level Complete")
	var position_before := player.global_position
	Input.action_press("move_right")
	for frame in range(4):
		await physics_frame
	Input.action_release("move_right")
	check(player.global_position == position_before, "completion stops normal gameplay")
	var motion := InputEventMouseMotion.new()
	root.push_input(motion)
	await process_frame
	check(current_scene == level, "mouse motion does not dismiss completion")
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	root.push_input(key)
	for frame in range(4):
		await process_frame
	check(current_scene != level and current_scene.scene_file_path == "res://scenes/next_level.tscn",
		"fresh input loads the configured placeholder next level")
	current_scene.queue_free()
	await process_frame
	# Configure a different real scene to prove progression is not hard-coded.
	level = GameplayScene.instantiate()
	level.next_level_scene = load("res://scenes/main_menu.tscn")
	root.add_child(level)
	current_scene = level
	await process_frame
	level.get_node("Enemies/Enemy1").kill_permanently()
	level.get_node("Player").global_position = Vector2(1680, 875)
	for frame in range(4):
		await physics_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	root.push_input(click)
	for frame in range(4):
		await process_frame
	check(current_scene.scene_file_path == "res://scenes/main_menu.tscn",
		"mouse click loads an alternative configured scene")
	current_scene.queue_free()
	await process_frame
	quit(failures)

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
