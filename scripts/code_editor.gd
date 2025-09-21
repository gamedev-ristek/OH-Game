extends Node2D

var player: CharacterBody2D
@onready var code_box: CodeEdit = $CodeBox

var last_line := 0
var command_queue: Array = []
var command_lines: Array = []
var current_execution_result: Dictionary = {}

signal execute_next_command

func _ready() -> void:
	player = get_parent().find_child("Player")
	
	connect("execute_next_command", on_execute_next_command)
	NetworkManager.code_execution_finished.connect(_on_python_execution_finished)
	NetworkManager.connection_established.connect(_on_backend_connected)

func _on_backend_connected():
	print("backend ready")

func _on_run_button_pressed() -> void:
	reset()
	execute_with_python_backend()

func execute_with_python_backend():
	var code_text = code_box.text
	
	if code_text.strip_edges() == "":
		print("no code to execute")
		return
	
	if not NetworkManager.is_connected:
		print("not connected to python")
		return

	NetworkManager.send_code_for_execution(code_text)

func _on_python_execution_finished(result: Dictionary):
	current_execution_result = result
	
	if result.success:
		print("execution successful!")
		print("actions: ", result.actions)
		print("char position: ", result.player_position)
		
		convert_python_actions_to_commands(result.actions)

		if not command_queue.is_empty():
			on_execute_next_command()
		else:
			done_executing()
	else:
		print("execution failed: ", result.error)
		
		if result.has("error_line"):
			executing_line(result.error_line, true)
		
		done_executing()

func convert_python_actions_to_commands(actions: Array):
	command_queue.clear()
	command_lines.clear()
	
	for action in actions:
		if action.type == "move":
			var direction = action.direction
			var steps = action.get("steps", 1)
			
			var command = "player.move_" + direction + "(" + str(steps) + ")"
			command_queue.append(command)
			command_lines.append(-1)

func executing_line(line_number: int, is_error := false):
	if line_number < 0:
		return
		
	code_box.set_line_background_color(last_line, Color(0, 0, 0, 0))

	code_box.clear_executing_lines()
	code_box.set_line_as_executing(line_number, true)
	if is_error:
		code_box.set_line_background_color(line_number, Color(1, 0, 0, 0.2))
	else:
		code_box.set_line_background_color(line_number, Color(0, 1, 0, 0.2))
	last_line = line_number
	
func done_executing():
	$Timer.start()
	await $Timer.timeout
	code_box.clear_executing_lines()
	if last_line >= 0:
		code_box.set_line_background_color(last_line, Color(0, 0, 0, 0))
	
	if current_execution_result.has("valid_commands"):
		print("execution completed, valid commands: ", current_execution_result.valid_commands)
	
func on_execute_next_command():
	if player == null:
		return
	if command_queue.is_empty():
		done_executing()
		return
	
	var command = command_queue.pop_front()
	var command_line = command_lines.pop_front()
	
	if command == "ERROR":
		executing_line(command_line, true)
		done_executing()
		return
		
	executing_line(command_line)
	
	if command.begins_with("player.move"):
		player.set_movement(command)

func reset():
	#player.reset()
	command_queue.clear()
	command_lines.clear()
	current_execution_result.clear()
