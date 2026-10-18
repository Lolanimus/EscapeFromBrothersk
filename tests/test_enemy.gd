extends SceneTree

const EnemyScript := preload("res://scripts/enemy.gd")
const GameplayScene := preload("res://scenes/main.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_exported_values_are_never_negative()
	await _test_target_is_resolved_when_enemy_becomes_ready()
	await _test_sight_range_and_obstacles_control_visibility()
	await _test_enemy_is_clamped_inside_the_viewport()
	await _test_enemy_keeps_pursuing_the_current_target_after_losing_sight()
	await _test_alerted_enemy_takes_the_shortest_doorway_route_to_the_player()
	await _test_alerted_enemy_crosses_a_doorway_without_getting_stuck()
	await _test_alerted_enemy_routes_around_a_wall_between_two_doorways()

	if _failures == 0:
		print("PASS: all enemy tests passed")
	else:
		push_error("FAIL: %d enemy test(s) failed" % _failures)

	quit(_failures)


func _test_exported_values_are_never_negative() -> void:
	var enemy := EnemyScript.new()

	enemy.speed = -1.0
	enemy.sight_range = -1.0
	enemy.stop_distance = -1.0

	_expect_float(enemy.speed, 0.0, "speed is clamped to zero")
	_expect_float(enemy.sight_range, 0.0, "sight_range is clamped to zero")
	_expect_float(enemy.stop_distance, 0.0, "stop_distance is clamped to zero")
	enemy.free()


func _test_target_is_resolved_when_enemy_becomes_ready() -> void:
	var target := CharacterBody2D.new()
	target.name = "Target"
	root.add_child(target)

	var enemy := _create_enemy()
	enemy.target_path = NodePath("../Target")
	root.add_child(enemy)
	await process_frame

	_expect(enemy.target == target, "target_path is resolved by @onready")

	enemy.queue_free()
	target.queue_free()
	await process_frame


func _test_sight_range_and_obstacles_control_visibility() -> void:
	var target := CharacterBody2D.new()
	target.name = "Target"
	target.position = Vector2(150.0, 100.0)
	root.add_child(target)

	var enemy := _create_enemy()
	enemy.target_path = NodePath("../Target")
	enemy.position = Vector2(100.0, 100.0)
	enemy.sight_range = 40.0
	root.add_child(enemy)
	await physics_frame

	_expect(not enemy._can_see_target(), "a target outside sight_range is not visible")

	enemy.sight_range = 100.0
	_expect(enemy._can_see_target(), "an unobstructed target inside sight_range is visible")

	var obstacle := StaticBody2D.new()
	obstacle.position = Vector2(125.0, 100.0)
	var obstacle_shape := CollisionShape2D.new()
	var obstacle_rectangle := RectangleShape2D.new()
	obstacle_rectangle.size = Vector2(10.0, 30.0)
	obstacle_shape.shape = obstacle_rectangle
	obstacle.add_child(obstacle_shape)
	root.add_child(obstacle)
	await physics_frame

	_expect(not enemy._can_see_target(), "an obstacle blocks line of sight")

	obstacle.queue_free()
	enemy.queue_free()
	target.queue_free()
	await process_frame


func _test_enemy_is_clamped_inside_the_viewport() -> void:
	var enemy := _create_enemy(Vector2(40.0, 20.0), Vector2(2.0, 3.0))
	root.add_child(enemy)
	await process_frame

	var viewport_rect := enemy.get_viewport_rect()
	enemy.global_position = viewport_rect.position - Vector2(100.0, 100.0)
	enemy._clamp_to_viewport()
	_expect_vector(enemy.global_position, viewport_rect.position + Vector2(18.0, 7.0),
		"the collision shape stays inside the top-left viewport edge")

	enemy.global_position = viewport_rect.end + Vector2(100.0, 100.0)
	enemy._clamp_to_viewport()
	_expect_vector(enemy.global_position, viewport_rect.end - Vector2(22.0, 13.0),
		"the collision shape stays inside the bottom-right viewport edge")

	enemy.queue_free()
	await process_frame


func _test_enemy_keeps_pursuing_the_current_target_after_losing_sight() -> void:
	var target := CharacterBody2D.new()
	target.name = "PersistentTarget"
	target.position = Vector2(150.0, 100.0)
	root.add_child(target)

	var enemy := _create_enemy()
	enemy.target_path = NodePath("../PersistentTarget")
	enemy.position = Vector2(100.0, 100.0)
	enemy.sight_range = 100.0
	enemy.stop_distance = 0.0
	enemy.speed = 120.0
	enemy.set_physics_process(true)
	root.add_child(enemy)
	await physics_frame
	await physics_frame

	target.position = Vector2(400.0, 100.0)
	var obstacle := StaticBody2D.new()
	obstacle.position = Vector2(130.0, 100.0)
	var obstacle_collision := CollisionShape2D.new()
	var obstacle_shape := RectangleShape2D.new()
	obstacle_shape.size = Vector2(10.0, 80.0)
	obstacle_collision.shape = obstacle_shape
	obstacle.add_child(obstacle_collision)
	root.add_child(obstacle)
	await physics_frame
	var position_after_losing_sight := enemy.position.x
	for frame in range(5):
		await physics_frame

	_expect(
		enemy.get("is_alerted") == true
		and enemy.position.x > position_after_losing_sight
		and enemy.velocity.x > 0.0,
		"an alerted enemy keeps pursuing the target's current position after losing sight"
	)

	enemy.queue_free()
	target.queue_free()
	obstacle.queue_free()
	await process_frame


func _test_alerted_enemy_takes_the_shortest_doorway_route_to_the_player() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var enemy := level.get_node("Enemies/Enemy1") as CharacterBody2D
	player.global_position = Vector2(650.0, 300.0)
	enemy.global_position = Vector2(600.0, 300.0)
	enemy.sight_range = 100.0
	enemy.stop_distance = 0.0
	enemy.speed = 300.0
	await physics_frame
	await physics_frame

	player.global_position = Vector2(1000.0, 850.0)
	await physics_frame
	await physics_frame
	var doorway_velocity := enemy.velocity

	for frame in range(240):
		await physics_frame

	_expect(
		enemy.get("is_alerted") == true
		and doorway_velocity.y > 0.0
		and absf(doorway_velocity.x) < 20.0
		and level.call("get_area_id_at", enemy.global_position) == &"exercise_yard",
		"an alerted enemy takes the shortest doorway route and reaches the player's room"
	)

	level.queue_free()
	await process_frame


func _test_alerted_enemy_crosses_a_doorway_without_getting_stuck() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var enemy := level.get_node("Enemies/Enemy1") as CharacterBody2D
	player.global_position = Vector2(820.0, 475.0)
	enemy.global_position = Vector2(900.0, 475.0)
	enemy.sight_range = 100.0
	enemy.stop_distance = 0.0
	enemy.speed = 160.0
	await physics_frame
	await physics_frame

	enemy.global_position = Vector2(850.0, 475.0)
	player.global_position = Vector2(600.0, 350.0)
	for frame in range(120):
		await physics_frame

	_expect(
		enemy.get("is_alerted") == true
		and level.call("get_area_id_at", enemy.global_position) == &"cell_block",
		"an alerted enemy crosses the doorway instead of stopping on its boundary"
	)

	level.queue_free()
	await process_frame


func _test_alerted_enemy_routes_around_a_wall_between_two_doorways() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame

	var player := level.get_node("Player") as CharacterBody2D
	var enemy := level.get_node("Enemies/Enemy1") as CharacterBody2D
	player.global_position = Vector2(1090.0, 430.0)
	enemy.global_position = Vector2(1075.0, 430.0)
	enemy.sight_range = 100.0
	enemy.stop_distance = 40.0
	enemy.speed = 160.0
	await physics_frame
	await physics_frame

	enemy.global_position = Vector2(1075.0, 400.0)
	player.global_position = Vector2(1500.0, 400.0)
	for frame in range(240):
		await physics_frame

	_expect(
		enemy.get("is_alerted") == true
		and enemy.global_position.distance_to(player.global_position) <= enemy.stop_distance + 5.0,
		"an alerted enemy routes around the wall between two doorway positions"
	)

	level.queue_free()
	await process_frame


func _create_enemy(
	shape_size: Vector2 = Vector2(20.0, 20.0),
	shape_position: Vector2 = Vector2.ZERO
) -> CharacterBody2D:
	var enemy := EnemyScript.new()
	enemy.set_physics_process(false)

	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.position = shape_position
	var rectangle := RectangleShape2D.new()
	rectangle.size = shape_size
	collision_shape.shape = rectangle
	enemy.add_child(collision_shape)

	return enemy


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return

	_failures += 1
	push_error("FAIL: %s" % message)


func _expect_float(actual: float, expected: float, message: String) -> void:
	_expect(is_equal_approx(actual, expected), "%s (expected %s, got %s)" % [message, expected, actual])


func _expect_vector(actual: Vector2, expected: Vector2, message: String) -> void:
	_expect(actual.is_equal_approx(expected), "%s (expected %s, got %s)" % [message, expected, actual])
