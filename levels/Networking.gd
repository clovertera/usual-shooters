# networking.gd - Save as an autoload named "Networking" in Project Settings > Globals > Autoload
extends Node

signal host_created()

const LOBBY_TYPE := Steam.LobbyType.LOBBY_TYPE_FRIENDS_ONLY
const MAX_MEMBERS := 8
const LOBBY_WORLD := "res://levels/MultiplayerLobbyTest.tscn"

var peer: SteamMultiplayerPeer
var current_lobby_id := 0


func _ready() -> void:
	print("Networking script loaded")
	OS.set_environment("SteamAppId", "480")
	OS.set_environment("SteamGameId", "480")
	var init: Dictionary = Steam.steamInitEx()
	print("Steam init: ", init)
	if init["status"] != 0:  # 0 = OK in steamInitEx
		push_error("Steam failed to initialize: " + str(init["verbal"]))
		return
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(on_lobby_created)
	Steam.lobby_joined.connect(on_lobby_joined)
	Steam.join_requested.connect(on_join_requested)
	Steam.lobby_chat_update.connect(on_lobby_chat_update)
	multiplayer.server_disconnected.connect(leave_game)


func _process(delta: float) -> void:
	Steam.run_callbacks()


func host_lobby() -> void:
	Steam.createLobby(LOBBY_TYPE, MAX_MEMBERS)


func on_lobby_created(connect: int, lobby_id: int) -> void:
	if connect == Steam.RESULT_OK:
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		multiplayer.multiplayer_peer = peer
		host_created.emit()


func on_lobby_joined(lobby_id: int, permissions: int, locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("Joined lobby ", lobby_id, " as ", Steam.getSteamID())
		current_lobby_id = lobby_id
		if Steam.getLobbyOwner(lobby_id) == Steam.getSteamID():
			return
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_client(Steam.getLobbyOwner(lobby_id), 0)
		multiplayer.multiplayer_peer = peer
		get_tree().change_scene_to_file(LOBBY_WORLD)
	else:
		print("Failed to join lobby, response: ", response)
		leave_game()


func on_join_requested(lobby_id: int, steam_id: int) -> void:
	if lobby_id == current_lobby_id:
		return
	close_connection()
	Steam.joinLobby(lobby_id)


func on_lobby_chat_update(lobby_id: int, changed_id: int, making_change_id: int, chat_state: int) -> void:
	if chat_state & Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("Player joined: ", changed_id)


func close_connection() -> void:
	if current_lobby_id != 0:
		Steam.leaveLobby(current_lobby_id)
		current_lobby_id = 0
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if peer:
		peer.close()
		peer = null


func leave_game() -> void:
	close_connection()
	get_tree().change_scene_to_file(LOBBY_WORLD)
