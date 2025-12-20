extends CanvasLayer

@export var level_scene: String = "res://scenes/level.tscn"

func _ready() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_start_button_pressed() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file(level_scene)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
