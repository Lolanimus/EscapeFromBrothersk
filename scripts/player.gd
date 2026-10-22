class_name Player
extends CharacterBody2D

const PistolProjectileScene := preload("res://scenes/pistol_projectile.tscn")
const FRONT_SPRITE_SCALE := Vector2(0.036772487, 0.033333333)
const ACTION_SPRITE_SCALE := Vector2(0.075, 0.075)
const SKIN_BASE_POSITION := Vector2(0.0, -1.0)
const SIDE_MUZZLE_OFFSET := Vector2(21.0, -13.0)
const REAR_MUZZLE_OFFSET := Vector2(11.0, -16.0)

@export_range(0.0, 1000.0, 1.0) var speed: float = 280.0:
	set(value):
		speed = maxf(value, 0.0)
@export_range(0.0, 200.0, 1.0) var interaction_distance: float = 64.0
@export_range(0.0, 4000.0, 1.0) var pistol_projectile_speed: float = 1200.0
@export_range(0.0, 10.0, 0.01) var pistol_firing_cadence: float = 0.25

var active_weapon: StringName = &"fists"
var _pistol_cooldown_remaining := 0.0
var _pistol_animation_playing := false
var _last_facing: StringName = &"side"
var _last_side_faces_right := false

@onready var aim_pivot: Node2D = $AimPivot
@onready var muzzle: Marker2D = $Muzzle
@onready var skin: AnimatedSprite2D = $skin


func _ready() -> void:
	skin.animation_finished.connect(_on_skin_animation_finished)
	skin.frame_changed.connect(_update_skin_frame_offset)
	_show_stationary_pose()


func _input(event: InputEvent) -> void:
	if event is not InputEventMouseMotion:
		return

	var mouse_motion := event as InputEventMouseMotion
	var player_viewport_position: Vector2 = get_global_transform_with_canvas() * Vector2.ZERO
	var cursor_direction := mouse_motion.position - player_viewport_position
	aim_pivot.global_rotation = cursor_direction.angle()
	if cursor_direction.y < 0.0 and absf(cursor_direction.y) >= absf(cursor_direction.x):
		_last_facing = &"up"
	else:
		_last_facing = &"side"
		_last_side_faces_right = cursor_direction.x > 0.0
	if velocity.is_zero_approx() and not _pistol_animation_playing:
		_show_stationary_pose()


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
	_update_movement_animation(direction)
	move_and_slide()


func _update_movement_animation(direction: Vector2) -> void:
	if _pistol_animation_playing:
		return

	if direction.y < 0.0 and absf(direction.y) >= absf(direction.x):
		_last_facing = &"up"
		skin.scale = ACTION_SPRITE_SCALE
		skin.position = SKIN_BASE_POSITION
		skin.flip_h = false
		if skin.animation != &"walk_up" or not skin.is_playing():
			skin.play(&"walk_up")
		return

	if not is_zero_approx(direction.x):
		_last_facing = &"side"
		_last_side_faces_right = direction.x > 0.0
		skin.scale = ACTION_SPRITE_SCALE
		skin.position = SKIN_BASE_POSITION
		skin.flip_h = _last_side_faces_right
		if skin.animation != &"walk_side" or not skin.is_playing():
			skin.play(&"walk_side")
		return

	if direction.y > 0.0:
		skin.scale = FRONT_SPRITE_SCALE
		skin.flip_h = false
		if skin.animation != &"walk_down" or not skin.is_playing():
			skin.play(&"walk_down")
		_update_skin_frame_offset()
		return

	_show_stationary_pose()


func _show_stationary_pose() -> void:
	skin.scale = ACTION_SPRITE_SCALE
	skin.position = SKIN_BASE_POSITION
	skin.flip_h = _last_facing != &"up" and _last_side_faces_right
	skin.stop()
	if active_weapon == &"pistol":
		skin.animation = &"idle_pistol_up" if _last_facing == &"up" else &"idle_pistol_side"
	else:
		skin.animation = &"idle_fists_up" if _last_facing == &"up" else &"idle_fists_side"
	skin.frame = 0


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
	nearest_pickup.queue_free()
	_update_movement_animation(
		Input.get_vector("move_left", "move_right", "move_up", "move_down")
	)


func _fire_pistol() -> void:
	var shot_direction := Vector2.RIGHT.rotated(aim_pivot.global_rotation)
	var aims_up := shot_direction.y < 0.0 and absf(shot_direction.y) >= absf(shot_direction.x)
	var fire_animation: StringName = &"fire_pistol_up" if aims_up else &"fire_pistol_side"
	_pistol_animation_playing = true
	skin.scale = ACTION_SPRITE_SCALE
	skin.position = SKIN_BASE_POSITION
	skin.flip_h = not aims_up and shot_direction.x > 0.0
	skin.play(fire_animation)
	if aims_up:
		muzzle.position = REAR_MUZZLE_OFFSET
	else:
		muzzle.position = Vector2(
			SIDE_MUZZLE_OFFSET.x if shot_direction.x > 0.0 else -SIDE_MUZZLE_OFFSET.x,
			SIDE_MUZZLE_OFFSET.y
		)

	var projectile := PistolProjectileScene.instantiate() as Area2D
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.set("direction", shot_direction)
	projectile.set("speed", pistol_projectile_speed)


func _on_skin_animation_finished() -> void:
	if skin.animation != &"fire_pistol_side" and skin.animation != &"fire_pistol_up":
		return

	_pistol_animation_playing = false
	_update_movement_animation(
		Input.get_vector("move_left", "move_right", "move_up", "move_down")
	)


func _update_skin_frame_offset() -> void:
	skin.position = SKIN_BASE_POSITION
	if skin.animation == &"walk_down":
		skin.position.y += -1.0 if skin.frame == 0 else 1.0
