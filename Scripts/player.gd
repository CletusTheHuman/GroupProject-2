extends RigidBody3D

@export var move_force: float = 1200.0
@export var jump_impulse: float = 4.0
@export var air_control: float = 0.3
@export var max_ground_speed: float = 8.0
@export var max_air_speed: float = 10.0

var mouse_sensitivity := 0.01
var twist_input := 0.0
var pitch_input := 0.0
var spawn_pos: Vector3
var spawn_basis: Basis
var was_on_ground: bool = true
var is_attacking: bool = false

var enemies_in_hit_zone: int = 0

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot
@onready var hit_area: Area3D = $HitArea
@onready var anim: AnimationPlayer = $TwistPivot/robot2/AnimationPlayer

@onready var dialog_ui: Label = get_node_or_null("CanvasLayer/DialogUI") as Label
@onready var combat_ui: Label = get_node_or_null("CanvasLayer/CombatUI") as Label

func _ready() -> void:
	# DON'T force-capture the mouse here anymore.
	# Your StartMenu / WinScreen will control mouse mode.
	if not get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	contact_monitor = true
	max_contacts_reported = 4

	spawn_pos = global_position
	spawn_basis = global_transform.basis

	hide_dialog_text()
	hide_combat_text()

	hit_area.body_entered.connect(_on_hit_area_body_entered)
	hit_area.body_exited.connect(_on_hit_area_body_exited)

func _physics_process(delta: float) -> void:
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_backward")

	var control := 1.0 if is_on_ground() else air_control
	apply_central_force(twist_pivot.basis * input * move_force * control * delta)

	var max_speed := max_ground_speed if is_on_ground() else max_air_speed
	_cap_horizontal_speed(max_speed)

	if Input.is_action_just_pressed("jump") and is_on_ground():
		apply_impulse(Vector3.UP * jump_impulse)

	# Optional: allow ESC to free the mouse (useful for testing)
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(
		pitch_pivot.rotation.x,
		deg_to_rad(-30),
		deg_to_rad(30)
	)

	twist_input = 0.0
	pitch_input = 0.0
	_update_animation(input)

func _cap_horizontal_speed(max_speed: float) -> void:
	var v := linear_velocity
	var horiz := Vector3(v.x, 0.0, v.z)
	var hs := horiz.length()
	if hs > max_speed:
		horiz = horiz.normalized() * max_speed
		linear_velocity = Vector3(horiz.x, v.y, horiz.z)

func _unhandled_input(event: InputEvent) -> void:
	# If the game is paused (StartMenu/WinScreen), ignore player input.
	if get_tree().paused:
		return

	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = -event.relative.x * mouse_sensitivity
			pitch_input = -event.relative.y * mouse_sensitivity

	if event.is_action_pressed("hit"):
		_play_attack()
		_hit_enemies_in_range()

func _play_attack() -> void:
	if anim == null:
		return
	if not anim.has_animation("attackspinlonghands"):
		return
	if is_attacking:
		return

	is_attacking = true
	anim.play("attackspinlonghands")
	anim.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

func _on_attack_finished(anim_name: StringName) -> void:
	if anim_name == &"attackspinlonghands":
		is_attacking = false

func _on_hit_area_body_entered(body: Node) -> void:
	if _is_enemy_or_parent_enemy(body):
		enemies_in_hit_zone += 1
		_show_destroy_prompt_if_needed()

func _on_hit_area_body_exited(body: Node) -> void:
	if _is_enemy_or_parent_enemy(body):
		enemies_in_hit_zone = max(0, enemies_in_hit_zone - 1)
		_hide_destroy_prompt_if_needed()

func _is_enemy_or_parent_enemy(body: Node) -> bool:
	var n: Node = body as Node
	while n != null and not n.is_in_group("enemy"):
		n = n.get_parent()
	return (n != null and n.is_in_group("enemy"))

func _show_destroy_prompt_if_needed() -> void:
	if combat_ui == null:
		return
	show_combat_text("Click to destroy")

func _hide_destroy_prompt_if_needed() -> void:
	if combat_ui == null:
		return
	if enemies_in_hit_zone == 0:
		hide_combat_text()

func _hit_enemies_in_range() -> void:
	if hit_area == null:
		return

	for body in hit_area.get_overlapping_bodies():
		var n: Node = body as Node
		while n != null and not n.is_in_group("enemy"):
			n = n.get_parent()

		if n != null and n.is_in_group("enemy"):
			if n.has_method("die"):
				n.die()
			else:
				n.queue_free()

func is_on_ground() -> bool:
	return get_contact_count() > 0

func show_dialog_text(text: String) -> void:
	if dialog_ui == null:
		return
	dialog_ui.text = text
	dialog_ui.visible = (text != "")

func hide_dialog_text() -> void:
	if dialog_ui == null:
		return
	dialog_ui.text = ""
	dialog_ui.visible = false

func show_combat_text(text: String) -> void:
	if combat_ui == null:
		return
	combat_ui.text = text
	combat_ui.visible = (text != "")

func hide_combat_text() -> void:
	if combat_ui == null:
		return
	combat_ui.text = ""
	combat_ui.visible = false

func respawn() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	global_position = spawn_pos
	global_transform.basis = spawn_basis

func _update_animation(input: Vector3) -> void:
	if anim == null:
		return

	if is_attacking:
		return

	var moving := Vector3(input.x, 0.0, input.z).length() > 0.1
	var on_ground := is_on_ground()

	if on_ground and moving:
		if anim.current_animation != "walking":
			anim.play("walking")

	# IDLE (optional)
	elif on_ground and not moving:
		if anim.has_animation("idle"):
			if anim.current_animation != "idle":
				anim.play("idle")

	was_on_ground = on_ground
