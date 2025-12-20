extends CharacterBody3D

@export var speed: float = 3.0
@export var path_points: Array[Vector3] = []

@export var dialog_lines: Array[String] = [
	"Get to the top and kill the enemies Dawg",
	"Good luck"
]

var current_point_index: int = 0
var player_in_range: bool = false
var is_talking: bool = false
var dialog_index: int = -1

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var talk_area: Area3D = $TalkArea

@export var wander_radius: float = 6.0
@export var wait_time_range := Vector2(0.8, 2.0)

var home_pos: Vector3
var wait_timer: float = 0.0
var waiting: bool = false

func _ready() -> void:
	home_pos = global_position
	_pick_new_wander_target()

	call_deferred("_set_player_dialog", "")

	talk_area.body_entered.connect(_on_talk_area_body_entered)
	talk_area.body_exited.connect(_on_talk_area_body_exited)

	if path_points.is_empty():
		push_warning("NPC has no path_points!")
		return

	global_position = path_points[0]
	_set_next_patrol_target()

func _process(delta: float) -> void:
	if is_talking:
		if Input.is_action_just_pressed("talk"):
			_advance_dialog()
		return

	if player_in_range:
		_set_player_dialog("Press F to talk")
		if Input.is_action_just_pressed("talk"):
			_start_conversation()
	else:
		_set_player_dialog("")

func _physics_process(delta: float) -> void:
	if is_talking:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if waiting:
		wait_timer -= delta
		if wait_timer <= 0.0:
			waiting = false
			_pick_new_wander_target()
		return

	if nav.is_navigation_finished():
		_start_wait()
		return

	var next_pos: Vector3 = nav.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position)
	dir.y = 0.0

	if dir.length() > 0.001:
		dir = dir.normalized()
	else:
		dir = Vector3.ZERO

	velocity = dir * speed
	move_and_slide()

	if dir != Vector3.ZERO:
		look_at(global_position + dir, Vector3.UP)

func _set_next_patrol_target() -> void:
	var target := path_points[current_point_index]
	target.y = global_position.y
	nav.set_target_position(target)

func _start_conversation() -> void:
	if dialog_lines.is_empty():
		return
	is_talking = true
	dialog_index = 0
	_set_player_dialog(dialog_lines[dialog_index])

func _advance_dialog() -> void:
	dialog_index += 1

	if dialog_index >= dialog_lines.size():
		is_talking = false
		dialog_index = -1

		if player_in_range:
			_set_player_dialog("Press F to talk")
		else:
			_set_player_dialog("")
	else:
		_set_player_dialog(dialog_lines[dialog_index])

func _on_talk_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		if not is_talking:
			_set_player_dialog("Press F to talk")

func _on_talk_area_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if not is_talking:
			_set_player_dialog("")

func _pick_new_wander_target() -> void:
	var p := home_pos
	p.x += randf_range(-wander_radius, wander_radius)
	p.z += randf_range(-wander_radius, wander_radius)
	p.y = home_pos.y
	nav.set_target_position(p)

func _start_wait() -> void:
	waiting = true
	wait_timer = randf_range(wait_time_range.x, wait_time_range.y)
	velocity = Vector3.ZERO

# -------- UI DIALOG HELPERS (put text in front of player) --------

func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")

func _set_player_dialog(text: String) -> void:
	var p := _get_player()
	if p == null:
		return
	if p.has_method("show_dialog_text"):
		p.show_dialog_text(text)
	elif p.has_method("set_dialog_text"):
		p.set_dialog_text(text)
