class_name PistolProjectile
extends Area2D

var direction := Vector2.RIGHT:
	set(value):
		direction = value.normalized() if not value.is_zero_approx() else Vector2.RIGHT
		rotation = direction.angle()
var speed := 1200.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	var destination := global_position + direction * speed * delta
	if not global_position.is_equal_approx(destination):
		var query := PhysicsRayQueryParameters2D.create(global_position, destination, collision_mask)
		query.exclude = [get_rid()]
		query.hit_from_inside = true
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		while not hit.is_empty():
			var body := hit["collider"] as Node2D
			if body is StaticBody2D or (body.is_in_group("police") and body.has_method("take_player_projectile_hit")):
				global_position = hit["position"]
				_on_body_entered(body)
				return
			# Friendly bodies do not stop this projectile's swept path.
			var excluded := query.exclude
			excluded.append((body as CollisionObject2D).get_rid())
			query.exclude = excluded
			hit = get_world_2d().direct_space_state.intersect_ray(query)
	global_position = destination


func _on_body_entered(body: Node2D) -> void:
	if is_queued_for_deletion():
		return
	if body.is_in_group("police") and body.has_method("take_player_projectile_hit"):
		body.call("take_player_projectile_hit")
		queue_free()
	elif body is StaticBody2D:
		queue_free()
