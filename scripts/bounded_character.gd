class_name BoundedCharacter
extends CharacterBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


# Keeps the entire rectangular collision shape inside the viewport.
func _clamp_to_viewport() -> void:
	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle == null:
		return

	var half_size := rectangle.size * 0.5
	var minimum_offset := collision_shape.position - half_size
	var maximum_offset := collision_shape.position + half_size
	var viewport_rect := get_viewport_rect()

	global_position.x = clampf(
		global_position.x,
		viewport_rect.position.x - minimum_offset.x,
		viewport_rect.end.x - maximum_offset.x
	)
	global_position.y = clampf(
		global_position.y,
		viewport_rect.position.y - minimum_offset.y,
		viewport_rect.end.y - maximum_offset.y
	)
