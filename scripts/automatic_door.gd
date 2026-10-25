extends Node2D

signal opened

@export var opening_size := Vector2(20.0, 100.0)
@export var trigger_size := Vector2(140.0, 140.0)

var is_open := false
var _barrier_shape: CollisionShape2D
var _visual: Polygon2D


func _ready() -> void:
	add_to_group("automatic_doors")

	var barrier := StaticBody2D.new()
	barrier.collision_layer = 8
	barrier.collision_mask = 0
	_barrier_shape = CollisionShape2D.new()
	var barrier_rectangle := RectangleShape2D.new()
	barrier_rectangle.size = opening_size
	_barrier_shape.shape = barrier_rectangle
	barrier.add_child(_barrier_shape)
	add_child(barrier)

	_visual = Polygon2D.new()
	var half_size := opening_size * 0.5
	_visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		half_size,
		Vector2(-half_size.x, half_size.y),
	])
	_visual.color = Color(0.68, 0.58, 0.32, 1.0)
	_visual.z_index = -1
	add_child(_visual)

	var proximity_area := Area2D.new()
	proximity_area.collision_layer = 0
	proximity_area.collision_mask = 2
	var proximity_shape := CollisionShape2D.new()
	var proximity_rectangle := RectangleShape2D.new()
	proximity_rectangle.size = trigger_size
	proximity_shape.shape = proximity_rectangle
	proximity_area.add_child(proximity_shape)
	proximity_area.body_entered.connect(_on_proximity_body_entered)
	add_child(proximity_area)


func _on_proximity_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("police"):
		_open()


func _open() -> void:
	if is_open:
		return

	is_open = true
	_barrier_shape.set_deferred("disabled", true)
	_visual.visible = false
	opened.emit()
