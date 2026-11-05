class_name Enemy
extends BoundedCharacter

signal alerted

const WAYPOINT_REACHED_DISTANCE := 5.0
const KNOCKDOWN_DURATION := 15.0
const RECOVERY_WARNING_DURATION := 3.0
const LIVING_COLOR := Color(0.85, 0.12, 0.2, 1.0)
const KNOCKED_DOWN_COLOR := Color(0.42, 0.48, 0.58, 1.0)
const RECOVERING_COLOR := Color(1.0, 0.66, 0.16, 1.0)
const DEAD_COLOR := Color(0.2, 0.22, 0.26, 1.0)

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
var recovery_time_remaining := 0.0

var recovery_warning: Label
var police_visual: Polygon2D


func _ready() -> void:
	recovery_warning = get_node_or_null("RecoveryWarning") as Label
	if recovery_warning == null:
		recovery_warning = Label.new()
		recovery_warning.name = "RecoveryWarning"
		recovery_warning.position = Vector2(-46.0, -48.0)
		recovery_warning.text = "RECOVERING!"
		recovery_warning.add_theme_color_override("font_color", RECOVERING_COLOR)
		recovery_warning.add_theme_font_size_override("font_size", 14)
		add_child(recovery_warning)
	police_visual = get_node_or_null("PoliceVisual") as Polygon2D
	if police_visual == null:
		police_visual = Polygon2D.new()
		police_visual.name = "PoliceVisual"
		police_visual.polygon = PackedVector2Array([
			Vector2(-12.0, -18.0), Vector2(12.0, -18.0), Vector2(18.0, -10.0),
			Vector2(18.0, 10.0), Vector2(12.0, 18.0), Vector2(-12.0, 18.0),
			Vector2(-18.0, 10.0), Vector2(-18.0, -10.0),
		])
		add_child(police_visual)
	recovery_warning.visible = false
	_update_state_presentation()


func _process(delta: float) -> void:
	if life_state != &"knocked_down" and life_state != &"recovering":
		return

	recovery_time_remaining = maxf(recovery_time_remaining - delta, 0.0)
	if is_zero_approx(recovery_time_remaining):
		life_state = &"living"
		recovery_warning.visible = false
		_update_state_presentation()
	elif recovery_time_remaining <= RECOVERY_WARNING_DURATION:
		if life_state != &"recovering":
			life_state = &"recovering"
			recovery_warning.visible = true
			_update_state_presentation()


func _physics_process(_delta: float) -> void:
	if life_state == &"dead" or life_state == &"knocked_down" or life_state == &"recovering":
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
	if life_state != &"living" and life_state != &"knocked_down" and life_state != &"recovering":
		return

	life_state = &"dead"
	is_alerted = false
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	recovery_time_remaining = 0.0
	recovery_warning.visible = false
	_update_state_presentation()


func knock_down() -> void:
	if life_state != &"living":
		return
	life_state = &"knocked_down"
	recovery_time_remaining = KNOCKDOWN_DURATION
	recovery_warning.visible = false
	velocity = Vector2.ZERO
	_update_state_presentation()


func _update_state_presentation() -> void:
	match life_state:
		&"living":
			police_visual.color = LIVING_COLOR
			police_visual.rotation = 0.0
			police_visual.scale = Vector2.ONE
		&"knocked_down":
			police_visual.color = KNOCKED_DOWN_COLOR
			police_visual.rotation = PI * 0.5
			police_visual.scale = Vector2(1.0, 0.72)
		&"recovering":
			police_visual.color = RECOVERING_COLOR
			police_visual.rotation = PI * 0.5
			police_visual.scale = Vector2(1.0, 0.72)
		&"dead":
			police_visual.color = DEAD_COLOR
			police_visual.rotation = PI * 0.5
			police_visual.scale = Vector2(1.0, 0.72)


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
