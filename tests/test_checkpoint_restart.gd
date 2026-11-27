extends SceneTree

## Story 19: the single level-start checkpoint. Every attempt is played through the
## real gameplay scene, then restored with Backspace or the death restart button, and
## the restored level is compared with the state observed when the level first started.

const GameplayScene := preload("res://scenes/main.tscn")
const START_POSITION := Vector2(225, 225)
const POLICE_ROSTER_SIZE := 24

var _failures := 0
var _level_start: Dictionary


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var level := await _start_level()
	_level_start = _observe(level)
	_expect_fresh_level_start(level)
	await _finish_level(level)
	await _test_backspace_mid_fight_restores_level_start()
	await _test_backspace_after_clearing_and_leaving_restores_level_start()
	await _test_restart_button_after_death_restores_level_start()
	await _test_backspace_after_death_restores_level_start()
	if _failures == 0:
		print("PASS: all checkpoint restart tests passed")
	else:
		push_error("FAIL: %d checkpoint restart test(s) failed" % _failures)
	quit(_failures)


# The observed level start is the checkpoint every restore is compared against.
func _expect_fresh_level_start(level: Node) -> void:
	var player := level.get_node("Player") as Player
	_expect(player.global_position.is_equal_approx(START_POSITION) and player.motivation == Player.MAX_MOTIVATION
		and player.active_weapon == &"fists" and player.carried_melee_weapon == &"" and player.carried_ranged_weapon == &""
		and player.pistol_bullet == 12 and player.shotgun_bullet == 6 and player.ak47_bullet == 31
		and player.pistol_magazines == 0 and player.shotgun_magazines == 0 and player.ak47_magazines == 0,
		"the level starts with the player at the start, full motivation, empty slots, full guns and no magazines")
	var police := _police(level)
	_expect(police.size() == POLICE_ROSTER_SIZE
		and police.all(func(policeman: Enemy) -> bool: return policeman.life_state == &"living" and not policeman.is_alerted),
		"the level starts with all %d policemen alive and unalerted" % POLICE_ROSTER_SIZE)
	_expect(level.has_node("Pickups/Pistol") and level.has_node("Pickups/Shotgun") and level.has_node("Pickups/AK47")
		and level.has_node("Pickups/Katana") and _level_start["weapon_pickups"].size() == 4
		and _level_start["magazine_pickups"].size() == 9
		and _level_start["police_drops"] == 0 and _level_start["thrown_weapons"] == 0,
		"the level starts with the four placed weapons, nine placed magazines and no loot")
	_expect(_level_start["doors"].size() == 11 and not _level_start["doors"].has(true)
		and _level_start["objective"] == {"exit_unlocked": false, "level_complete": false,
			"exit_status": "EXIT LOCKED", "exit_gate_visible": true, "completion_overlay": false},
		"the level starts with every door closed and the exit locked")
	_expect(_level_start["stray_root_nodes"].is_empty(),
		"the level starts without leftover nodes outside the scene")


func _test_backspace_mid_fight_restores_level_start() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	await _play_common_attempt(level)
	var alerted := await _alert_policeman_until_hit(level)
	# A magazine collected right before the restart leaves its pickup feedback on screen.
	player.global_position = level.get_node("AK-47Magazine").global_position
	await physics_frame
	await _press("interact")
	_expect(alerted.is_alerted and alerted.life_state == &"living" and player.motivation < Player.MAX_MOTIVATION
		and player.ak47_magazines == 1 and not level.has_node("AK-47Magazine/Area2D") and not player.is_dead,
		"mid-fight: an alerted policeman lowers motivation by shooting, and another magazine is collected")
	await _restart_with_backspace(level, "Backspace mid-fight")


func _test_backspace_after_clearing_and_leaving_restores_level_start() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	await _play_common_attempt(level)
	for policeman in _police(level):
		policeman.kill_permanently()
	await physics_frame
	player.global_position = PrisonLevel.EXIT_THRESHOLD.get_center()
	for frame in range(3):
		await physics_frame
	_expect(level.exit_unlocked and level.level_complete and level.has_node("CompletionLayer")
		and level.get_node("Prison/ExitStatus").text == "EXIT OPEN"
		and _police(level).all(func(policeman: Enemy) -> bool: return policeman.life_state == &"dead"),
		"cleared: every policeman is a body, the exit is unlocked and the player has left the prison")
	await _restart_with_backspace(level, "Backspace after leaving")


func _test_restart_button_after_death_restores_level_start() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	await _play_common_attempt(level)
	await _get_shot_dead(level)
	var button := player.get_node("CanvasLayer/RestartButton") as Button
	_expect(player.is_dead and button.visible, "death: the alerted police shoot the player dead and the restart button appears")
	var previous_instance := level.get_instance_id()
	var started := Time.get_ticks_msec()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = button.get_global_rect().get_center()
	click.global_position = click.position
	click.pressed = true
	root.push_input(click, true)
	await process_frame
	click = click.duplicate()
	click.pressed = false
	root.push_input(click, true)
	await _expect_restored(previous_instance, started, "the death restart button")


func _test_backspace_after_death_restores_level_start() -> void:
	var level := await _start_level()
	var player := level.get_node("Player") as Player
	await _play_common_attempt(level)
	await _get_shot_dead(level)
	_expect(player.is_dead, "death: the alerted police shoot the player dead before Backspace")
	await _restart_with_backspace(level, "Backspace after death")


# The shared attempt mutates every captured system: the player takes the katana and the
# pistol, collects placed magazines, fires rounds that kill a policeman (who drops his gun),
# throws the gun to knock a policeman down, opens a door, and throws the katana.
func _play_common_attempt(level: Node) -> void:
	var player := level.get_node("Player") as Player
	var victim := level.get_node("Enemies/Enemy1") as Enemy
	var knocked := level.get_node("Enemies/CellBlockPolice4") as Enemy
	await _press("interact")
	player.global_position = level.get_node("Pickups/Pistol").global_position
	await physics_frame
	await _press("interact")
	player.global_position = level.get_node("PistolMagazine").global_position
	await physics_frame
	await _press("interact")
	player.global_position = level.get_node("ShotgunMagazine").global_position
	await physics_frame
	await _press("interact")
	_expect(player.carried_melee_weapon == &"katana" and player.carried_ranged_weapon == &"pistol"
		and player.active_weapon == &"pistol" and player.pistol_magazines == 1 and player.shotgun_magazines == 1
		and not level.has_node("Pickups/Katana") and not level.has_node("Pickups/Pistol")
		and not level.has_node("PistolMagazine/Area2D") and not level.has_node("ShotgunMagazine/Area2D"),
		"the attempt fills both carried slots and retains placed pistol and shotgun magazines")

	victim.global_position = Vector2(650, 350)
	player.global_position = Vector2(550, 350)
	await physics_frame
	await _aim_right(player)
	for shot in range(3):
		await _press("shoot")
		await create_timer(0.3).timeout
	_expect(victim.life_state == &"dead" and player.pistol_bullet == 9
		and not get_nodes_in_group("police_drops").is_empty(),
		"the attempt fires three pistol rounds and kills a policeman, who drops his gun")

	knocked.global_position = Vector2(700, 350)
	await physics_frame
	await _throw_right()
	await create_timer(0.3).timeout
	_expect(knocked.life_state == &"knocked_down" and player.carried_ranged_weapon == &""
		and player.active_weapon == &"katana",
		"the attempt throws the pistol, which knocks a policeman down")

	player.global_position = Vector2(330, 225)
	for frame in range(6):
		await physics_frame
	_expect(get_nodes_in_group("automatic_doors").any(func(door: Node) -> bool: return door.is_open),
		"the attempt opens an automatic door")

	player.global_position = Vector2(550, 250)
	await physics_frame
	await _aim_right(player)
	await _throw_right()
	await create_timer(0.6).timeout
	var thrown_katana := get_nodes_in_group("weapon_pickups").any(
		func(pickup: Node) -> bool: return StringName(pickup.get("weapon_type")) == &"katana")
	_expect(player.carried_melee_weapon == &"" and player.active_weapon == &"fists" and thrown_katana,
		"the attempt throws the katana, which lands as a floor pickup")


# CellBlockPolice2 faces down from (480, 150); standing below him alerts him and he shoots.
func _alert_policeman_until_hit(level: Node) -> Enemy:
	var player := level.get_node("Player") as Player
	var policeman := level.get_node("Enemies/CellBlockPolice2") as Enemy
	player.global_position = Vector2(480, 280)
	policeman.set_physics_process(true)
	var started := Time.get_ticks_msec()
	while player.motivation == Player.MAX_MOTIVATION and Time.get_ticks_msec() - started < 4000:
		await physics_frame
	return policeman


func _get_shot_dead(level: Node) -> void:
	var player := level.get_node("Player") as Player
	var policeman := await _alert_policeman_until_hit(level)
	_expect(policeman.is_alerted and player.motivation < Player.MAX_MOTIVATION,
		"an alerted policeman lowers the player's motivation with real hits")
	var started := Time.get_ticks_msec()
	while not player.is_dead and Time.get_ticks_msec() - started < 6000:
		await physics_frame
	await process_frame


func _restart_with_backspace(level: Node, label: String) -> void:
	var previous_instance := level.get_instance_id()
	var started := Time.get_ticks_msec()
	var key := InputEventKey.new()
	key.keycode = KEY_BACKSPACE
	key.pressed = true
	root.push_input(key)
	key = key.duplicate()
	key.pressed = false
	root.push_input(key)
	await _expect_restored(previous_instance, started, label)


# Waits for the reloaded 24-police level, checks the restore time, then compares every
# captured system with the observed level start.
func _expect_restored(previous_instance: int, started: int, label: String) -> void:
	while (current_scene == null or current_scene.get_instance_id() == previous_instance
		or not current_scene.is_node_ready()) and Time.get_ticks_msec() - started < 2000:
		await process_frame
	await physics_frame
	var elapsed := Time.get_ticks_msec() - started
	var restored := current_scene != null and current_scene.get_instance_id() != previous_instance
	_expect(restored and elapsed < 1000 and _police(current_scene).size() == POLICE_ROSTER_SIZE,
		"%s restores the full %d-police level in under one second (%d ms)" % [label, POLICE_ROSTER_SIZE, elapsed])
	if not restored:
		return
	# Feedback from the previous attempt would have expired by now; anything left has leaked.
	await create_timer(1.6).timeout
	_expect_level_start(current_scene, label)
	await _finish_level(current_scene)


func _expect_level_start(level: Node, label: String) -> void:
	var state := _observe(level)
	_expect(state["player"] == _level_start["player"],
		"%s restores the player's start position, motivation, carried weapons, loaded rounds and magazines: %s"
		% [label, state["player"]])
	_expect(state["police"] == _level_start["police"],
		"%s restores all %d policemen to their posts alive, unalerted and standing, with no bodies" % [label, POLICE_ROSTER_SIZE])
	_expect(state["weapon_pickups"] == _level_start["weapon_pickups"]
		and state["magazine_pickups"] == _level_start["magazine_pickups"]
		and state["police_drops"] == 0 and state["thrown_weapons"] == 0,
		"%s restores the placed weapons and magazines and removes police drops and thrown weapons" % label)
	_expect(state["doors"] == _level_start["doors"], "%s closes every door" % label)
	_expect(state["objective"] == _level_start["objective"],
		"%s relocks the exit and clears level completion: %s" % [label, state["objective"]])
	_expect(state["stray_root_nodes"].is_empty(),
		"%s leaves nothing from the previous attempt outside the level: %s" % [label, state["stray_root_nodes"]])


# Everything the checkpoint captures, read from the running level.
func _observe(level: Node) -> Dictionary:
	var player := level.get_node("Player") as Player
	var police: Array[String] = []
	for policeman in _police(level):
		police.append("%s %s %s alerted=%s gun=%s facing=%.1f layer=%d" % [
			policeman.name, policeman.global_position.round(), policeman.life_state, policeman.is_alerted,
			(policeman.get_node("Gun") as EnemyGun).weapon_type,
			(policeman.get_node("Vision") as Node2D).rotation_degrees, policeman.collision_layer])
	police.sort()
	var weapon_pickups: Array[String] = []
	for pickup in _in_level(level, "weapon_pickups"):
		weapon_pickups.append("%s %s rounds=%d" % [
			pickup.get("weapon_type"), (pickup as Node2D).global_position.round(), int(pickup.get("loaded_rounds"))])
	weapon_pickups.sort()
	var magazine_pickups: Array[String] = []
	for pickup in _in_level(level, "magazine_pickups"):
		magazine_pickups.append("%s %s" % [pickup.get("weapon_type"), (pickup as Node2D).global_position.round()])
	magazine_pickups.sort()
	var doors: Array[bool] = []
	for door in _in_level(level, "automatic_doors"):
		doors.append(door.is_open)
	var stray_root_nodes: Array[String] = []
	for child in root.get_children():
		if child != level:
			stray_root_nodes.append(child.name)
	return {
		"player": {
			"position": player.global_position.round(),
			"dead": player.is_dead,
			"motivation": player.motivation,
			"active": player.active_weapon,
			"melee_slot": player.carried_melee_weapon,
			"ranged_slot": player.carried_ranged_weapon,
			"loaded": [player.pistol_bullet, player.shotgun_bullet, player.ak47_bullet],
			"magazines": [player.pistol_magazines, player.shotgun_magazines, player.ak47_magazines],
			"restart_button": (player.get_node("CanvasLayer/RestartButton") as Button).visible,
		},
		"police": police,
		"weapon_pickups": weapon_pickups,
		"magazine_pickups": magazine_pickups,
		"police_drops": _in_level(level, "police_drops").size(),
		"thrown_weapons": _in_level(level, "thrown_weapons").size(),
		"doors": doors,
		"objective": {
			"exit_unlocked": level.exit_unlocked,
			"level_complete": level.level_complete,
			"exit_status": level.get_node("Prison/ExitStatus").text,
			"exit_gate_visible": level.get_node("Prison/ExitGate").visible,
			"completion_overlay": level.has_node("CompletionLayer"),
		},
		"stray_root_nodes": stray_root_nodes,
	}


func _start_level() -> Node:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	level.get_node("Player/Camera2D").enabled = false
	for policeman in get_nodes_in_group("police"):
		policeman.set_physics_process(false)
	return level


func _aim_right(player: Player) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300, 0)
	motion.global_position = motion.position
	root.push_input(motion, true)
	await process_frame


func _throw_right() -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	await physics_frame
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	await process_frame


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await process_frame


func _police(level: Node) -> Array[Enemy]:
	var police: Array[Enemy] = []
	for policeman in _in_level(level, "police"):
		police.append(policeman as Enemy)
	return police


func _in_level(level: Node, group: StringName) -> Array[Node]:
	var nodes: Array[Node] = []
	for node in get_nodes_in_group(group):
		if level.is_ancestor_of(node) and not node.is_queued_for_deletion():
			nodes.append(node)
	return nodes


func _finish_level(level: Node) -> void:
	level.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
