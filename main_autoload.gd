extends Node

func _ready() -> void:
	Engine.max_fps = DisplayServer.screen_get_refresh_rate() as int
