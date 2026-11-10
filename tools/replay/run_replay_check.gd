extends SceneTree
## Debug entry point for ReplayCheck: Godot/godot.exe --headless --path . -s res://tools/replay/run_replay_check.gd


func _init() -> void:
	print(ReplayCheck.run())
	quit()
