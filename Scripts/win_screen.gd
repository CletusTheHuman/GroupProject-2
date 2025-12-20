extends CanvasLayer

@export var start_menu: String = "res://scenes/start_menu.tscn"

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func show_win() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_reset_pressed() -> void:
	print("RESET PRESSED")
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file(start_menu)

func _on_quit_pressed() -> void:
	print("QUIT PRESSED")
	get_tree().quit()
