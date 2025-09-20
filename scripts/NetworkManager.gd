extends Node

signal code_execution_finished(result)
signal connection_established

var websocket: WebSocketPeer
var is_connected = false
var backend_url = "ws://127.0.0.1:8000/ws"

func _ready():
	connect_to_server()

func connect_to_server():
	websocket = WebSocketPeer.new()
	var error = websocket.connect_to_url(backend_url)
	
	if error != OK:
		print("failed to connect: ", error)
		return false
	
	print("connecting...")
	return true

func _process(_delta):
	if websocket:
		websocket.poll()
		var state = websocket.get_ready_state()
		
		if state == WebSocketPeer.STATE_OPEN:
			if not is_connected:
				is_connected = true
				print("connected to server")
				connection_established.emit()
			
			while websocket.get_available_packet_count():
				var packet = websocket.get_packet()
				var message_str = packet.get_string_from_utf8()
				var message = JSON.parse_string(message_str)
				handle_server_message(message)
				
		elif state == WebSocketPeer.STATE_CLOSED:
			if is_connected:
				is_connected = false
				print("disconnected")
				await get_tree().create_timer(2.0).timeout
				connect_to_server()

func send_code_for_execution(code: String):
	if not is_connected:
		print("not connected")
		return false
	
	var message = {
		"type": "execute_code", 
		"code": code
	}
	
	websocket.send_text(JSON.stringify(message))
	return true

func handle_server_message(message: Dictionary):
	match message.type:
		"execution_result":
			code_execution_finished.emit(message.data)
		"connected":
			print("session established: ", message.session_id)
		_:
			print("unknown message type: ", message.type)

func disconnect_from_server():
	if websocket:
		websocket.close()
	is_connected = false
