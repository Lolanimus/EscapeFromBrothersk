class_name EnemyGun
extends Node2D
## A policeman's gun. Add it as a child of the Enemy, named "Gun".
## Optional children:
##   Sprite2D "Sprite" - the gun picture (Pistol.png)
##   Marker2D "Muzzle" - where bullets come out (place it at the barrel tip)

const EnemyProjectileScene := preload("res://scenes/enemy_projectile.tscn")

## Seconds between shots.
@export_range(0.05, 10.0, 0.01) var fire_cadence: float = 1.0
## Seconds to wait after the player enters the cone before the first shot.
@export_range(0.0, 10.0, 0.01) var first_shot_delay: float = 0.0
## Bullet speed in pixels per second.
@export_range(0.0, 4000.0, 1.0) var projectile_speed: float = 900.0
## How far in front of the gun bullets appear if there is no Muzzle node.
@export_range(0.0, 200.0, 1.0) var muzzle_distance: float = 24.0
## Pistol.png has its barrel pointing left, so it gets flipped to point right.
@export var sprite_points_left: bool = true

var _trigger_held := false
var _cooldown := 0.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D
@onready var muzzle: Marker2D = get_node_or_null("Muzzle") as Marker2D


func _ready() -> void:
	if sprite != null:
		sprite.flip_h = sprite_points_left


## Points the gun at a position in the world.
func aim_at(world_point: Vector2) -> void:
	var to_point := world_point - global_position
	if to_point.is_zero_approx():
		return
	global_rotation = to_point.angle()
	# Keep the gun the right way up when it points left.
	scale.y = -1.0 if to_point.x < 0.0 else 1.0


## true = keep shooting, false = stop.
func set_trigger(held: bool) -> void:
	if held and not _trigger_held:
		_cooldown = maxf(_cooldown, first_shot_delay)
	_trigger_held = held


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _trigger_held and is_zero_approx(_cooldown):
		fire()
		_cooldown = fire_cadence


## Fires one bullet in the direction the gun is pointing.
func fire() -> void:
	var shot_direction := Vector2.RIGHT.rotated(global_rotation)
	var spawn_position := global_position + shot_direction * muzzle_distance
	if muzzle != null:
		spawn_position = muzzle.global_position

	var projectile := EnemyProjectileScene.instantiate() as Area2D
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_position
	projectile.set("direction", shot_direction)
	projectile.set("speed", projectile_speed)
