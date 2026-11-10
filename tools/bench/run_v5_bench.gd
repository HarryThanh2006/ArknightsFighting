extends SceneTree
## Editor / Debug entry point for V5Bench: Godot/godot.exe --headless --path . -s res://tools/bench/run_v5_bench.gd


func _init() -> void:
	print(V5Bench.run())
	quit()
