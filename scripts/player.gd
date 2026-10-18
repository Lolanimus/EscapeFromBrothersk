class_name Player
extends CharacterBody2D

@export_range(0.0, 1000.0, 1.0) var speed: float = 280.0:
	set(value):
		speed = maxf(value, 0.0)

var active_weapon: StringName = &"fists"

@onready var aim_pivot: Node2D = $AimPivot


func _input(event: InputEvent) -> void:
	if event is not InputEventMouseMotion:
		return

	var mouse_motion := event as InputEventMouseMotion
	var player_viewport_position: Vector2 = get_global_transform_with_canvas() * Vector2.ZERO
	var cursor_direction := mouse_motion.position - player_viewport_position
	aim_pivot.global_rotation = cursor_direction.angle()


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
