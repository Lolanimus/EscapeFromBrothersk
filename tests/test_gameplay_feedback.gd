extends SceneTree
## Story 20: HUD, placeholder visuals, and audio cues observed through the real gameplay scene.
## Audio is judged only by which cue fired, never by how it sounds.

const GameplayScene := preload("res://scenes/main.tscn")
const PoliceBullet := preload("res://scenes/enemy_projectile.tscn")
const FeedbackAudio := preload("res://scripts/feedback_audio.gd")
const REQUIRED_CUES: Array[StringName] = [
	&"pistol_fire", &"shotgun_fire", &"ak47_fire", &"empty_click", &"reload",
	&"weapon_pickup", &"magazine_pickup", &"thrown_impact", &"punch", &"katana_swing",
	&"knockout", &"choking", &"detection", &"player_death", &"level_complete", &"door_open",
]

var _failures := 0
var _cues: Array[StringName] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_every_cue_has_a_distinct_generated_tone()
	await _test_gun_fire_pickup_reload_and_empty_cues()
	await _test_shotgun_and_ak47_fire_cues()
	await _test_katana_pickup_and_swing_cues()
	await _test_thrown_impact_cue()
	await _test_punch_knockout_and_choking_cues()
	await _test_detection_cue()
	await _test_door_open_cue()
	await _test_player_death_cue_and_cursor_release()
	await _test_level_complete_cue_overlay_and_cursor_release()
	await _test_hud_shows_weapons_rounds_and_magazine_limits()
	await _test_crosshair_follows_the_mouse()
	await _test_placeholder_visuals()
	if _failures == 0:
		print("PASS: all gameplay feedback tests passed")
	else:
		push_error("FAIL: %d gameplay feedback test(s) failed" % _failures)
	quit(_failures)


func _test_every_cue_has_a_distinct_generated_tone() -> void:
	var seen: Array[PackedByteArray] = []
	var all_distinct := true
	for cue in REQUIRED_CUES:
		var stream := FeedbackAudio.stream_for(cue)
		if stream == null or stream.data.is_empty() or stream.get_length() <= 0.0 or stream.get_length() > 1.0:
			all_distinct = false
			continue
		if seen.has(stream.data):
			all_distinct = false
		seen.append(stream.data)
	_expect(all_distinct and seen.size() == REQUIRED_CUES.size(),
		"every required cue has its own short, distinct generated placeholder tone")


func _test_gun_fire_pickup_reload_and_empty_cues() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	player.pistol_projectile_speed = 0.0
	player.global_position = level.get_node("Pickups/Pistol").global_position
	await _press("interact")
	_expect_cue(&"weapon_pickup", "E on the pistol plays the weapon pickup cue")
	_cues.clear()
	await _press("shoot")
	_expect_cue(&"pistol_fire", "firing the pistol plays the pistol shot cue")
	player.global_position = (level.get_node("PistolMagazine/Area2D") as Node2D).global_position
	_cues.clear()
	await _press("interact")
	_expect_cue(&"magazine_pickup", "E on a magazine plays the magazine pickup cue")
	_cues.clear()
	await _press("reload")
	_expect_cue(&"reload", "R with a retained magazine plays the reload cue")
	player.pistol_bullet = 0
	await physics_frame
	_cues.clear()
	await _press("shoot")
	_expect(_cues == [&"empty_click"], "firing an empty pistol plays only the empty-gun click: %s" % [_cues])
	await _finish_level(level)


func _test_shotgun_and_ak47_fire_cues() -> void:
	for weapon in [["Shotgun", &"shotgun_fire"], ["AK47", &"ak47_fire"]]:
		var level := await _start_level()
		var player := level.get_node("Player") as Player
		player.shotgun_projectile_speed = 0.0
		player.ak47_projectile_speed = 0.0
		player.global_position = level.get_node("Pickups/" + weapon[0]).global_position
		await _press("interact")
		_cues.clear()
		await _press("shoot")
		_expect_cue(weapon[1], "firing the %s plays its own shot cue" % weapon[0])
		await _finish_level(level)


func _test_katana_pickup_and_swing_cues() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	await _press("interact")
	_expect(player.active_weapon == &"katana" and _cues.has(&"weapon_pickup"),
		"E on the katana plays the weapon pickup cue")
	_cues.clear()
	await _press("shoot")
	_expect_cue(&"katana_swing", "left click with the katana plays the swing cue")
	await _finish_level(level)


func _test_thrown_impact_cue() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	player.global_position = level.get_node("Pickups/Pistol").global_position
	await _press("interact")
	player.global_position = Vector2(550, 350)
	await physics_frame
	await _aim(player, Vector2.RIGHT)
	_cues.clear()
	await _click(MOUSE_BUTTON_RIGHT)
	_expect(not _cues.has(&"thrown_impact"), "a thrown gun is silent until it lands")
	await create_timer(0.6).timeout
	_expect_cue(&"thrown_impact", "a thrown gun hitting the wall plays the impact cue")
	await _finish_level(level)


func _test_punch_knockout_and_choking_cues() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	enemy.global_position = player.global_position + Vector2(36, 0)
	await _aim(player, Vector2.RIGHT)
	_cues.clear()
	await _click(MOUSE_BUTTON_LEFT)
	_expect(enemy.life_state == &"knocked_down" and _cues.has(&"punch") and _cues.has(&"knockout"),
		"a punch that downs a policeman plays the punch and knockout cues: %s" % [_cues])
	_cues.clear()
	await _mouse(MOUSE_BUTTON_LEFT, true)
	for frame in range(6):
		await physics_frame
	var progress := player.get_node("CanvasLayer/ChokeProgress") as ProgressBar
	await process_frame
	_expect(_cues.count(&"choking") == 1 and progress.visible and progress.value > 0.0,
		"holding left click on the downed policeman plays the choking cue once and shows choke progress")
	await _mouse(MOUSE_BUTTON_LEFT, false)
	await _finish_level(level)


func _test_detection_cue() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	(enemy.get_node("Gun") as Node).set_physics_process(false)
	player.global_position = enemy.global_position + Vector2(0, -90)
	_cues.clear()
	enemy.set_physics_process(true)
	for frame in range(4):
		await physics_frame
	_expect(enemy.is_alerted and _cues.count(&"detection") == 1,
		"a policeman seeing the player plays the detection cue once")
	await _finish_level(level)


func _test_door_open_cue() -> void:
	var level := await _start_level()
	Input.action_press("move_right")
	for frame in range(25):
		await physics_frame
	Input.action_release("move_right")
	_expect_cue(&"door_open", "walking into an automatic door plays the door opening cue")
	await _finish_level(level)


func _test_player_death_cue_and_cursor_release() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	var crosshair := player.get_node_or_null("CanvasLayer/Crosshair") as CanvasItem
	_expect(crosshair != null and crosshair.visible, "the crosshair is shown during gameplay")
	for hit in range(4):
		var bullet := PoliceBullet.instantiate()
		bullet.speed = 0.0
		level.add_child(bullet)
		bullet.global_position = player.global_position
		for frame in range(4):
			await physics_frame
	await process_frame
	_expect(player.is_dead and _cues.count(&"player_death") == 1,
		"the lethal police hit plays the player death cue once")
	_expect(crosshair != null and not crosshair.visible,
		"the death screen hides the crosshair so the restart button uses the normal cursor")
	await _finish_level(level)


func _test_level_complete_cue_overlay_and_cursor_release() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	(level.get_node("Enemies/Enemy1") as Enemy).kill_permanently()
	await physics_frame
	await physics_frame
	player.global_position = Vector2(1600, 875)
	_cues.clear()
	Input.action_press("move_right")
	for frame in range(30):
		await physics_frame
	Input.action_release("move_right")
	await process_frame
	var overlay := level.get_node_or_null("CompletionLayer/LevelComplete") as Control
	var crosshair := player.get_node_or_null("CanvasLayer/Crosshair") as CanvasItem
	_expect(level.level_complete and overlay != null and overlay.visible and _cues.count(&"level_complete") == 1,
		"leaving through the open exit shows Level Complete and plays the completion cue once")
	_expect(crosshair != null and not crosshair.visible,
		"the Level Complete overlay hides the crosshair and returns the normal cursor")
	var feedback := level.get_node("FeedbackAudio")
	_expect(feedback.can_process(), "cue playback keeps running while gameplay is stopped by Level Complete")
	await _finish_level(level)


func _test_hud_shows_weapons_rounds_and_magazine_limits() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	player.global_position = level.get_node("Pickups/Pistol").global_position
	await _press("interact")
	player.global_position = (level.get_node("PistolMagazine/Area2D") as Node2D).global_position
	await _press("interact")
	await process_frame
	var hud := player.stats_label.text
	_expect(hud.contains("Active: pistol") and hud.contains("1  Fists    2  Pistol")
		and hud.contains("Loaded: 12/12"),
		"the HUD shows the active and carried weapons and the loaded rounds:\n%s" % hud)
	_expect(hud.contains("Pistol magazines: 1/4") and hud.contains("Shotgun magazines: 0/4")
		and hud.contains("AK-47 magazines: 0/4") and not hud.contains("/3"),
		"the HUD shows every retained magazine count against the real four-magazine limit:\n%s" % hud)
	player.pistol_bullet = 0
	await process_frame
	await process_frame
	_expect(player.stats_label.text.contains("Loaded: 0/12 EMPTY"), "an empty gun shows EMPTY in the HUD")
	var bar := player.get_node("CanvasLayer/MotivationBar") as ProgressBar
	_expect(bar.visible and bar.value == 100 and bar.max_value == 100, "the motivation bar shows full motivation")
	await _finish_level(level)


func _test_crosshair_follows_the_mouse() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	var crosshair := player.get_node_or_null("CanvasLayer/Crosshair") as Node2D
	var target := player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(120, -80)
	await _aim(player, Vector2(120, -80).normalized(), 144.222)
	_expect(crosshair != null and crosshair.visible and crosshair.position.distance_to(target) < 1.0,
		"the crosshair follows the mouse cursor")
	await _finish_level(level)


func _test_placeholder_visuals() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var posted := level.get_node("Enemies/CellBlockPolice2") as Enemy
	var cone := posted.get_node("Vision") as Node2D
	_expect(cone.visible and is_equal_approx(cone.rotation_degrees, 180.0) and cone.get("cone_color").a < 1.0,
		"each policeman shows a translucent vision cone turned to his facing")
	level.queue_free()
	await process_frame

	level = await _start_level()
	var player := level.get_node("Player") as Player
	player.global_position = level.get_node("Pickups/Shotgun").global_position
	await _press("interact")
	await _aim(player, Vector2.LEFT)
	var held := player.get_node("AimPivot/HeldGun") as Sprite2D
	_expect(player.skin.visible and player.skin.sprite_frames != null and held.visible
		and Vector2.RIGHT.rotated(player.get_node("AimPivot").global_rotation).dot(Vector2.LEFT) > 0.99,
		"the player sprite and held gun show the weapon pointing at the cursor")
	var facing_left := player.skin.flip_h
	await _aim(player, Vector2.RIGHT)
	_expect(not facing_left and player.skin.flip_h, "the player sprite turns to face the cursor")

	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	var visual := enemy.get_node("PoliceVisual") as Polygon2D
	var living := visual.color
	enemy.knock_down()
	var knocked := visual.color
	enemy.recovery_time_remaining = 3.05
	await create_timer(0.2).timeout
	var recovering_warning := (enemy.get_node("RecoveryWarning") as Label).visible
	enemy.kill_permanently()
	var dead := visual.color
	_expect(living.r > 0.7 and living.g < 0.3 and living.b < 0.3,
		"living police are red")
	_expect(knocked != living and dead != living and dead != knocked and not cone_visible(enemy),
		"unconscious and dead police have distinct appearances without a vision cone")
	_expect(recovering_warning, "a recovering policeman shows the recovery warning")
	var pickups_visible := true
	for path in ["Pickups/Pistol/Visual", "Pickups/AK47/Visual", "PistolMagazine/Area2D", "AK-47Magazine/Area2D"]:
		var item := level.get_node(path) as CanvasItem
		pickups_visible = pickups_visible and item.is_visible_in_tree()
	_expect(pickups_visible, "weapon and magazine pickups are visible")
	await _finish_level(level)


func cone_visible(enemy: Enemy) -> bool:
	return (enemy.get_node("Vision") as CanvasItem).visible


func _start_level() -> Node:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	_keep_only_enemy1(level)
	current_scene = level
	await process_frame
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	enemy.set_physics_process(false)
	_cues.clear()
	var feedback := level.get_node_or_null("FeedbackAudio")
	if feedback == null:
		_expect(false, "the level owns a FeedbackAudio cue player")
	else:
		feedback.connect(&"cue_played", func(cue: StringName, _at: Variant) -> void: _cues.append(cue))
	return level


func _finish_level(level: Node) -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "shoot", "interact"]:
		Input.action_release(action)
	level.queue_free()
	await process_frame


func _aim(player: Player, direction: Vector2, distance: float = 200.0) -> void:
	var motion := InputEventMouseMotion.new()
	# Input arrives in screen space and reaches the game in viewport space.
	motion.position = root.get_screen_transform() * (
		player.get_global_transform_with_canvas() * Vector2.ZERO + direction * distance)
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await process_frame
	await physics_frame
	await process_frame


func _mouse(button: MouseButton, pressed: bool) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.pressed = pressed
	click.position = root.get_mouse_position()
	click.global_position = click.position
	Input.parse_input_event(click)
	await physics_frame
	await physics_frame


func _click(button: MouseButton) -> void:
	await _mouse(button, true)
	await _mouse(button, false)
	await process_frame


func _press(action: StringName) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await process_frame


func _expect_cue(cue: StringName, description: String) -> void:
	_expect(_cues.has(cue), "%s (cues: %s)" % [description, _cues])


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)


## Story 16 posts 24 police in the level. This suite exercises one policeman's
## feedback, so only Enemy1 is kept to stop the rest of the roster from seeing,
## shooting or blocking the subject.
func _keep_only_enemy1(level: Node) -> void:
	for policeman in get_nodes_in_group("police"):
		if level.is_ancestor_of(policeman) and policeman.name != &"Enemy1":
			policeman.get_parent().remove_child(policeman)
			policeman.free()
