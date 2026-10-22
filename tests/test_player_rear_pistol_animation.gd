extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var skin := player.get_node("skin") as AnimatedSprite2D
	var pistol_pickup := level.get_node("Pickups/Pistol") as Area2D
	player.set("speed", 0.0)
	player.set("pistol_projectile_speed", 0.0)
	player.global_position = pistol_pickup.global_position
	await physics_frame
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")

	var mouse_motion := InputEventMouseMotion.new()
	var player_viewport_position := player.get_global_transform_with_canvas() * Vector2.ZERO
	mouse_motion.position = player_viewport_position + Vector2(0.0, -300.0)
	mouse_motion.global_position = mouse_motion.position
	level.get_viewport().push_input(mouse_motion, true)
	var aim_rotation := (player.get_node("AimPivot") as Node2D).global_rotation
	Input.action_press("move_up")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	await physics_frame
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = mouse_motion.position
	click.global_position = mouse_motion.global_position
	click.pressed = false
	Input.parse_input_event(click)

	var played_rear_fire_once := (
		skin.animation == &"fire_pistol_up"
		and skin.sprite_frames.has_animation(&"fire_pistol_up")
		and skin.sprite_frames.get_frame_count(&"fire_pistol_up") == 2
		and not skin.sprite_frames.get_animation_loop(&"fire_pistol_up")
		and not skin.flip_h
	)
	var animation_during_fire := skin.animation
	var projectiles := get_nodes_in_group("player_projectiles")
	var spawned_from_rear_barrel := false
	if projectiles.size() == 1:
		var projectile := projectiles[0] as Node2D
		spawned_from_rear_barrel = projectile.global_position.distance_to(
			player.global_position + Vector2(11.0, -16.0)
		) < 0.1
	for frame in range(20):
		await physics_frame
	var returned_to_upward_walk := skin.animation == &"walk_up" and skin.is_playing()
	Input.action_release("move_up")

	_expect(
		played_rear_fire_once and spawned_from_rear_barrel and returned_to_upward_walk,
		"upward pistol fire starts at the rear-view barrel, plays once, and returns to upward walking "
		+ "(player viewport: %s, event: %s, aim: %s, during: %s, after: %s)" % [
			player_viewport_position,
			mouse_motion.position,
			aim_rotation,
			animation_during_fire,
			skin.animation,
		]
	)

	level.queue_free()
	await process_frame
	if _failures == 0:
		print("PASS: rear pistol animation test passed")
	else:
		push_error("FAIL: rear pistol animation test failed")
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failures += 1
	push_error("FAIL: %s" % message)
