extends Node3D

@onready var aggro_area: Area3D = $AggroArea

func _ready() -> void:
	aggro_area.body_entered.connect(_on_body_entered)
	aggro_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		for mob in get_tree().get_nodes_in_group("mobs"):
			if mob.has_method("set_aggro"):
				mob.set_aggro(true)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		for mob in get_tree().get_nodes_in_group("mobs"):
			if mob.has_method("set_aggro"):
				mob.set_aggro(false)
