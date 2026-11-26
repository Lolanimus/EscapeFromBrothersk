extends SceneTree

const DEMO := preload("res://scenes/main.tscn")
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := DEMO.instantiate()
	root.add_child(level)
	current_scene = level
	var player := level.get_node("Player") as Player
	for police in get_nodes_in_group("police"):
		police.set_physics_process(false)
		police.get_node("Gun").set_physics_process(false)
	await _press("interact")
	_expect(player.active_weapon == &"katana" and not level.has_node("Pickups/Katana"),
		"E at the starting spawn acquires and equips the katana")
	var held_katana := player.get_node("AimPivot/HeldGun") as Sprite2D
	Input.action_press("move_right")
	await physics_frame
	await process_frame
	_expect(not held_katana.visible and player.skin.animation == &"walk_side",
		"walking with the katana uses the normal walk animation and hides the held blade")
	var walking_height := _visible_height(player.skin)
	Input.action_release("move_right")
	await physics_frame
	await process_frame
	_expect(not held_katana.visible, "the held katana stays hidden when the player stops")
	player.global_position = level.get_node("Pickups/Pistol").global_position
	await _press("interact")
	_expect(player.active_weapon == &"pistol", "E equips the nearby pistol")
	await _press("shoot")
	await _press_key(KEY_1)
	_expect(player.active_weapon == &"katana", "1 selects the carried katana")
	await _press_key(KEY_2)
	_expect(player.active_weapon == &"pistol" and player.get_loaded_rounds() == 11,
		"2 selects the carried pistol with its remaining rounds")
	await _press_key(KEY_1)
	player.get_node("Camera2D").enabled = false
	var first := level.get_node("Enemies/Enemy1") as Enemy
	var second := level.get_node("Enemies/Enemy2") as Enemy
	_expect(second.global_position == first.global_position + Vector2(40, 0),
		"the demo spawns the second policeman beside the first")
	player.global_position = first.global_position.lerp(second.global_position, 0.5) + Vector2(0, 42)
	player.take_police_projectile_hit()
	await _aim(player, Vector2.UP)
	await _press("shoot")
	_expect(first.life_state == &"dead" and second.life_state == &"dead",
		"one swing permanently kills two police in the forward rectangle")
	_expect(player.skin.animation == &"katana_up" and player.skin.is_playing(),
		"the swing plays the sprite animation facing the aim")
	_expect(absf(_visible_height(player.skin) - walking_height) < 10.0,
		"the visible slash pose stays close to the normal walking height")
	var slash_effect := player.get_node("KatanaSlashVFX") as AnimatedSprite2D
	_expect(slash_effect.visible and slash_effect.animation == player.skin.animation
		and slash_effect.frame == player.skin.frame and slash_effect.scale.is_equal_approx(Vector2(0.64, 0.64)),
		"the doubled slash VFX follows the pose frame")
	var motivation_bar := player.get_node("CanvasLayer/MotivationBar") as ProgressBar
	_expect(motivation_bar.value == 95, "two permanent swing kills restore 20 motivation")
	player.global_position = Vector2(303, 150)
	var blocked := _place_police(level, Vector2(368, 150))
	var clear := _place_police(level, Vector2(329, 168))
	await create_timer(0.5).timeout
	_expect(not slash_effect.visible, "the slash VFX disappears when the pose animation ends")
	await _aim(player, Vector2.RIGHT)
	await _press("shoot")
	_expect(blocked.life_state == &"living" and clear.life_state == &"dead",
		"a wall protects police behind it while an exposed target in the same swing dies")
	_expect(motivation_bar.value == 100, "swing kills cap motivation at 100")
	await create_timer(0.5).timeout
	player.global_position = Vector2(500, 300)
	player.katana_swing_cadence = 0.2
	var beyond_tip := _place_police(level, Vector2(595, 300))
	var beyond_side := _place_police(level, Vector2(520, 380))
	var behind := _place_police(level, Vector2(490, 300))
	var inside := _place_police(level, Vector2(510, 330))
	await _aim(player, Vector2.RIGHT)
	await _press("shoot")
	_expect(inside.life_state == &"dead" and beyond_tip.life_state == &"living"
		and beyond_side.life_state == &"living" and behind.life_state == &"living",
		"the rectangular VFX footprint hits beside the aim and stops at its edges")
	var next := _place_police(level, Vector2(539, 300))
	await _press("shoot")
	_expect(next.life_state == &"living", "a click during the swing cooldown has no effect")
	await create_timer(0.22).timeout
	await _press("shoot")
	_expect(next.life_state == &"dead", "a fresh click can swing after the configured cooldown")
	await create_timer(0.22).timeout
	# Keep both fixtures out of the automatic door's proximity detection until the first swing.
	player.collision_layer = 0
	player.global_position = Vector2(1220, 225)
	var beyond_door := _place_police(level, Vector2(1268, 225))
	beyond_door.collision_layer = 0
	await _aim(player, Vector2.RIGHT)
	await _press("shoot")
	_expect(beyond_door.life_state == &"living", "a closed automatic door blocks the swing")
	player.collision_layer = 2
	await create_timer(0.22).timeout
	await _aim(player, Vector2.RIGHT)
	await _press("shoot")
	_expect(beyond_door.life_state == &"dead", "the same target is exposed after the door opens")
	player.global_position = level.get_node("Pickups/Shotgun").global_position
	await _press("interact")
	await _press_key(KEY_1)
	var kept_katana := player.active_weapon == &"katana"
	await _press_key(KEY_2)
	_expect(player.active_weapon == &"shotgun" and player.get_loaded_rounds() == 6 and kept_katana,
		"replacing the pistol equips the shotgun and keeps the katana slot")
	await _press("interact")
	_expect(player.active_weapon == &"pistol" and player.get_loaded_rounds() == 11,
		"E picks the dropped pistol back up with its remaining 11 rounds")
	await _press("interact")
	_expect(player.active_weapon == &"shotgun" and player.get_loaded_rounds() == 6,
		"swapping back leaves the shotgun available with its loaded rounds")
	quit(failures)


func _place_police(level: Node, position: Vector2) -> Enemy:
	var policeman := level.get_node("Enemies/Enemy1").duplicate() as Enemy
	level.get_node("Enemies").add_child(policeman)
	policeman.set_physics_process(false)
	policeman.get_node("Gun").set_physics_process(false)
	policeman.global_position = position
	return policeman


func _visible_height(sprite: AnimatedSprite2D) -> float:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	return texture.get_image().get_used_rect().size.y * absf(sprite.scale.y)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await physics_frame
	await process_frame
	Input.action_release(action)
	await physics_frame
	await process_frame


func _press_key(key: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = key
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
		await physics_frame
		await process_frame


func _aim(player: Player, direction: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = root.get_screen_transform() * (
		player.get_global_transform_with_canvas().origin + direction * 250.0
	)
	event.global_position = event.position
	Input.parse_input_event(event)
	await process_frame


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
