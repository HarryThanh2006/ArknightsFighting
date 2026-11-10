extends Node3D

@onready var player: AnimationPlayer = $Surtr.find_child("AnimationPlayer", true, false) as AnimationPlayer

func _ready() -> void:
	$Camera.look_at(Vector3(0.10, 0.61, 0))
	player.animation_finished.connect(_on_finished)
	player.play(&"idle")

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1: player.play(&"idle")
		KEY_2: player.play(&"walk_fwd")
		KEY_3:
			player.stop()
			player.play(&"light_atk")

func _on_finished(clip: StringName) -> void:
	if clip == &"light_atk":
		player.play(&"idle")

