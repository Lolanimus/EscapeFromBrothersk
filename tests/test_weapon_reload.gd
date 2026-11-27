extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_pistol_reload_discards_partial_magazine_and_empty_fire_stops()
	await _test_shotgun_reload_discards_partial_magazine_and_empty_fire_stops()
	await _test_ak47_reload_discards_partial_magazine_and_empty_fire_stops()
	if _failures == 0:
		print("PASS: all weapon reload tests passed")
	else:
		push_error("FAIL: %d weapon reload test(s) failed" % _failures)
	quit(_failures)


func _test_pistol_reload_discards_partial_magazine_and_empty_fire_stops() -> void:
	var level := await _new_quiet_level()
	var player := level.get_node("Player") as Player
	player.pistol_projectile_speed = 0.0
	player.global_position = level.get_node("Pickups/Pistol").global_position
	await _press("interact")
	var pickup := level.get_node("PistolMagazine/Area2D") as MagazinePickup
	player.global_position = pickup.global_position
	await _press("interact")
	player.pistol_bullet = 5
	await _press("reload")
	await process_frame
	_expect(player.pistol_bullet == 12 and player.pistol_magazines == 0,
		"R discards five remaining pistol rounds and loads one full 12-round retained magazine")
	_expect(player.stats_label.text.contains("Loaded: 12/12")
		and player.stats_label.text.contains("Pistol magazines: 0/4"),
		"pistol HUD shows the loaded and retained counts after reloading")

	player.pistol_bullet = 1
	player.pistol_firing_cadence = 0.0
	await _press("shoot")
	var shots_after_last_round := get_nodes_in_group("player_projectiles").size()
	await _press("shoot")
	await process_frame
	_expect(player.pistol_bullet == 0 and shots_after_last_round == 1
		and get_nodes_in_group("player_projectiles").size() == 1
		and player.stats_label.text.contains("EMPTY"),
		"the final pistol round empties its magazine and later firing shows EMPTY without another projectile")
	player.pistol_magazines = 3
	var pistol_pickup_collected := await _collect_extra_magazine(
		level, player, "res://scenes/PistolMagazine.tscn", "ExtraPistolMagazine")
	_expect(pistol_pickup_collected and player.pistol_magazines == 4,
		"an empty pistol magazine no longer occupies capacity, so a fourth reserve magazine can be collected")
	level.queue_free()
	await process_frame


func _test_shotgun_reload_discards_partial_magazine_and_empty_fire_stops() -> void:
	var level := await _new_quiet_level()
	var player := level.get_node("Player") as Player
	player.shotgun_projectile_speed = 0.0
	player.global_position = level.get_node("Pickups/Shotgun").global_position
	await _press("interact")
	var pickup := level.get_node("ShotgunMagazine/Area2D") as MagazinePickup
	player.global_position = pickup.global_position
	await _press("interact")
	player.shotgun_bullet = 2
	await _press("reload")
	await process_frame
	_expect(player.shotgun_bullet == 6 and player.shotgun_magazines == 0,
		"R discards two remaining shotgun blasts and loads one full six-blast retained magazine")
	_expect(player.stats_label.text.contains("Loaded: 6/6")
		and player.stats_label.text.contains("Shotgun magazines: 0/4"),
		"shotgun HUD shows the loaded and retained counts after reloading")

	player.shotgun_bullet = 1
	player.shotgun_firing_cadence = 0.0
	await _press("shoot")
	var shots_after_last_round := get_nodes_in_group("player_projectiles").size()
	await _press("shoot")
	await process_frame
	_expect(player.shotgun_bullet == 0 and shots_after_last_round == 6
		and get_nodes_in_group("player_projectiles").size() == 6
		and player.stats_label.text.contains("EMPTY"),
		"the final shotgun blast destroys its magazine and later firing shows EMPTY without another blast")
	player.shotgun_magazines = 3
	var shotgun_pickup_collected := await _collect_extra_magazine(
		level, player, "res://scenes/ShotgunMagazine.tscn", "ExtraShotgunMagazine")
	_expect(shotgun_pickup_collected and player.shotgun_magazines == 4,
		"an empty shotgun magazine no longer occupies capacity, so a fourth reserve magazine can be collected")
	level.queue_free()
	await process_frame


func _test_ak47_reload_discards_partial_magazine_and_empty_fire_stops() -> void:
	var level := await _new_quiet_level()
	var player := level.get_node("Player") as Player
	player.ak47_projectile_speed = 0.0
	player.global_position = level.get_node("Pickups/AK47").global_position
	await _press("interact")
	var pickup := level.get_node("AK-47Magazine/Area2D") as MagazinePickup
	player.global_position = pickup.global_position
	await _press("interact")
	player.ak47_bullet = 5
	await _press("reload")
	await process_frame
	_expect(player.ak47_bullet == 31 and player.ak47_magazines == 0,
		"R discards five remaining AK-47 rounds and loads one full 31-round retained magazine")
	_expect(player.stats_label.text.contains("Loaded: 31/31")
		and player.stats_label.text.contains("AK-47 magazines: 0/4"),
		"AK-47 HUD shows the loaded and retained counts after reloading")

	player.ak47_bullet = 1
	player.ak47_firing_cadence = 0.1
	Input.action_press("shoot")
	for frame in range(12):
		await physics_frame
	Input.action_release("shoot")
	await physics_frame
	await process_frame
	var shots_after_last_round := get_nodes_in_group("player_projectiles").size()
	await _press("shoot")
	await process_frame
	_expect(player.ak47_bullet == 0 and shots_after_last_round == 1
		and get_nodes_in_group("player_projectiles").size() == 1
		and player.stats_label.text.contains("EMPTY"),
		"the final AK-47 round destroys its magazine and later firing shows EMPTY without another projectile")
	player.ak47_magazines = 3
	var ak47_pickup_collected := await _collect_extra_magazine(
		level, player, "res://scenes/AK-47Magazine.tscn", "ExtraAK47Magazine")
	_expect(ak47_pickup_collected and player.ak47_magazines == 4,
		"an empty AK-47 magazine no longer occupies capacity, so a fourth reserve magazine can be collected")
	level.queue_free()
	await process_frame


func _new_quiet_level() -> Node:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	for enemy in level.get_node("Enemies").get_children():
		enemy.set_physics_process(false)
		enemy.get_node("Gun").set_physics_process(false)
	return level


func _press(action: StringName) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	await physics_frame
	await process_frame


func _collect_extra_magazine(level: Node, player: Player, scene_path: String, pickup_name: String) -> bool:
	var pickup_root := load(scene_path).instantiate() as Node2D
	pickup_root.name = pickup_name
	level.add_child(pickup_root)
	pickup_root.global_position = player.global_position
	await process_frame
	var pickup := pickup_root.get_node("Area2D") as MagazinePickup
	await _press("interact")
	return not is_instance_valid(pickup)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures += 1
		push_error("FAIL: %s" % message)
