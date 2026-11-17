
class_name MagazinePickup
extends Area2D

@export_enum("pistol", "shotgun", "ak47")
var weapon_type: String = "pistol"

const MAGAZINE_CAPACITIES := {
	"pistol": 12,
	"shotgun": 6,
	"ak47": 31
}

func _ready() -> void:
	add_to_group("magazine_pickups")


func get_magazine_capacity() -> int:
	return MAGAZINE_CAPACITIES.get(weapon_type, 0)
