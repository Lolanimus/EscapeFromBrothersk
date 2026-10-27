class_name Enemy
extends BoundedCharacter

signal alerted

const WAYPOINT_REACHED_DISTANCE := 5.0

# whenever the variable is @export_range, 
# you can access it from inside the Godot editor, and change it there.
@export_range(0.0, 1000.0, 1.0) var speed: float = 40.0:
	set(value):
		speed = maxf(value, 0.0)

@export_range(0.0, 2000.0, 1.0) var sight_range: float = 350.0:
	set(value):
		sight_range = maxf(value, 0.0)

@export_range(0.0, 200.0, 1.0) var stop_distance: float = 35.0:
	set(value):
		stop_distance = maxf(value, 0.0)
		
@export_range(1.0, 180.0, 1.0) var vision_angle: float = 90.0

@export_node_path("CharacterBody2D") var target_path: NodePath = ^"../../Player"

@onready var vision: Node2D = get_node_or_null("Vision")
# whenever the variable is @onready,
# it gets initialized shen the node becomes ready
@onready var target: CharacterBody2D = get_node_or_null(target_path) as CharacterBody2D
func _ready() -> void:
	print("Enemy target: ", target)

var is_alerted: bool = false
var life_state: StringName = &"living"






func _physics_process(_delta: float) -> void:
	if life_state == &"dead":
		velocity = Vector2.ZERO
		return

	# 1. MOVEMENT: keep chasing the player
	velocity = Vector2.ZERO

	if target != null:
		var distance := global_position.distance_to(
			target.global_position
		)

		if distance > stop_distance:
			var direction := global_position.direction_to(
				target.global_position
			)
			velocity = direction * speed

	# 2. DETECTION: cone turns red only if player is visible
	var can_see := _can_see_target()

	if can_see != is_alerted:
		is_alerted = can_see

		if vision != null:
			vision.set_alerted(is_alerted)

		if is_alerted:
			alerted.emit()

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
	if target == null or vision == null:
		return false

	# 1. Check distance using the same range as the drawn cone
	var direction: Vector2 = target.global_position - vision.global_position
	var distance: float = direction.length()

	if distance > vision.vision_range:
		return false

	# 2. Check whether the player is inside the triangle
	var forward: Vector2 = Vector2.UP.rotated(vision.global_rotation)
	var half_angle: float = deg_to_rad(vision.vision_angle / 2.0)

	if absf(forward.angle_to(direction.normalized())) > half_angle:
		return false

	# 3. Check whether a wall blocks the view
	var query := PhysicsRayQueryParameters2D.create(
		vision.global_position,
		target.global_position
	)

	query.exclude = [get_rid()]
	query.collision_mask = 4294967295
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		return false

	return result["collider"] == target
