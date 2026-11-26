extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await check_fast_shot(false)
	await check_fast_shot(true)
	quit(failures)

func check_fast_shot(police: bool) -> void:
	var level := GameplayScene.instantiate()
	root.add_child(level)
	_keep_only_enemy1(level)
	current_scene = level
	await process_frame
	var player := level.get_node("Player") as Player
	var enemy := level.get_node("Enemies/Enemy1") as Enemy
	enemy.set_physics_process(false)
	var gun := enemy.get_node("Gun") as EnemyGun
	gun.set_physics_process(false)
	player.global_position = Vector2(450, 450)
	enemy.global_position = Vector2(700, 550)
	if not police:
		var pickup := level.get_node("Pickups/Shotgun") as Node2D
		player.global_position = pickup.global_position
		await press("interact")
		player.global_position = Vector2(450, 450)
	for frame in range(3):
		await physics_frame
	var motion := InputEventMouseMotion.new()
	motion.position = player.get_global_transform_with_canvas() * Vector2.ZERO + Vector2(300, 0)
	Input.parse_input_event(motion)
	await process_frame
	var direction := Vector2.RIGHT.rotated(player.aim_pivot.global_rotation)
	var origin := player.global_position + direction * 24.0
	if police:
		player.global_position = Vector2(750, 550)
		gun.global_position = Vector2(450, 450)
		gun.global_rotation = 0.0
		direction = Vector2.RIGHT
		origin = gun.global_position + direction * gun.muzzle_distance
	var wall := StaticBody2D.new()
	wall.position = origin + direction * 33.0
	wall.rotation = direction.angle()
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(2, 180)
	collision.shape = rectangle
	wall.add_child(collision)
	level.add_child(wall)
	await physics_frame
	await physics_frame
	if police:
		gun.weapon_type = "shotgun"
		gun.projectile_speed = 4000.0
		# Public trigger drives the real gun while isolating projectile collision from AI sight.
		gun.set_trigger(true)
		gun.set_physics_process(true)
	else:
		player.shotgun_projectile_speed = 4000.0
		await press("shoot")
	for frame in range(5):
		await physics_frame
	var remaining := get_nodes_in_group("enemy_projectiles" if police else "player_projectiles").size()
	if remaining != 0:
		failures += 1
		push_error("FAIL: %s shotgun at4000px/s skips a2px obstacle (%d pellets remain)" % ["police" if police else "player", remaining])
	else:
		print("PASS: %s fast shotgun stops at thin obstacle" % ["police" if police else "player"])
	level.queue_free()
	await process_frame

func press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame
	await physics_frame


## Story 16 posts 24 police in the level. This suite exercises one policeman's
## mechanics (or player navigation), so only Enemy1 is kept to stop the rest of
## the roster from seeing, shooting or blocking shots aimed at the subject.
func _keep_only_enemy1(level: Node) -> void:
	for policeman in get_nodes_in_group("police"):
		if level.is_ancestor_of(policeman) and policeman.name != &"Enemy1":
			policeman.get_parent().remove_child(policeman)
			policeman.free()
