class_name Player
extends CharacterBody2D

signal died

const PistolProjectileScene := preload("res://scenes/pistol_projectile.tscn")
const FRONT_SPRITE_SCALE := Vector2(0.036772487, 0.033333333)
const ACTION_SPRITE_SCALE := Vector2(0.075, 0.075)
const SKIN_BASE_POSITION := Vector2(0.0, -1.0)
const SIDE_MUZZLE_OFFSET := Vector2(21.0, -13.0)
const REAR_MUZZLE_OFFSET := Vector2(11.0, -16.0)
const CHOKE_DURATION := 3.0
const CHOKE_DISTANCE := 64.0

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

var _choke_target: Enemy
var _choke_elapsed := 0.0
var _choke_requires_release := false
var is_dead := false
var motivation := 100
var pistol_magazines = 0
var pistol_bullet = 12

const MAX_MAG = 3
const MAX_PISTOL_BULLET = 12
const MAX_MOTIVATION = 100

var shotgun_magazines: int = 0
var ak47_magazines: int = 0

const MAX_MAGAZINES_PER_WEAPON := 4


@onready var aim_pivot: Node2D = $AimPivot
@onready var muzzle: Marker2D = $Muzzle
@onready var skin: AnimatedSprite2D = $skin
@onready var stats_label: Label = $CanvasLayer/StatsLabel

func _process(_delta: float) -> void:
	$CanvasLayer/MotivationBar.value = motivation
	$CanvasLayer/ChokeProgress.value = _choke_elapsed
	$CanvasLayer/ChokeProgress.visible = _choke_elapsed > 0.0
	$CanvasLayer/ChokeLabel.visible = _choke_elapsed > 0.0
	stats_label.text = "motivation: %d/%d" % [motivation, MAX_MOTIVATION]
	#test
	stats_label.text += "\nShotgun magazines: " + str(shotgun_magazines)
	stats_label.text += "\nAK-47 magazines: " + str(ak47_magazines)
	
	
	if active_weapon == &"pistol":
		stats_label.text += "\nPistol magazines: %d/%d" % [
			pistol_magazines,
			MAX_MAG
		]
		stats_label.text += "\nPistol bullets: %d/%d" % [
			pistol_bullet,
			MAX_PISTOL_BULLET
		]
		


func _ready() -> void:
	$CanvasLayer/RestartButton.pressed.connect(_restart_level)
	skin.animation_finished.connect(_on_skin_animation_finished)
	skin.frame_changed.connect(_update_skin_frame_offset)
	_show_stationary_pose()


func _input(event: InputEvent) -> void:
	if is_dead or event is not InputEventMouseMotion:
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
	if is_dead:
		return
	if _update_choke(delta):
		velocity = Vector2.ZERO
		_update_movement_animation(Vector2.ZERO)
		return
	_pistol_cooldown_remaining = maxf(_pistol_cooldown_remaining - delta, 0.0)
	if Input.is_action_just_pressed("interact"):
		_acquire_nearest_weapon()
		_collect_nearest_magazine()
	if (
		Input.is_action_just_pressed("shoot")
		and active_weapon == &"pistol"
		and pistol_bullet > 0
		and is_zero_approx(_pistol_cooldown_remaining)
	):
		_fire_pistol()
		pistol_bullet -= 1
		_pistol_cooldown_remaining = pistol_firing_cadence
	elif Input.is_action_just_pressed("shoot") and active_weapon == &"fists":
		_punch_targeted_policeman()
	if Input.is_action_just_pressed("reload"):
		_reload_pistol()


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
	
func _collect_nearest_magazine() -> void:
	var nearest: Node2D = null
	var nearest_distance := interaction_distance

	for candidate in get_tree().get_nodes_in_group("magazine_pickups"):
		var pickup := candidate as MagazinePickup

		if pickup == null:
			continue

		var distance := global_position.distance_to(
			pickup.global_position
		)

		if distance <= nearest_distance:
			nearest = pickup
			nearest_distance = distance

	if nearest == null:
		return

	match nearest.weapon_type:
		"pistol":
			if active_weapon == &"pistol" and pistol_bullet == -1:
				pistol_bullet = MAX_PISTOL_BULLET
			else:
				if pistol_magazines >= MAX_MAGAZINES_PER_WEAPON - 1:
					return
			pistol_magazines += 1
		"shotgun":
			if shotgun_magazines >= MAX_MAGAZINES_PER_WEAPON - 1:
				return
			shotgun_magazines += 1
		"ak47":
			if ak47_magazines >= MAX_MAGAZINES_PER_WEAPON - 1:
				return
			ak47_magazines += 1
			
	_show_pickup_feedback("Magazine collected!")
	nearest.queue_free()


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


func _punch_targeted_policeman() -> void:
	var attack_direction := Vector2.RIGHT.rotated(aim_pivot.global_rotation)
	var target: Node2D = null
	var closest_distance := 64.0
	for candidate in get_tree().get_nodes_in_group("police"):
		var policeman := candidate as Node2D
		if policeman == null or policeman.get("life_state") != &"living":
			continue
		var offset := policeman.global_position - global_position
		var distance := offset.length()
		if distance > closest_distance or distance == 0.0:
			continue
		if attack_direction.dot(offset / distance) < 0.7:
			continue
		target = policeman
		closest_distance = distance

	if target != null:
		target.call("knock_down")


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


# Called by enemy bullets when they hit the player.
func take_police_projectile_hit() -> void:
	if is_dead:
		return
	_cancel_choke(true)
	motivation = maxi(motivation - 25, 0)
	if motivation == 0:
		is_dead = true
		velocity = Vector2.ZERO
		skin.stop()
		$CanvasLayer/DeathNotice.show()
		$CanvasLayer/RestartButton.show()
		$CanvasLayer/RestartButton.grab_focus()
		died.emit()


# Called by an enemy when the player kills him.
func on_enemy_killed() -> void:
	if is_dead:
		return
	motivation = mini(motivation + 10, MAX_MOTIVATION)



func _reload_pistol() -> void:
	if active_weapon != &"pistol":
		return
	if pistol_magazines <= 0:
		return  # no magazines left
	if pistol_bullet == MAX_PISTOL_BULLET:
		return  # already full, don't waste a magazine

	pistol_magazines -= 1
	pistol_bullet = MAX_PISTOL_BULLET


func _show_pickup_feedback(message: String) -> void:
	var layer := CanvasLayer.new()
	get_tree().root.add_child(layer)

	var label := Label.new()
	label.text = message
	label.position = Vector2(24, 24)
	layer.add_child(label)

	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(layer.queue_free)

func _update_choke(delta: float) -> bool:
	if active_weapon != &"fists" or not Input.is_action_pressed("shoot"):
		_cancel_choke()
		return false
	if _choke_requires_release:
		return false
	if (
		Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")
		or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down")
	):
		var was_choking := is_instance_valid(_choke_target)
		_cancel_choke(true)
		return was_choking
	if _choke_elapsed > 0.0 and (not is_instance_valid(_choke_target) or not _can_choke(_choke_target)):
		_cancel_choke(true)
		return true
	if not is_instance_valid(_choke_target):
		var nearest_distance := CHOKE_DISTANCE
		for node in get_tree().get_nodes_in_group("police"):
			var candidate := node as Enemy
			if not _can_choke(candidate):
				continue
			var distance := global_position.distance_to(candidate.global_position)
			if distance <= nearest_distance:
				_choke_target = candidate
				nearest_distance = distance
	if not is_instance_valid(_choke_target):
		return false
	_choke_elapsed += delta
	if _choke_elapsed >= CHOKE_DURATION:
		_choke_target.kill_permanently()
		_choke_target = null
		_choke_elapsed = 0.0
	return true


func _cancel_choke(require_release: bool = false) -> void:
	_choke_target = null
	_choke_elapsed = 0.0
	_choke_requires_release = require_release and Input.is_action_pressed("shoot")


func _can_choke(candidate: Enemy) -> bool:
	if not is_instance_valid(candidate) or candidate.life_state not in [&"knocked_down", &"recovering"]:
		return false
	if global_position.distance_to(candidate.global_position) > CHOKE_DISTANCE:
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, candidate.global_position)
	query.collision_mask = collision_mask
	query.exclude = [get_rid(), candidate.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _restart_level() -> void:
	if not is_dead:
		return
	$CanvasLayer/RestartButton.disabled = true
	get_tree().call_deferred("reload_current_scene")
