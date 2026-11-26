class_name Player
extends CharacterBody2D

signal died

const RangedWeapon := preload("res://scripts/ranged_weapon.gd")
const ThrownWeaponScript := preload("res://scripts/thrown_weapon.gd")
const SHOTGUN_TEXTURE := preload("res://assets/sprites/weapon/shotgun.png")
const AK47_TEXTURE := preload("res://assets/sprites/weapon/ak47.png")
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
@export_range(0.0, 4000.0, 1.0) var shotgun_projectile_speed: float = 1200.0
@export_range(0.0, 10.0, 0.01) var shotgun_firing_cadence: float = 0.8
@export_range(0.0, 4000.0, 1.0) var ak47_projectile_speed: float = 1200.0
@export_range(0.0, 10.0, 0.01) var ak47_firing_cadence: float = 0.1
@export_range(0.0, 4000.0, 1.0) var thrown_weapon_speed: float = 800.0

var active_weapon: StringName = &"fists"
## The one carried gun (&"" when none); fists are always available besides it.
var carried_ranged_weapon: StringName = &""
## The one carried melee weapon (&"katana"), or &"" so fists fill the melee side.
var carried_melee_weapon: StringName = &""
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
var shotgun_bullet: int = 6
var ak47_bullet: int = 31
var _held_gun: Sprite2D

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
	stats_label.text += "\nShotgun magazines: " + str(shotgun_magazines)
	stats_label.text += "\nAK-47 magazines: " + str(ak47_magazines)
	stats_label.text += "\nActive: " + String(active_weapon)
	if active_weapon in [&"pistol", &"shotgun", &"ak47"]:
		stats_label.text += "\nLoaded: %d/%d" % [get_loaded_rounds(), RangedWeapon.capacity(active_weapon)]
		if get_loaded_rounds() == 0:
			stats_label.text += " EMPTY"
	
	
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
	_held_gun = Sprite2D.new()
	_held_gun.name = "HeldGun"
	_held_gun.position = Vector2(15.0, 0.0)
	_held_gun.flip_h = true
	_held_gun.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	aim_pivot.add_child(_held_gun)
	_update_held_gun()
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
	_held_gun.flip_v = cursor_direction.x < 0.0
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
	if Input.is_action_just_pressed("throw_weapon"):
		_throw_active_weapon()
	if Input.is_action_just_pressed("switch_weapon"):
		_switch_weapon()
	if (
		(Input.is_action_pressed("shoot") if active_weapon == &"ak47" else Input.is_action_just_pressed("shoot"))
		and active_weapon in [&"pistol", &"shotgun", &"ak47"]
		and get_loaded_rounds() > 0
		and is_zero_approx(_pistol_cooldown_remaining)
	):
		if active_weapon == &"pistol":
			_fire_pistol()
		else:
			var shot_direction := Vector2.RIGHT.rotated(aim_pivot.global_rotation)
			var projectile_speed := shotgun_projectile_speed if active_weapon == &"shotgun" else ak47_projectile_speed
			RangedWeapon.fire(get_tree().current_scene, active_weapon, global_position + shot_direction * 24.0, shot_direction, projectile_speed)
		_set_loaded_rounds(active_weapon, get_loaded_rounds() - 1)
		match active_weapon:
			&"pistol": _pistol_cooldown_remaining = pistol_firing_cadence
			&"shotgun": _pistol_cooldown_remaining = shotgun_firing_cadence
			&"ak47": _pistol_cooldown_remaining = ak47_firing_cadence
	elif Input.is_action_just_pressed("shoot") and active_weapon == &"fists":
		_punch_targeted_policeman()
	if Input.is_action_just_pressed("reload"):
		_reload_active_weapon()


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

	var incoming_type := StringName(nearest_pickup.get("weapon_type"))
	var rounds := int(nearest_pickup.get("loaded_rounds"))
	if incoming_type == &"katana":
		_acquire_katana(nearest_pickup)
		return
	if incoming_type == carried_ranged_weapon:
		_collect_duplicate_magazine(nearest_pickup)
		return
	if rounds != 0 and _get_reserve_magazines(incoming_type) >= MAX_MAGAZINES_PER_WEAPON:
		return
	_drop_carried_ranged_weapon()
	active_weapon = incoming_type
	carried_ranged_weapon = incoming_type
	_set_loaded_rounds(active_weapon, rounds if rounds >= 0 else RangedWeapon.capacity(active_weapon))
	_update_held_gun()
	nearest_pickup.queue_free()
	_update_movement_animation(
		Input.get_vector("move_left", "move_right", "move_up", "move_down")
	)


# The katana fills the melee slot without touching the carried gun; only one katana exists.
func _acquire_katana(pickup: Node2D) -> void:
	if carried_melee_weapon == &"katana":
		return
	carried_melee_weapon = &"katana"
	active_weapon = &"katana"
	pickup.queue_free()
	_update_held_gun()
	_update_movement_animation(Input.get_vector("move_left", "move_right", "move_up", "move_down"))


# Fists are the melee side of the loadout whenever no katana is carried.
func _melee_weapon() -> StringName:
	return carried_melee_weapon if carried_melee_weapon != &"" else &"fists"


# Swap rule: the replaced gun is left at the player's feet with exactly its loaded rounds,
# while retained magazines stay with the player, so no ammunition is created or destroyed.
func _drop_carried_ranged_weapon() -> void:
	if carried_ranged_weapon == &"":
		return
	var dropped := ThrownWeaponScript.new()
	dropped.weapon_type = carried_ranged_weapon
	dropped.loaded_rounds = _get_loaded_rounds_of(carried_ranged_weapon)
	dropped.position = global_position
	dropped.add_to_group("weapon_pickups")
	# Interaction runs in a physics callback, where adding an Area2D directly is not allowed.
	get_tree().current_scene.add_child.call_deferred(dropped)
	_set_loaded_rounds(carried_ranged_weapon, 0)
	carried_ranged_weapon = &""


# A duplicate of the carried gun only gives up its full magazine; the gun itself stays on the floor.
func _collect_duplicate_magazine(pickup: Node2D) -> void:
	var rounds := int(pickup.get("loaded_rounds"))
	var carried := carried_ranged_weapon
	if rounds >= 0 and rounds != RangedWeapon.capacity(carried):
		return
	var loaded_magazines := 1 if _get_loaded_rounds_of(carried) > 0 else 0
	if _get_reserve_magazines(carried) + loaded_magazines >= MAX_MAGAZINES_PER_WEAPON:
		return
	_set_reserve_magazines(carried, _get_reserve_magazines(carried) + 1)
	pickup.set("loaded_rounds", 0)
	_show_pickup_feedback("Magazine collected!")


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

	var weapon_type := StringName(nearest.weapon_type)
	var loaded_magazines := 1 if carried_ranged_weapon == weapon_type and _get_loaded_rounds_of(weapon_type) > 0 else 0
	if _get_reserve_magazines(weapon_type) + loaded_magazines >= MAX_MAGAZINES_PER_WEAPON:
		return
	_set_reserve_magazines(weapon_type, _get_reserve_magazines(weapon_type) + 1)
			
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

	RangedWeapon.fire(get_tree().current_scene, &"pistol", muzzle.global_position, shot_direction, pistol_projectile_speed)


func get_loaded_rounds() -> int:
	return _get_loaded_rounds_of(active_weapon)


func _get_loaded_rounds_of(weapon_type: StringName) -> int:
	match weapon_type:
		&"pistol": return pistol_bullet
		&"shotgun": return shotgun_bullet
		&"ak47": return ak47_bullet
	return 0


func _set_loaded_rounds(weapon_type: StringName, rounds: int) -> void:
	match weapon_type:
		&"pistol": pistol_bullet = maxi(rounds, 0)
		&"shotgun": shotgun_bullet = maxi(rounds, 0)
		&"ak47": ak47_bullet = maxi(rounds, 0)


func _throw_active_weapon() -> void:
	if active_weapon not in [&"pistol", &"shotgun", &"ak47"]:
		return
	var thrown := ThrownWeaponScript.new()
	thrown.weapon_type = active_weapon
	thrown.loaded_rounds = get_loaded_rounds()
	get_tree().current_scene.add_child(thrown)
	thrown.global_position = global_position
	thrown.launch(Vector2.RIGHT.rotated(aim_pivot.global_rotation), thrown_weapon_speed, self)
	_set_loaded_rounds(active_weapon, 0)
	carried_ranged_weapon = &""
	active_weapon = _melee_weapon()
	_update_held_gun()
	_update_movement_animation(Input.get_vector("move_left", "move_right", "move_up", "move_down"))


# Q toggles between the carried gun and the melee side of the loadout.
func _switch_weapon() -> void:
	if carried_ranged_weapon == &"":
		return
	active_weapon = _melee_weapon() if active_weapon == carried_ranged_weapon else carried_ranged_weapon
	_update_held_gun()
	_update_movement_animation(Input.get_vector("move_left", "move_right", "move_up", "move_down"))


func _update_held_gun() -> void:
	_held_gun.visible = active_weapon in [&"shotgun", &"ak47"]
	if active_weapon == &"shotgun":
		_held_gun.texture = SHOTGUN_TEXTURE
		_held_gun.scale = Vector2(0.05, 0.05)
	elif active_weapon == &"ak47":
		_held_gun.texture = AK47_TEXTURE
		_held_gun.scale = Vector2(0.08, 0.08)


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



func _reload_active_weapon() -> void:
	if active_weapon not in [&"pistol", &"shotgun", &"ak47"]:
		return
	var retained := _get_reserve_magazines(active_weapon)
	if retained <= 0:
		return
	_set_reserve_magazines(active_weapon, retained - 1)
	_set_loaded_rounds(active_weapon, RangedWeapon.capacity(active_weapon))


func _get_reserve_magazines(weapon_type: StringName) -> int:
	match weapon_type:
		&"pistol": return pistol_magazines
		&"shotgun": return shotgun_magazines
		&"ak47": return ak47_magazines
	return 0


func _set_reserve_magazines(weapon_type: StringName, count: int) -> void:
	match weapon_type:
		&"pistol": pistol_magazines = count
		&"shotgun": shotgun_magazines = count
		&"ak47": ak47_magazines = count


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
