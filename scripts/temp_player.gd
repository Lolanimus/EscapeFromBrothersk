
extends CharacterBody2D

@export var speed: float = 100.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	print("=== PLAYER INITIALIZED ===")
	print("Collision Layer: ", collision_layer)
	print("Collision Mask: ", collision_mask)
	print("Starting Position: ", global_position)


func _physics_process(_delta: float) -> void:
	var direction = Vector2.ZERO

	# WASD Movement
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1

	if Input.is_key_pressed(KEY_S):
		direction.y += 1

	if Input.is_key_pressed(KEY_A):
		direction.x -= 1

	if Input.is_key_pressed(KEY_D):
		direction.x += 1

	# Normalize movement to prevent faster diagonal speed
	direction = direction.normalized()

	# Move the CharacterBody2D using physics
	velocity = direction * speed
	move_and_slide()

	# Print position while moving
	if direction != Vector2.ZERO:
		print("Direction: ", direction)
		print("Player Position: ", global_position)

	# Check for collisions
	if get_slide_collision_count() > 0:
		print("=== COLLISION DETECTED! ===")

		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			print("Collided with: ", collision.get_collider())


func _input(event: InputEvent) -> void:
	# Press T to test for a wall to the right
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			test_wall_detection()


func test_wall_detection() -> void:
	var space_state = get_world_2d().direct_space_state

	var start = global_position
	var end = global_position + Vector2(100, 0)

	var query = PhysicsRayQueryParameters2D.create(start, end)

	# Detect physics objects on layer 1
	query.collision_mask = 1

	# Ignore the player itself
	query.exclude = [get_rid()]

	var result = space_state.intersect_ray(query)

	if result.is_empty():
		print("T TEST: No physics object detected to the right")
	else:
		print("T TEST: Hit ", result["collider"])
		print("Hit Position: ", result["position"])
