class_name Enemy
extends BoundedCharacter

# whenever the variable is @export_range, 
# you can access it from inside the Godot editor, and change it there.
@export_range(0.0, 1000.0, 1.0) var speed: float = 160.0:
	set(value):
		speed = maxf(value, 0.0)

@export_range(0.0, 2000.0, 1.0) var sight_range: float = 350.0:
	set(value):
		sight_range = maxf(value, 0.0)

@export_range(0.0, 200.0, 1.0) var stop_distance: float = 35.0:
	set(value):
		stop_distance = maxf(value, 0.0)

@export_node_path("CharacterBody2D") var target_path: NodePath = ^"../../Player"

# whenever the variable is @onready,
# it gets initialized shen the node becomes ready
@onready var target: CharacterBody2D = get_node_or_null(target_path) as CharacterBody2D


func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO

	if target != null and _can_see_target():
		var distance_to_target := global_position.distance_to(target.global_position)
		if distance_to_target > stop_distance:
			velocity = global_position.direction_to(target.global_position) * speed

	move_and_slide()
	_clamp_to_viewport()

func _can_see_target() -> bool:
	if global_position.distance_squared_to(target.global_position) > sight_range * sight_range:
		return false

	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask

	var result := get_world_2d().direct_space_state.intersect_ray(query)
	return result.is_empty() or result.get("collider") == target
