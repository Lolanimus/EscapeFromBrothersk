extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_magazines_are_typed_full_and_retained_without_matching_guns()
	await _test_full_capacity_rejects_pickup_until_space_is_freed()
	if _failures == 0:
		print("PASS: all weapon magazine tests passed")
	else:
		push_error("FAIL: %d weapon magazine test(s) failed" % _failures)
	quit(_failures)


func _test_magazines_are_typed_full_and_retained_without_matching_guns() -> void:
	var level := await _new_quiet_level()
	var player := level.get_node("Player") as Player
	var expected := {
		"PistolMagazine": {"type": "pistol", "capacity": 12, "label": "Pistol Ammunition", "reserve": "pistol_magazines"},
		"ShotgunMagazine": {"type": "shotgun", "capacity": 6, "label": "Shot Ammunition", "reserve": "shotgun_magazines"},
		"AK-47Magazine": {"type": "ak47", "capacity": 31, "label": "AK-47 Ammunition", "reserve": "ak47_magazines"},
	}
	var definitions_match := true
	for node_name in expected:
		var pickup_root := level.get_node(node_name) as Node2D
		var pickup := pickup_root.get_node("Area2D") as MagazinePickup
		var label := pickup.get_node("Label") as Label
		var sprite := pickup.get_node("Sprite2D") as Sprite2D
		var item: Dictionary = expected[node_name]
		definitions_match = definitions_match and pickup.weapon_type == item.type
		definitions_match = definitions_match and pickup.get_magazine_capacity() == item.capacity
		definitions_match = definitions_match and label.visible and label.text == item.label
		definitions_match = definitions_match and sprite.visible and sprite.texture != null
	_expect(definitions_match,
		"floor pickups visibly identify full pistol 12, shotgun 6, and AK-47 31 magazines")

	var retained_correctly := true
	var retained_counts := {"pistol_magazines": 0, "shotgun_magazines": 0, "ak47_magazines": 0}
	for node_name in expected:
		var pickup_root := level.get_node(node_name) as Node2D
		var pickup := pickup_root.get_node("Area2D") as MagazinePickup
		var item: Dictionary = expected[node_name]
		player.global_position = pickup.global_position
		await _press_interact()
		retained_counts[item.reserve] += 1
		retained_correctly = retained_correctly and player.active_weapon == &"fists"
		for reserve in retained_counts:
			retained_correctly = retained_correctly and int(player.get(reserve)) == retained_counts[reserve]
		retained_correctly = retained_correctly and not is_instance_valid(pickup)
		pickup_root.queue_free()
		await process_frame
	_expect(retained_correctly,
		"each full magazine is retained for its weapon type while the player carries no matching gun")
	_expect(_has_pickup_feedback(),
		"collecting a magazine shows observable pickup feedback")
	level.queue_free()
	await process_frame


func _test_full_capacity_rejects_pickup_until_space_is_freed() -> void:
	var cases := [
		{"weapon": "Pistol", "magazine": "PistolMagazine", "type": &"pistol", "reserve": "pistol_magazines", "capacity": 12},
		{"weapon": "Shotgun", "magazine": "ShotgunMagazine", "type": &"shotgun", "reserve": "shotgun_magazines", "capacity": 6},
		{"weapon": "AK47", "magazine": "AK-47Magazine", "type": &"ak47", "reserve": "ak47_magazines", "capacity": 31},
	]
	for item in cases:
		var level := await _new_quiet_level()
		var player := level.get_node("Player") as Player
		var weapon_pickup := level.get_node("Pickups/" + item.weapon) as Node2D
		player.global_position = weapon_pickup.global_position
		await _press_interact()
		player.set(item.reserve, 3)
		var pickup := level.get_node(item.magazine + "/Area2D") as MagazinePickup
		player.global_position = pickup.global_position
		await _press_interact()
		var rejected_and_preserved: bool = (
			player.active_weapon == item.type
			and player.get_loaded_rounds() == item.capacity
			and int(player.get(item.reserve)) == 3
			and is_instance_valid(pickup)
		)
		_expect(rejected_and_preserved,
			"a %s pickup is rejected and stays on the floor when its loaded magazine plus three reserves reach four" % item.type)

		player.set(item.reserve, 2)
		await _press_interact()
		_expect(int(player.get(item.reserve)) == 3 and not is_instance_valid(pickup),
			"the preserved %s pickup can be collected after a reserve slot is freed" % item.type)
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


func _press_interact() -> void:
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")
	await physics_frame
	await process_frame


func _has_pickup_feedback() -> bool:
	for child in current_scene.find_children("*", "CanvasLayer", true, false):
		if child is CanvasLayer:
			for label in child.get_children():
				if label is Label and label.text == "Magazine collected!":
					return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures += 1
		push_error("FAIL: %s" % message)
