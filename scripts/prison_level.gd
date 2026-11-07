class_name PrisonLevel
extends Node2D

const AUTOMATIC_DOOR_SCRIPT := preload("res://scripts/automatic_door.gd")
const EXIT_THRESHOLD := Rect2(1650, 825, 100, 100)

@export var next_level_scene: PackedScene = preload("res://scenes/next_level.tscn")

var exit_unlocked := false
var level_complete := false
var _exit_gate: StaticBody2D
var _exit_status: Label
var _transition_pending := false

const AREA_RECTS: Dictionary = {
	&"starting_cell": Rect2(100.0, 100.0, 250.0, 250.0),
	&"cell_block": Rect2(350.0, 100.0, 500.0, 500.0),
	&"guard_office": Rect2(850.0, 100.0, 400.0, 300.0),
	&"storage": Rect2(1250.0, 100.0, 400.0, 300.0),
	&"central_corridor": Rect2(850.0, 400.0, 800.0, 200.0),
	&"exercise_yard": Rect2(850.0, 600.0, 600.0, 500.0),
	&"exit": Rect2(1450.0, 600.0, 200.0, 500.0),
	&"alternate_passage": Rect2(350.0, 600.0, 500.0, 200.0),
}

const ROOM_IDS: Array[StringName] = [
	&"starting_cell",
	&"cell_block",
	&"guard_office",
	&"storage",
	&"central_corridor",
	&"exercise_yard",
	&"exit",
]

const AREA_NODE_IDS: Dictionary = {
	&"starting_cell": [0, 100],
	&"cell_block": [1, 100, 101, 105, 106],
	&"guard_office": [2, 101, 102, 103],
	&"storage": [3, 102, 104],
	&"central_corridor": [4, 103, 104, 105, 108, 109],
	&"exercise_yard": [5, 107, 108, 110],
	&"exit": [6, 109, 110],
	&"alternate_passage": [7, 106, 107],
}

const FLOOR_COLOR := Color(0.16, 0.19, 0.24, 1.0)
const WALL_COLOR := Color(0.42, 0.46, 0.52, 1.0)

var _world := Node2D.new()
var _navigation_graph := AStar2D.new()


func _ready() -> void:
	_build_navigation_graph()
	_world.name = "Prison"
	add_child(_world)
	_add_floor(&"starting_cell", AREA_RECTS[&"starting_cell"])
	_add_floor(&"cell_block", AREA_RECTS[&"cell_block"])
	_add_floor(&"guard_office", AREA_RECTS[&"guard_office"])
	_add_floor(&"storage", AREA_RECTS[&"storage"])
	_add_floor(&"central_corridor", AREA_RECTS[&"central_corridor"])
	_add_floor(&"exercise_yard", AREA_RECTS[&"exercise_yard"])
	_add_floor(&"exit", AREA_RECTS[&"exit"])
	_add_floor(&"alternate_passage", AREA_RECTS[&"alternate_passage"])

	_add_wall("StartingCellTop", Rect2(100.0, 90.0, 250.0, 20.0))
	_add_wall("StartingCellLeft", Rect2(90.0, 100.0, 20.0, 250.0))
	_add_wall("StartingCellBottom", Rect2(100.0, 340.0, 250.0, 20.0))
	_add_wall("StartingCellRightUpper", Rect2(340.0, 100.0, 20.0, 75.0))
	_add_wall("StartingCellRightLower", Rect2(340.0, 275.0, 20.0, 75.0))
	_add_wall("CellBlockTop", Rect2(350.0, 90.0, 500.0, 20.0))
	_add_wall("CellBlockRightUpper", Rect2(840.0, 100.0, 20.0, 75.0))
	_add_wall("CellBlockRightMiddle", Rect2(840.0, 275.0, 20.0, 150.0))
	_add_wall("CellBlockRightLower", Rect2(840.0, 525.0, 20.0, 75.0))
	_add_wall("CellBlockBottomLeft", Rect2(350.0, 590.0, 200.0, 20.0))
	_add_wall("CellBlockBottomRight", Rect2(650.0, 590.0, 200.0, 20.0))
	_add_wall("GuardOfficeTop", Rect2(850.0, 90.0, 400.0, 20.0))
	_add_wall("GuardOfficeRightUpper", Rect2(1240.0, 100.0, 20.0, 75.0))
	_add_wall("GuardOfficeRightLower", Rect2(1240.0, 275.0, 20.0, 125.0))
	_add_wall("GuardOfficeBottomLeft", Rect2(850.0, 390.0, 175.0, 20.0))
	_add_wall("GuardOfficeBottomRight", Rect2(1125.0, 390.0, 125.0, 20.0))
	_add_wall("StorageTop", Rect2(1250.0, 90.0, 400.0, 20.0))
	_add_wall("StorageRight", Rect2(1640.0, 100.0, 20.0, 300.0))
	_add_wall("StorageBottomLeft", Rect2(1250.0, 390.0, 200.0, 20.0))
	_add_wall("StorageBottomRight", Rect2(1550.0, 390.0, 100.0, 20.0))
	_add_wall("CentralCorridorRight", Rect2(1640.0, 400.0, 20.0, 200.0))
	_add_wall("CentralCorridorBottomLeft", Rect2(850.0, 590.0, 200.0, 20.0))
	_add_wall("CentralCorridorBottomMiddle", Rect2(1150.0, 590.0, 370.0, 20.0))
	_add_wall("CentralCorridorBottomRight", Rect2(1600.0, 590.0, 50.0, 20.0))
	_add_wall("ExerciseYardLeftUpper", Rect2(840.0, 600.0, 20.0, 75.0))
	_add_wall("ExerciseYardLeftLower", Rect2(840.0, 775.0, 20.0, 325.0))
	_add_wall("ExerciseYardRightUpper", Rect2(1440.0, 600.0, 20.0, 200.0))
	_add_wall("ExerciseYardRightLower", Rect2(1440.0, 900.0, 20.0, 200.0))
	_add_wall("ExerciseYardBottom", Rect2(850.0, 1090.0, 600.0, 20.0))
	_add_wall("ExitRightUpper", Rect2(1640.0, 600.0, 20.0, 225.0))
	_add_wall("ExitRightLower", Rect2(1640.0, 925.0, 20.0, 175.0))
	_add_wall("ExitBottom", Rect2(1450.0, 1090.0, 200.0, 20.0))
	_add_wall("AlternatePassageLeft", Rect2(340.0, 600.0, 20.0, 200.0))
	_add_wall("AlternatePassageBottom", Rect2(350.0, 790.0, 500.0, 20.0))
	_add_automatic_doors()

	var player := get_node("Player") as CharacterBody2D
	player.position = Vector2(225.0, 225.0)
	_add_wall("ExitGate", Rect2(1640.0, 825.0, 20.0, 100.0))
	_exit_gate = _world.get_node("ExitGate")
	_exit_status = Label.new()
	_exit_status.name = "ExitStatus"
	_exit_status.position = Vector2(1460.0, 940.0)
	_exit_status.text = "EXIT LOCKED"
	_world.add_child(_exit_status)


func _physics_process(_delta: float) -> void:
	if not exit_unlocked:
		for policeman in get_tree().get_nodes_in_group("police"):
			if is_ancestor_of(policeman) and policeman.life_state != &"dead":
				return
		exit_unlocked = true
		_exit_status.text = "EXIT OPEN"
		_exit_gate.visible = false
		_exit_gate.get_node("CollisionShape2D").set_deferred("disabled", true)
	var player := get_node("Player") as Player
	if not level_complete and not player.is_dead and EXIT_THRESHOLD.has_point(player.global_position):
		level_complete = true
		for child in get_children():
			child.process_mode = Node.PROCESS_MODE_DISABLED
		var layer := CanvasLayer.new()
		layer.name = "CompletionLayer"
		layer.layer = 10
		add_child(layer)
		var overlay := ColorRect.new()
		overlay.name = "LevelComplete"
		overlay.color = Color(0.02, 0.04, 0.08, 0.9)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.add_child(overlay)
		var label := Label.new()
		label.text = "LEVEL COMPLETE\nPress a key or click to continue"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 32)
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.add_child(label)


func _input(event: InputEvent) -> void:
	if not level_complete or _transition_pending or next_level_scene == null:
		return
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo():
		_transition_pending = true
		get_viewport().set_input_as_handled()
		call_deferred("_load_next_level")


func _load_next_level() -> void:
	var result := get_tree().change_scene_to_packed(next_level_scene)
	if result != OK:
		_transition_pending = false
		push_error("Could not load configured next level: %s" % error_string(result))


func _add_automatic_doors() -> void:
	var door_locations: Array[Dictionary] = [
		{"position": Vector2(350.0, 225.0), "rotation": 0.0},
		{"position": Vector2(850.0, 225.0), "rotation": 0.0},
		{"position": Vector2(1250.0, 225.0), "rotation": 0.0},
		{"position": Vector2(1075.0, 400.0), "rotation": 90.0},
		{"position": Vector2(1500.0, 400.0), "rotation": 90.0},
		{"position": Vector2(850.0, 475.0), "rotation": 0.0},
		{"position": Vector2(600.0, 600.0), "rotation": 90.0},
		{"position": Vector2(850.0, 725.0), "rotation": 0.0},
		{"position": Vector2(1100.0, 600.0), "rotation": 90.0},
		{"position": Vector2(1560.0, 600.0), "rotation": 90.0},
		{"position": Vector2(1450.0, 850.0), "rotation": 0.0},
	]
	for location: Dictionary in door_locations:
		var door := Node2D.new()
		door.set_script(AUTOMATIC_DOOR_SCRIPT)
		door.position = location["position"]
		door.rotation_degrees = location["rotation"]
		_world.add_child(door)


func get_area_id_at(global_point: Vector2) -> StringName:
	for area_id: StringName in AREA_RECTS:
		var area_rect: Rect2 = AREA_RECTS[area_id]
		if area_rect.has_point(global_point):
			return area_id

	return &""


func get_room_ids() -> Array[StringName]:
	return ROOM_IDS.duplicate()


func get_navigation_path(from_position: Vector2, target_position: Vector2) -> PackedVector2Array:
	var from_area := get_area_id_at(from_position)
	var target_area := get_area_id_at(target_position)
	if from_area == &"" or target_area == &"":
		return PackedVector2Array([from_position, target_position])
	if from_area == target_area and _has_clear_path(from_position, target_position):
		return PackedVector2Array([from_position, target_position])

	const START_POINT_ID := 1000
	const TARGET_POINT_ID := 1001
	_navigation_graph.add_point(START_POINT_ID, from_position)
	_navigation_graph.add_point(TARGET_POINT_ID, target_position)
	for point_id: int in AREA_NODE_IDS[from_area]:
		if _has_clear_path(from_position, _navigation_graph.get_point_position(point_id)):
			_navigation_graph.connect_points(START_POINT_ID, point_id)
	for point_id: int in AREA_NODE_IDS[target_area]:
		if _has_clear_path(target_position, _navigation_graph.get_point_position(point_id)):
			_navigation_graph.connect_points(TARGET_POINT_ID, point_id)

	var path := _navigation_graph.get_point_path(START_POINT_ID, TARGET_POINT_ID)
	_navigation_graph.remove_point(START_POINT_ID)
	_navigation_graph.remove_point(TARGET_POINT_ID)
	return path


func _has_clear_path(from_position: Vector2, target_position: Vector2) -> bool:
	if from_position.is_equal_approx(target_position):
		return true

	var query := PhysicsRayQueryParameters2D.create(from_position, target_position)
	query.collision_mask = 1
	var collision := get_world_2d().direct_space_state.intersect_ray(query)
	return collision.is_empty()


func _build_navigation_graph() -> void:
	var area_centers: Dictionary = {
		0: Vector2(225.0, 225.0),
		1: Vector2(600.0, 350.0),
		2: Vector2(1050.0, 250.0),
		3: Vector2(1450.0, 250.0),
		4: Vector2(1250.0, 500.0),
		5: Vector2(1150.0, 850.0),
		6: Vector2(1550.0, 850.0),
		7: Vector2(600.0, 700.0),
	}
	var door_positions: Dictionary = {
		100: Vector2(350.0, 225.0),
		101: Vector2(850.0, 225.0),
		102: Vector2(1250.0, 225.0),
		103: Vector2(1075.0, 400.0),
		104: Vector2(1500.0, 400.0),
		105: Vector2(850.0, 475.0),
		106: Vector2(600.0, 600.0),
		107: Vector2(850.0, 725.0),
		108: Vector2(1100.0, 600.0),
		109: Vector2(1560.0, 600.0),
		110: Vector2(1450.0, 850.0),
	}
	for point_id: int in area_centers:
		_navigation_graph.add_point(point_id, area_centers[point_id])
	for point_id: int in door_positions:
		_navigation_graph.add_point(point_id, door_positions[point_id])

	_connect_route(0, 100, 1)
	_connect_route(1, 101, 2)
	_connect_route(2, 102, 3)
	_connect_route(2, 103, 4)
	_connect_route(3, 104, 4)
	_connect_route(1, 105, 4)
	_connect_route(1, 106, 7)
	_connect_route(7, 107, 5)
	_connect_route(4, 108, 5)
	_connect_route(4, 109, 6)
	_connect_route(5, 110, 6)


func _connect_route(first_area_id: int, door_id: int, second_area_id: int) -> void:
	_navigation_graph.connect_points(first_area_id, door_id)
	_navigation_graph.connect_points(door_id, second_area_id)


func _add_floor(area_id: StringName, area_rect: Rect2) -> void:
	var floor := Polygon2D.new()
	floor.name = String(area_id).to_pascal_case()
	floor.polygon = PackedVector2Array([
		area_rect.position,
		Vector2(area_rect.end.x, area_rect.position.y),
		area_rect.end,
		Vector2(area_rect.position.x, area_rect.end.y),
	])
	floor.color = FLOOR_COLOR
	floor.z_index = -10
	_world.add_child(floor)

	var label := Label.new()
	label.position = area_rect.position + Vector2(20.0, 16.0)
	label.text = String(area_id).replace("_", " ").to_upper()
	label.z_index = -9
	_world.add_child(label)


func _add_wall(wall_name: String, wall_rect: Rect2) -> void:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.position = wall_rect.get_center()

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = wall_rect.size
	collision.shape = shape
	wall.add_child(collision)

	var visual := Polygon2D.new()
	var half_size := wall_rect.size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		half_size,
		Vector2(-half_size.x, half_size.y),
	])
	visual.color = WALL_COLOR
	visual.z_index = -1
	wall.add_child(visual)

	_world.add_child(wall)
