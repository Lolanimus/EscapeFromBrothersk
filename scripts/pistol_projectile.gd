class_name PistolProjectile
extends Area2D

var direction := Vector2.RIGHT
var speed := 1200.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("police") and body.has_method("take_player_projectile_hit"):
		body.call("take_player_projectile_hit")
		queue_free()
	elif body is StaticBody2D:
		queue_free()
