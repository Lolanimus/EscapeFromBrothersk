extends SceneTree

const GameplayScene := preload("res://scenes/main.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	for weapon in ["Shotgun", "AK47"]:
		var level := GameplayScene.instantiate()
		root.add_child(level)
		current_scene = level
		await process_frame
		for enemy in get_nodes_in_group("police"):
			enemy.set_physics_process(false)
			enemy.get_node("Gun").set_physics_process(false)
		var player = level.get_node("Player")
		player.global_position = level.get_node("Pickups/" + weapon).global_position
		for frame in range(3):
			await physics_frame
		Input.action_press("interact")
		await physics_frame
		Input.action_release("interact")
		await physics_frame
		for aim in [Vector2.LEFT, Vector2.RIGHT, Vector2(-1, -0.5), Vector2(-1, 0.5)]:
			var motion := InputEventMouseMotion.new()
			motion.position = root.get_screen_transform() * (player.get_global_transform_with_canvas() * Vector2.ZERO + aim * 250.0)
			motion.global_position = motion.position
			Input.parse_input_event(motion)
			await process_frame
			await physics_frame
			await process_frame
			var held := player.get_node("AimPivot/HeldGun") as Sprite2D
			# Texture top must stay above its grip in world space on either side.
			var texture_up := Vector2.DOWN if held.flip_v else Vector2.UP
			var visible_up := held.global_transform.basis_xform(texture_up).normalized()
			var barrel := Vector2.RIGHT.rotated(player.get_node("AimPivot").global_rotation)
			if held.visible and barrel.dot(aim.normalized()) > 0.99 and visible_up.y < -0.5:
				print("PASS: %s stays upright aiming %s" % [weapon, aim])
			else:
				failures += 1
				push_error("FAIL: %s turns upside down aiming %s" % [weapon, aim])
		level.queue_free()
		await process_frame
	quit(failures)
