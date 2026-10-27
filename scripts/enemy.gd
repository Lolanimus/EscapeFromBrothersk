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
@onready var vision: Node2D = get_node_or_null("Vision")
@onready var gun: EnemyGun = get_node_or_null("Gun") as EnemyGun

var is_alerted: bool = false
var life_state: StringName = &"living"


func _physics_process(delta: float) -> void:
	if life_state == &"dead":
		velocity = Vector2.ZERO
		return

	velocity = Vector2.ZERO

	if vision != null and target != null:
		vision.face_point(target.global_position, delta)

	var player_in_cone := _is_player_inside_cone()

	# Red only while the player is inside the drawn cone.
	if vision != null:
		vision.set_alerted(player_in_cone)

	# Point the gun at the player, and shoot only while he is in the cone.
	if gun != null:
		if target != null:
			gun.aim_at(target.global_position)
		gun.set_trigger(player_in_cone)

	if target != null and not is_alerted and _can_see_target():
		is_alerted = true
		alerted.emit()

	# Chase the player, but stand still while he is in the cone (shooting).
	if target != null and is_alerted and not player_in_cone:
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
	if gun != null:
		gun.set_trigger(false)
	set_physics_process(false)

	if target != null and target.has_method("on_enemy_killed"):
		target.on_enemy_killed()


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


func _is_player_inside_cone() -> bool:
	if target == null or vision == null:
		return false

	var to_player := target.global_position - vision.global_position

	# Further away than the cone reaches?
	if to_player.length() > vision.vision_range:
		return false

	# Outside the cone's angle? The cone points "up" in its own space.
	var forward := Vector2.UP.rotated(vision.global_rotation)
	if absf(forward.angle_to(to_player)) > deg_to_rad(vision.vision_angle / 2.0):
		return false

	# Behind a wall that cuts the cone short?
	var query := PhysicsRayQueryParameters2D.create(vision.global_position, target.global_position)
	query.exclude = [get_rid()]
	query.collision_mask = vision.vision_collision_mask
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()
