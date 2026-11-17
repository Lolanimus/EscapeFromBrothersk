extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	await test_gunfire_turns_police_through_walls_without_alerting()
	await test_gunfire_turns_police_through_walls_without_alerting(100.0, false)
	await test_gunfire_turns_police_through_walls_without_alerting(300.0, true)
	await test_gunfire_turns_police_through_walls_without_alerting(800.0, true, false)
	await test_alerted_police_fire_outside_the_cone_with_a_clear_shot()
	await test_pistol_detection_cadence_and_obstructed_pursuit()
	await test_police_gunfire_is_audible_to_other_police()
	quit(failures)

func test_gunfire_turns_police_through_walls_without_alerting(radius: float = 800.0, should_turn: bool = true, obstructed: bool = true) -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player = level.get_node("Player")
	var enemy = level.get_node("Enemies/Enemy1")
	enemy.speed = 0.0
	enemy.gunfire_hearing_radius = radius
	enemy.get_node("Gun").set_physics_process(false)
	player.global_position = Vector2(3000, 3000)
	enemy.global_position = Vector2(3200, 3000)
	level.get_node("Pickups/Pistol").global_position = player.global_position
	var wall := StaticBody2D.new()
	wall.position = Vector2(3100, 3000)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 200)
	collision.shape = shape
	wall.add_child(collision)
	level.add_child(wall)
	if not obstructed:
		wall.queue_free()
	await physics_frame
	await physics_frame
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")
	await physics_frame
	Input.action_press("shoot")
	await physics_frame
	Input.action_release("shoot")
	for frame in range(5):
		await physics_frame
	var facing := Vector2.UP.rotated(enemy.get_node("Vision").global_rotation)
	var turned: bool = facing.dot(enemy.global_position.direction_to(player.global_position)) > 0.99
	check(turned == should_turn and enemy.is_alerted == (should_turn and not obstructed)
		and enemy.velocity.is_zero_approx(),
		"gunfire respects radius %.0f; hearing turns=%s, visual obstruction=%s" % [radius, should_turn, obstructed])
	level.queue_free()
	await process_frame

func test_alerted_police_fire_outside_the_cone_with_a_clear_shot() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player = level.get_node("Player")
	var enemy = level.get_node("Enemies/Enemy1")
	var gun = enemy.get_node("Gun")
	var vision = enemy.get_node("Vision")
	enemy.speed = 0.0
	enemy.global_position = Vector2(3000, 3000)
	player.global_position = Vector2(3200, 3000)
	vision.global_rotation = PI / 2.0
	vision.turn_speed = 0.01
	gun.fire_cadence = 0.1
	gun.projectile_speed = 0.0
	for frame in range(4):
		await physics_frame
	check(enemy.is_alerted, "seeing the player establishes persistent alert")
	player.global_position = Vector2(2800, 3000)
	var shots_before := 0
	for child in level.get_children():
		if child is EnemyProjectile:
			shots_before += 1
	for frame in range(10):
		await physics_frame
	var new_aimed_shots := 0
	for child in level.get_children():
		if child is EnemyProjectile and child.direction.x < -0.99:
			new_aimed_shots += 1
	check(shots_before > 0 and new_aimed_shots > 0,
		"alerted police keep firing toward the current player position outside their cone")
	level.queue_free()
	await process_frame

func test_pistol_detection_cadence_and_obstructed_pursuit() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player = level.get_node("Player")
	var enemy = level.get_node("Enemies/Enemy1")
	var gun = enemy.get_node("Gun")
	enemy.speed = 0.0
	enemy.global_position = Vector2(3000, 3000)
	player.global_position = Vector2(3200, 3000)
	enemy.get_node("Vision").global_rotation = PI / 2.0
	gun.projectile_speed = 0.0
	var shots: Array[Node] = []
	level.child_entered_tree.connect(func(node: Node):
		if node is EnemyProjectile:
			shots.append(node)
	)
	for frame in range(3):
		await physics_frame
	check(shots.size() == 1, "police pistol fires immediately on detection")
	for frame in range(30):
		await physics_frame
	check(shots.size() == 1, "default police pistol cadence waits 0.6 seconds")
	for frame in range(7):
		await physics_frame
	check(shots.size() == 2, "default police pistol fires again after 0.6 seconds")
	var wall := StaticBody2D.new()
	wall.position = Vector2(3100, 3000)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 200)
	collision.shape = shape
	wall.add_child(collision)
	level.add_child(wall)
	for frame in range(3):
		await physics_frame
	var shots_before := shots.size()
	enemy.speed = 50.0
	var pursuit_start: Vector2 = enemy.global_position
	for frame in range(40):
		await physics_frame
	check(shots.size() == shots_before and enemy.is_alerted
		and enemy.global_position.distance_to(pursuit_start) > 10.0
		and enemy.get_node("Vision").is_alerted,
		"wall stops firing while persistent red alert and pursuit continue")
	wall.queue_free()
	for frame in range(3):
		await physics_frame
	check(shots.size() > shots_before, "alerted police resume firing when the wall is removed")
	level.queue_free()
	await process_frame

func test_police_gunfire_is_audible_to_other_police() -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	var player = level.get_node("Player")
	var shooter = level.get_node("Enemies/Enemy1")
	shooter.global_position = Vector2(3000, 3000)
	shooter.speed = 0.0
	shooter.get_node("Gun").projectile_speed = 0.0
	shooter.get_node("Vision").global_rotation = PI / 2.0
	player.global_position = Vector2(3200, 3000)
	var listener = shooter.duplicate()
	level.get_node("Enemies").add_child(listener)
	listener.global_position = Vector2(3000, 3200)
	listener.get_node("Gun").set_physics_process(false)
	listener.get_node("Vision").global_rotation = PI
	var wall := StaticBody2D.new()
	wall.position = Vector2(3100, 3100)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(500, 20)
	collision.shape = shape
	wall.add_child(collision)
	level.add_child(wall)
	for frame in range(6):
		await physics_frame
	var facing := Vector2.UP.rotated(listener.get_node("Vision").global_rotation)
	check(facing.y < -0.9 and not listener.is_alerted,
		"police gunfire also turns other unalerted police through walls")
	level.queue_free()
	await process_frame

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
