class_name Player
extends CharacterBody2D

const PistolProjectileScene := preload("res://scenes/pistol_projectile.tscn")

@export_range(0.0, 1000.0, 1.0) var speed: float = 280.0:
	set(value):
		speed = maxf(value, 0.0)
@export_range(0.0, 200.0, 1.0) var interaction_distance: float = 64.0
@export_range(0.0, 4000.0, 1.0) var pistol_projectile_speed: float = 1200.0
@export_range(0.0, 10.0, 0.01) var pistol_firing_cadence: float = 0.25

var active_weapon: StringName = &"fists"
var _pistol_cooldown_remaining := 0.0

@onready var aim_pivot: Node2D = $AimPivot
@onready var upper_fist: Polygon2D = $AimPivot/UpperFist
@onready var lower_fist: Polygon2D = $AimPivot/LowerFist
@onready var pistol_visual: Polygon2D = $AimPivot/Pistol


func _input(event: InputEvent) -> void:
	if event is not InputEventMouseMotion:
		return

	var mouse_motion := event as InputEventMouseMotion
	var player_viewport_position: Vector2 = get_global_transform_with_canvas() * Vector2.ZERO
	var cursor_direction := mouse_motion.position - player_viewport_position
	aim_pivot.global_rotation = cursor_direction.angle()


func _physics_process(delta: float) -> void:
	_pistol_cooldown_remaining = maxf(_pistol_cooldown_remaining - delta, 0.0)
	if Input.is_action_just_pressed("interact"):
		_acquire_nearest_weapon()
	if (
		Input.is_action_just_pressed("shoot")
		and active_weapon == &"pistol"
		and is_zero_approx(_pistol_cooldown_remaining)
	):
		_fire_pistol()
		_pistol_cooldown_remaining = pistol_firing_cadence

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()


func _acquire_nearest_weapon() -> void:
	var nearest_pickup: Node2D = null
	var nearest_distance := interaction_distance
	for candidate in get_tree().get_nodes_in_group("weapon_pickups"):
		var pickup := candidate as Node2D
		if pickup == null:
			continue
		var distance := global_position.distance_to(pickup.global_position)
		if distance <= nearest_distance:
			nearest_pickup = pickup
			nearest_distance = distance

	if nearest_pickup == null:
		return

	active_weapon = StringName(nearest_pickup.get("weapon_type"))
	upper_fist.visible = active_weapon != &"pistol"
	lower_fist.visible = active_weapon != &"pistol"
	pistol_visual.visible = active_weapon == &"pistol"
	nearest_pickup.queue_free()


func _fire_pistol() -> void:
	var projectile := PistolProjectileScene.instantiate() as Area2D
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = aim_pivot.global_position
	projectile.set("direction", Vector2.RIGHT.rotated(aim_pivot.global_rotation))
	projectile.set("speed", pistol_projectile_speed)
