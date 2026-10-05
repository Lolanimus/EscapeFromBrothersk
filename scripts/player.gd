class_name Player
extends CharacterBody2D

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
