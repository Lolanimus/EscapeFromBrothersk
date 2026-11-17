class_name EnemyProjectile
extends Area2D
## A bullet fired by police. Passes through other policemen, stops at walls,
## and hits the player.

const LIFETIME := 3.0  # bullets that hit nothing disappear after this

var direction := Vector2.RIGHT:
	set(value):
		direction = value.normalized() if not value.is_zero_approx() else Vector2.RIGHT
		rotation = direction.angle()
var speed := 900.0

## Shared by pellets from a single shotgun blast; released with the pellets.
var blast_hit: RefCounted

var _age := 0.0


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
			if not body.is_in_group("police") and (body is Player or body is StaticBody2D):
				global_position = hit["position"]
				_on_body_entered(body)
				return
			# Friendly bodies do not stop this projectile's swept path.
			var excluded := query.exclude
			excluded.append((body as CollisionObject2D).get_rid())
			query.exclude = excluded
			hit = get_world_2d().direct_space_state.intersect_ray(query)
	global_position = destination
	_age += delta
	if _age >= LIFETIME:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if is_queued_for_deletion():
		return
	if body.is_in_group("police"):
		return  # police bullets pass through other officers
	if body is Player:
		if body.has_method("take_police_projectile_hit") and (blast_hit == null or not blast_hit.get("damaged_player")):
			if blast_hit != null:
				blast_hit.set("damaged_player", true)
			body.call("take_police_projectile_hit")
		queue_free()
	elif body is StaticBody2D:
		queue_free()
