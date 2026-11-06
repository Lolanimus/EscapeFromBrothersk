extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
const PoliceBullet := preload("res://scenes/enemy_projectile.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as Player
	level.get_node("Enemies/Enemy1").set_physics_process(false)
	var button := player.get_node_or_null("CanvasLayer/RestartButton") as Button
	check(button != null and not button.visible, "restart button stays hidden while alive")
	if button == null:
		level.queue_free()
		await process_frame
		quit(failures)
		return
	player.global_position = level.get_node("Pickups/Pistol").global_position
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	check(player.active_weapon == &"pistol", "player acquires a gun before retry")
	for hit in range(4):
		var bullet := PoliceBullet.instantiate()
		bullet.speed = 0.0
		level.add_child(bullet)
		bullet.global_position = player.global_position
		for frame in range(4):
			await physics_frame
	await process_frame
	check(player.is_dead and button.visible and button.text == "Restart level",
		"death displays a restart-level button")
	var previous_instance := level.get_instance_id()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = button.get_global_rect().get_center()
	click.global_position = click.position
	click.pressed = true
	root.push_input(click, true)
	await process_frame
	click.pressed = false
	root.push_input(click, true)
	for frame in range(4):
		await process_frame
	check(current_scene != null and current_scene.get_instance_id() != previous_instance
		and current_scene.scene_file_path == "res://scenes/main.tscn",
		"restart button reloads the current level instead of opening the menu")
	var restarted_player := current_scene.get_node("Player") as Player
	check(not restarted_player.is_dead and restarted_player.motivation == 100
		and restarted_player.global_position.is_equal_approx(Vector2(225, 225))
		and restarted_player.active_weapon == &"fists"
		and current_scene.has_node("Pickups/Pistol")
		and current_scene.get_node("Enemies/Enemy1").life_state == &"living",
		"retry restores the beginning of the level with full motivation, fists, pickups and police")
	current_scene.queue_free()
	await process_frame
	quit(failures)

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
