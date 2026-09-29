class_name Player
extends Node2D

@export_range(0.0, 1000.0, 1.0) var speed: float = 280.0:
	set(value):
		speed = maxf(value, 0.0)

const RADIUS: float = 18.0


func _process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var next_position := position + direction * speed * delta
	var viewport_size := get_viewport_rect().size
	next_position.x = clampf(next_position.x, RADIUS, viewport_size.x - RADIUS)
	next_position.y = clampf(next_position.y, RADIUS, viewport_size.y - RADIUS)
	position = next_position


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + 5.0, Color(0.12, 0.2, 0.34, 0.8))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.22, 0.66, 1.0))
	draw_circle(Vector2(-5.0, -4.0), 3.0, Color(0.92, 0.97, 1.0))
