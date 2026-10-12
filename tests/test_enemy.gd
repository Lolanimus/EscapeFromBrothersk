extends SceneTree

const EnemyScript := preload("res://scripts/enemy.gd")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_exported_values_are_never_negative()
	await _test_target_is_resolved_when_enemy_becomes_ready()
	await _test_sight_range_and_obstacles_control_visibility()
	await _test_enemy_is_clamped_inside_the_viewport()

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
