extends Node3D
const MULTI_PLAYER = preload("uid://bgglnkjwf56y4")
@export var spawn_radius := 2.0

@onready var players: Node3D = $Players
@onready var spawn_point: Marker3D = $SpawnPoint


func _ready() -> void:
	players.child_entered_tree.connect(_on_player_entered)
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		Networking.host_created.connect(_start_hosting)
		Networking.host_lobby()
		return
	if multiplayer.is_server():
		_start_hosting()


func _start_hosting() -> void:
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)
	_add_player(multiplayer.get_unique_id())


func _add_player(id: int) -> void:
	var player := MULTI_PLAYER.instantiate()
	player.name = str(id)
	players.add_child(player, true)


func _remove_player(id: int) -> void:
	var player := players.get_node_or_null(str(id))
	if player:
		player.queue_free()


func _on_player_entered(node: Node) -> void:
	if not node.is_multiplayer_authority():
		return
	var offset := Vector3(randf_range(-spawn_radius, spawn_radius), 0.0, randf_range(-spawn_radius, spawn_radius))
	(node as Node3D).global_position = spawn_point.global_position + offset
