class_name RangedWeapon
extends RefCounted
## Shared shot definitions; callers own input, cooldowns, and ammunition.

class BlastHit:
	extends RefCounted
	var damaged_player := false

const Magazine := preload("res://scripts/MagazinePickup.gd")
const Gunfire := preload("res://scripts/gunfire.gd")
const Feedback := preload("res://scripts/feedback_audio.gd")
const PlayerProjectile := preload("res://scenes/pistol_projectile.tscn")
const PoliceProjectile := preload("res://scenes/enemy_projectile.tscn")

static func capacity(weapon_type: StringName) -> int:
	return Magazine.MAGAZINE_CAPACITIES.get(String(weapon_type), 0)

static func player_cadence(weapon_type: StringName) -> float:
	return {&"pistol": 0.25, &"shotgun": 0.8, &"ak47": 0.1}.get(weapon_type, 0.25)

static func police_cadence(weapon_type: StringName) -> float:
	return {&"pistol": 0.6, &"shotgun": 1.2, &"ak47": 0.1}.get(weapon_type, 0.6)

static func projectile_speed(_weapon_type: StringName) -> float:
	return 1200.0

static func pellet_offsets(weapon_type: StringName) -> Array[float]:
	if weapon_type == &"shotgun":
		return [-10.0, -6.0, -2.0, 2.0, 6.0, 10.0]
	return [0.0]

static func fire(parent: Node, weapon_type: StringName, origin: Vector2, direction: Vector2, speed: float, police: bool = false) -> Array[Node2D]:
	Gunfire.notify(parent, origin)
	Feedback.play_cue(parent, StringName("%s_fire" % weapon_type), origin)
	var projectiles: Array[Node2D] = []
	var blast_hit := BlastHit.new() if police and weapon_type == &"shotgun" else null
	for offset in pellet_offsets(weapon_type):
		var projectile := (PoliceProjectile if police else PlayerProjectile).instantiate() as Area2D
		projectile.set("direction", direction.rotated(deg_to_rad(offset)))
		projectile.set("speed", speed)
		if police:
			projectile.set("blast_hit", blast_hit)
		parent.add_child(projectile)
		projectile.global_position = origin
		projectiles.append(projectile)
	return projectiles
