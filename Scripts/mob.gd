extends CharacterBody3D

signal died

@export var speed: float = 3
@export var aggro: bool = false

@onready var nav: NavigationAgent3D = $NavigationAgent3D

var player: Node3D

func _ready() -> void:
	add_to_group("mobs")
	add_to_group("enemy") # IMPORTANT: so your hitbox detects it as an enemy
	player = get_tree().get_first_node_in_group("player") as Node3D

func die() -> void:
	emit_signal("died")
	queue_free()

func set_aggro(on: bool) -> void:
	aggro = on
	if not aggro:
		velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not aggro or player == null:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	nav.set_target_position(player.global_position)

	var next_pos: Vector3 = nav.get_next_path_position()
	var dir: Vector3 = next_pos - global_position
	dir.y = 0.0

	if dir.length() > 0.001:
		dir = dir.normalized()
	else:
		dir = Vector3.ZERO

	velocity = dir * speed
	move_and_slide()

	if dir != Vector3.ZERO:
		look_at(global_position + dir, Vector3.UP)
