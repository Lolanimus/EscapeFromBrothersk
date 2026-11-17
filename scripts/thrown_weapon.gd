extends "res://scripts/weapon_pickup.gd"

var _direction := Vector2.RIGHT
var _speed := 800.0
var _source: CollisionObject2D
var _flying := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.polygon = PackedVector2Array([
		Vector2(-15, -4), Vector2(15, -4), Vector2(15, 4),
		Vector2(-4, 4), Vector2(-4, 10), Vector2(-10, 10),
	])
	visual.color = Color(0.75, 0.8, 0.85)
	add_child(visual)


func launch(direction: Vector2, speed: float, source: CollisionObject2D = null) -> void:
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	_speed = maxf(speed, 0.0)
	_source = source
	_flying = true
	rotation = _direction.angle()
	add_to_group("thrown_weapons")
	remove_from_group("weapon_pickups")


func _physics_process(delta: float) -> void:
	if not _flying:
		return
	var destination := global_position + _direction * _speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, destination, 11)
	if is_instance_valid(_source):
		query.exclude = [_source.get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = destination
		return
	global_position = hit.position
	var body: Node = hit.collider
	if body.is_in_group("police") and body.has_method("knock_down"):
		body.knock_down()
	_flying = false
	remove_from_group("thrown_weapons")
	add_to_group("weapon_pickups")
	var cue := Label.new()
	cue.name = "ImpactFeedback"
	cue.text = "IMPACT"
	cue.position = Vector2(-26, -32)
	cue.rotation = -rotation
	cue.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	add_child(cue)
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(cue.queue_free)
