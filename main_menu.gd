extends Control

var client: Node
var connected: bool = false

@onready var lobby_field: LineEdit = $LobbyField
@onready var create_button: Button = $CreateButton
@onready var join_button: Button = $JoinButton

func _ready() -> void:
	get_tree().paused = true

	client = preload("res://multiplayer_client.gd").new()
	add_child(client)

	# Connect button signals
	create_button.pressed.connect(_on_create_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)

	# Connect client signals
	client.lobby_joined.connect(_on_lobby_joined)
	client.connected.connect(_on_connected)


# Step 1: Create lobby → connect and fill LineEdit, but keep game paused
func _on_create_button_pressed() -> void:
	print("Create button pressed")
	client.start("wss://surviveandprospernow.com", "", true)


func _on_lobby_joined(lobby: String) -> void:
	lobby_field.text = lobby
	print("Lobby created: %s" % lobby)


# Step 2: Join lobby → if already connected, just unpause; otherwise connect
func _on_join_button_pressed() -> void:
	var lobby_name = lobby_field.text.strip_edges()
	if connected:
		print("Already connected, unpausing game")
		hide()
		get_tree().paused = false
	elif lobby_name != "":
		print("Joining lobby: %s" % lobby_name)
		client.start("wss://surviveandprospernow.com", lobby_name, true)


# Step 3: On successful connection → mark connected, but don’t unpause yet
func _on_connected(id: int, use_mesh: bool) -> void:
	connected = true
	print("Connected with ID %d" % id)
	# Game stays paused until Join Lobby button is pressed
