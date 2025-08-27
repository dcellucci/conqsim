extends Node2D

const PORT = 8910
const MAX_CLIENTS = 4

var peer = ENetMultiplayerPeer.new()
var status_label: Label

func _ready():
	# Check for command line arguments
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg == "--host":
			_on_host_pressed()
			return
		elif arg == "--client":
			_on_join_pressed()
			return
	
	# UI setup
	var ui = VBoxContainer.new()
	add_child(ui)
	
	var host_button = Button.new()
	host_button.text = "Host Game"
	host_button.pressed.connect(_on_host_pressed)
	ui.add_child(host_button)
	
	var join_button = Button.new()
	join_button.text = "Join Game"
	join_button.pressed.connect(_on_join_pressed)
	ui.add_child(join_button)
	
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Ready to connect"
	ui.add_child(status_label)
	
	var instructions = Label.new()
	instructions.text = "Command line: --host or --client"
	instructions.add_theme_font_size_override("font_size", 12)
	ui.add_child(instructions)
	
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_host_pressed():
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	status_label.text = "Hosting on port " + str(PORT)
	print("Server started on port ", PORT)

func _on_join_pressed():
	peer.create_client("127.0.0.1", PORT)
	multiplayer.multiplayer_peer = peer
	status_label.text = "Connecting to server..."
	print("Connecting to server...")

func _on_peer_connected(id):
	print("Player connected: ", id)
	status_label.text = "Player " + str(id) + " connected"

func _on_peer_disconnected(id):
	print("Player disconnected: ", id)
	status_label.text = "Player " + str(id) + " disconnected"

func _on_connected_to_server():
	print("Connected to server!")
	status_label.text = "Connected to server"

func _on_connection_failed():
	print("Failed to connect to server")
	status_label.text = "Connection failed"

func _on_server_disconnected():
	print("Disconnected from server")
	status_label.text = "Disconnected from server"

# Test RPC function
@rpc("any_peer")
func send_test_message(message: String):
	print("Received message: ", message)
	status_label.text = "Received: " + message
