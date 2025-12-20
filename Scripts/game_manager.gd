extends Node

@export var win_zone_path: NodePath
@export var win_marker_path: NodePath
@export var win_screen_path: NodePath

var enemies_left: int = 0

@onready var win_zone: Area3D = get_node(win_zone_path) as Area3D
@onready var win_marker: Node3D = get_node_or_null(win_marker_path) as Node3D
@onready var win_screen: CanvasLayer = get_node(win_screen_path) as CanvasLayer

func _ready() -> void:
	# Start hidden/disabled
	win_zone.monitoring = false
	if win_marker != null:
		win_marker.visible = false
	win_screen.visible = false

	# Count and connect to all enemies currently in the scene
	var enemies := get_tree().get_nodes_in_group("enemy")
	enemies_left = enemies.size()

	for e in enemies:
		if e.has_signal("died"):
			e.died.connect(_on_enemy_died)

	# When player enters the zone
	win_zone.body_entered.connect(_on_win_zone_body_entered)

func _on_enemy_died() -> void:
	enemies_left -= 1
	if enemies_left <= 0:
		_enable_win_zone()

func _enable_win_zone() -> void:
	win_zone.monitoring = true
	if win_marker != null:
		win_marker.visible = true

func _on_win_zone_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_play_win_cutscene()

func _play_win_cutscene() -> void:
	win_screen.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
