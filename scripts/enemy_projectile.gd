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

var _age := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta
	if _age >= LIFETIME:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("police"):
		return  # police bullets pass through other officers
	if body is Player:
		if body.has_method("take_police_projectile_hit"):
			body.call("take_police_projectile_hit")
		queue_free()
	elif body is StaticBody2D:
		queue_free()
