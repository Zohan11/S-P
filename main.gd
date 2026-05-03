extends Node

func _ready() -> void:
	var client = preload("res://multiplayer_client.gd").new()
	add_child(client)
	client.start("wss://surviveandprospernow.com", "test_lobby", true)
