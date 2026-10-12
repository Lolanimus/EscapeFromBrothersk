extends SceneTree

const MainMenuScene := preload("res://scenes/main_menu.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var menu := MainMenuScene.instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame

	var play_button := menu.get_node("%PlayButton") as Button
	var quit_button := menu.get_node("%QuitButton") as Button

	_expect(play_button.text == "PLAY THE GAME", "play button has the expected label")
	_expect(quit_button.text == "QUIT", "quit button has the expected label")
	_expect(root.gui_get_focus_owner() == play_button, "play button receives initial focus")

	play_button.pressed.emit()
	await process_frame
	await process_frame
	_expect(
		current_scene != null and current_scene.scene_file_path == "res://scenes/main.tscn",
		"play button opens the gameplay scene"
	)

	if _failures == 0:
		print("PASS: all main menu tests passed")
	else:
		push_error("FAIL: %d main menu test(s) failed" % _failures)

	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return

	_failures += 1
	push_error("FAIL: %s" % message)
