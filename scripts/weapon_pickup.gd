class_name WeaponPickup
extends Area2D

@export var weapon_type: StringName = &"pistol"
## Negative means a fresh full magazine; zero preserves an empty dropped gun.
@export var loaded_rounds: int = -1
