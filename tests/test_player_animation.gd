extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_horizontal_movement_animates_and_mirrors_the_player()
	await _test_vertical_movement_uses_available_front_and_rear_art()
	await _test_stationary_pose_matches_walking_size_and_shows_equipped_weapon()
	await _test_pistol_artwork_and_side_firing_animation_are_visible_in_gameplay()

	if _failures == 0:
		print("PASS: all player animation tests passed")
	else:
		push_error("FAIL: %d player animation test(s) failed" % _failures)

	quit(_failures)


func _test_horizontal_movement_animates_and_mirrors_the_player() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var skin := player.get_node_or_null("skin") as AnimatedSprite2D
	if skin == null:
		_expect(false, "horizontal movement uses an animated player sprite")
		level.queue_free()
		await process_frame
		return

	Input.action_press("move_left")
	await physics_frame
	var first_frame := skin.frame
	for frame in range(12):
		await physics_frame
	Input.action_release("move_left")
	var moved_through_frames := skin.frame != first_frame
	var faces_left_without_mirroring := not skin.flip_h

	Input.action_press("move_right")
	await physics_frame
	Input.action_release("move_right")

	_expect(
		skin.animation == &"walk_side"
		and skin.sprite_frames.get_frame_count(&"walk_side") == 3
		and moved_through_frames
		and faces_left_without_mirroring
		and skin.flip_h,
		"horizontal movement cycles through three side-facing frames and mirrors them when moving right"
	)

	level.queue_free()
	await process_frame


func _test_pistol_artwork_and_side_firing_animation_are_visible_in_gameplay() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var skin := player.get_node("skin") as AnimatedSprite2D
	var pistol_pickup := level.get_node("Pickups/Pistol") as Area2D
	var pickup_visual := pistol_pickup.get_node_or_null("Visual") as Sprite2D
	var pickup_uses_artwork := (
		pickup_visual != null
		and pickup_visual.texture != null
		and pickup_visual.texture.resource_path == "res://assets/sprites/weapon/Pistol.png"
	)
	var pickup_uses_nearest_filter := (
		pickup_visual != null
		and pickup_visual.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST
	)
	player.global_position = pistol_pickup.global_position
	await physics_frame
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")

	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300.0, 0.0)
	mouse_motion.global_position = mouse_motion.position
	Input.parse_input_event(mouse_motion)
	await process_frame
	Input.action_release("shoot")
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

	var played_side_fire_once := (
		skin.animation == &"fire_pistol_side"
		and skin.sprite_frames.has_animation(&"fire_pistol_side")
		and skin.sprite_frames.get_frame_count(&"fire_pistol_side") == 2
		and not skin.sprite_frames.get_animation_loop(&"fire_pistol_side")
		and skin.flip_h
	)
	var animation_during_fire := skin.animation
	var mirrored_during_fire := skin.flip_h
	var projectiles := get_nodes_in_group("player_projectiles")
	var projectile_uses_artwork := false
	var uses_consistent_pixel_filtering := false
	if projectiles.size() == 1:
		var projectile := projectiles[0] as Area2D
		var projectile_visual := projectile.get_node_or_null("Visual") as Sprite2D
		projectile_uses_artwork = (
			projectile_visual != null
			and projectile_visual.texture != null
			and projectile_visual.texture.resource_path == "res://assets/sprites/bullets/bullet.png"
		)
		uses_consistent_pixel_filtering = (
			skin.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST
			and pickup_uses_nearest_filter
			and projectile_visual.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST
		)
	for frame in range(20):
		await physics_frame
	var returned_to_idle := skin.animation == &"idle_pistol_side"

	_expect(
		pickup_uses_artwork
		and projectile_uses_artwork
		and uses_consistent_pixel_filtering
		and played_side_fire_once
		and returned_to_idle,
		"the pistol pickup and projectile use consistently filtered existing artwork, and right-facing fire animates once before returning to idle "
		+ "(during: %s, mirrored: %s, projectiles: %d, after: %s)" % [
			animation_during_fire,
			mirrored_during_fire,
			projectiles.size(),
			skin.animation,
		]
	)

	level.queue_free()
	await process_frame


func _test_stationary_pose_matches_walking_size_and_shows_equipped_weapon() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await physics_frame

	var player := level.get_node("Player") as CharacterBody2D
	var skin := player.get_node("skin") as AnimatedSprite2D
	var fists_texture := skin.sprite_frames.get_frame_texture(skin.animation, skin.frame)
	var shows_fists_while_standing := (
		skin.animation == &"idle_fists_side"
		and fists_texture != null
		and fists_texture.resource_path == "res://assets/sprites/main character/attack/1.png"
	)
	var standing_height := _visible_sprite_height(skin)

	Input.action_press("move_left")
	await physics_frame
	var walking_height := _visible_sprite_height(skin)
	Input.action_release("move_left")
	await physics_frame
	var sizes_match := absf(standing_height - walking_height) <= 2.0

	var pistol_pickup := level.get_node("Pickups/Pistol") as Area2D
	player.global_position = pistol_pickup.global_position
	await physics_frame
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")
	await physics_frame
	var pistol_texture := skin.sprite_frames.get_frame_texture(skin.animation, skin.frame)
	var shows_pistol_while_standing := (
		skin.animation == &"idle_pistol_side"
		and pistol_texture != null
		and pistol_texture.resource_path
		== "res://assets/sprites/main character/attack/pistol2.png"
	)

	_expect(
		shows_fists_while_standing and shows_pistol_while_standing and sizes_match,
		"stationary and walking sprites have the same visible height, and equipped fists or pistol remain visible "
		+ "(standing: %.1f, walking: %.1f, after pickup: %s)" % [
			standing_height,
			walking_height,
			skin.animation,
		]
	)

	level.queue_free()
	await process_frame


func _test_vertical_movement_uses_available_front_and_rear_art() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var skin := player.get_node("skin") as AnimatedSprite2D
	Input.action_press("move_up")
	await physics_frame
	var first_frame := skin.frame
	for frame in range(12):
		await physics_frame
	Input.action_release("move_up")
	var uses_rear_walk := (
		skin.animation == &"walk_up"
		and skin.sprite_frames.get_frame_count(&"walk_up") == 3
		and skin.frame != first_frame
	)
	var reference_walk_size := (
		_average_visible_animation_size(skin, &"walk_side")
		+ _average_visible_animation_size(skin, &"walk_up")
	) / 2.0

	Input.action_press("move_down")
	await physics_frame
	var first_down_frame := skin.frame
	var first_down_position := skin.position
	for frame in range(12):
		await physics_frame
	var down_texture := skin.sprite_frames.get_frame_texture(skin.animation, skin.frame)
	var down_visible_size := _visible_sprite_size(skin)
	var uses_front_walk := (
		skin.animation == &"walk_down"
		and skin.sprite_frames.get_frame_count(&"walk_down") == 2
		and skin.is_playing()
		and skin.frame != first_down_frame
		and skin.position != first_down_position
		and down_texture != null
		and down_texture.resource_path == "res://assets/sprites/main character/Player.png"
	)
	var matches_other_walking_sprite_size := (
		down_visible_size.distance_to(reference_walk_size) < 2.0
	)
	Input.action_release("move_down")

	_expect(
		uses_rear_walk and uses_front_walk and matches_other_walking_sprite_size,
		"downward movement animates the front-facing character at the average visible size of the other walking sprites "
		+ "(other walks: %s, down: %s)" % [reference_walk_size, down_visible_size]
	)

	level.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failures += 1
	push_error("FAIL: %s" % message)


func _visible_sprite_height(sprite: AnimatedSprite2D) -> float:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return 0.0
	var visible_rect := texture.get_image().get_used_rect()
	return visible_rect.size.y * absf(sprite.scale.y)


func _visible_sprite_size(sprite: AnimatedSprite2D) -> Vector2:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return Vector2.ZERO
	return Vector2(texture.get_image().get_used_rect().size) * sprite.scale.abs()


func _average_visible_animation_size(
	sprite: AnimatedSprite2D, animation_name: StringName
) -> Vector2:
	var total := Vector2.ZERO
	var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
	for frame_index in range(frame_count):
		var texture := sprite.sprite_frames.get_frame_texture(animation_name, frame_index)
		total += Vector2(texture.get_image().get_used_rect().size) * sprite.scale.abs()
	return total / frame_count
