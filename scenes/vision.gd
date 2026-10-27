
extends Node2D

@export_range(1.0, 180.0, 1.0) var vision_angle: float = 90.0
@export_range(0.0, 2000.0, 1.0) var vision_range: float = 150.0
@export var cone_color: Color = Color(1.0, 0.85, 0.0, 0.35)
@export var alerted_color: Color = Color(1.0, 0.0, 0.0, 0.45)

var is_alerted: bool = false

func set_alerted(value: bool) -> void:
	is_alerted = value
	queue_redraw()
@export_flags_2d_physics var vision_collision_mask: int = 1

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var points := PackedVector2Array()
	var half_angle: float = deg_to_rad(vision_angle / 2.0)
	var segments: int = 64
	var space_state := get_world_2d().direct_space_state

	points.append(Vector2.ZERO)

	for i in range(segments + 1):
		var angle: float = lerp(
			-half_angle,
			half_angle,
			float(i) / float(segments)
		)

		var direction := Vector2(sin(angle), -cos(angle))
		var end_point: Vector2 = global_position + direction * vision_range

		var query := PhysicsRayQueryParameters2D.create(
			global_position,
			end_point
		)
		query.exclude = [get_parent().get_rid()]
		query.collision_mask = vision_collision_mask

		var result: Dictionary = space_state.intersect_ray(query)
		var local_point: Vector2

		if result.is_empty():
			local_point = to_local(end_point)
		else:
			local_point = to_local(result["position"])

		points.append(local_point)

	var current_color: Color = alerted_color if is_alerted else cone_color
	var outline_color: Color = Color.RED if is_alerted else Color.YELLOW

	draw_colored_polygon(points, current_color)
	draw_polyline(points, outline_color, 2.0, true)
