class_name Enemy
extends BoundedCharacter

signal alerted

const WAYPOINT_REACHED_DISTANCE := 5.0

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

var is_alerted: bool = false
var life_state: StringName = &"living"


func _physics_process(_delta: float) -> void:
	if life_state == &"dead":
		velocity = Vector2.ZERO
		return

	velocity = Vector2.ZERO

	if target != null and not is_alerted and _can_see_target():
		is_alerted = true
		alerted.emit()

	if target != null and is_alerted:
		var distance_to_target := global_position.distance_to(target.global_position)
		if distance_to_target > stop_distance:
			var pursuit_position := _get_next_pursuit_position()
			velocity = global_position.direction_to(pursuit_position) * speed

	move_and_slide()


func take_player_projectile_hit() -> void:
	if life_state != &"living" and life_state != &"knocked_down":
		return

	life_state = &"dead"
	is_alerted = false
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	modulate = Color(0.35, 0.35, 0.35, 1.0)
	set_physics_process(false)


func _get_next_pursuit_position() -> Vector2:
	var navigation_host := get_parent()
	while navigation_host != null and not navigation_host.has_method("get_navigation_path"):
		navigation_host = navigation_host.get_parent()

	if navigation_host == null:
		return target.global_position

	var path: PackedVector2Array = navigation_host.call(
		"get_navigation_path",
		global_position,
		target.global_position
	)
	for point_index in range(1, path.size()):
		var waypoint := path[point_index]
		if global_position.distance_to(waypoint) > WAYPOINT_REACHED_DISTANCE:
			return waypoint

	return target.global_position

func _can_see_target() -> bool:
	if global_position.distance_squared_to(target.global_position) > sight_range * sight_range:
		return false

	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask

	var result := get_world_2d().direct_space_state.intersect_ray(query)
	return result.is_empty() or result.get("collider") == target
