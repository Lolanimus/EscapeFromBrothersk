extends Camera2D

@export_range(0.0, 500.0, 1.0) var look_ahead_distance: float = 80.0


func _input(event: InputEvent) -> void:
	if event is not InputEventMouseMotion:
		return

	var mouse_motion := event as InputEventMouseMotion
	var viewport_center: Vector2 = get_viewport_rect().size * 0.5
	var cursor_offset: Vector2 = mouse_motion.position - viewport_center
	offset = cursor_offset.limit_length(look_ahead_distance)
