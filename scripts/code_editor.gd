extends  Node2D
var player: CharacterBody2D
@onready var code_box: CodeEdit = $CodeBox

var last_line := 0
var command_queue: Array = []
var command_lines: Array = []
var cur_indentation_level = 0
signal execute_next_command
func _ready() -> void:
	player = get_parent().find_child("Player")
	connect("execute_next_command", on_execute_next_command)
func _on_run_button_pressed() -> void:
	reset()
	var commands := {}
	
	for i in range(code_box.get_line_count()):
		var line_text = code_box.get_line(i).strip_edges(false)
		
		var leading_spaces = ""
		for j in line_text:
			if j != " ":
				break
			leading_spaces += j

		var words = line_text.split(" ", false)
		for j in range(words.size()):
			words[j] = words[j].replace("\t", "    ")
		line_text = leading_spaces + " ".join(words)
		print(line_text)
		if line_text == "" or line_text.begins_with("#"):
			continue
		var is_valid = false
		
		var valid_syntax = ["player.move_up", "player.move_down", "player.move_left", "player.move_right", "for i in range :"]
		# TODO ganti bagian cek argumen agar tida	k cuma jika arg angka
		for syntax in valid_syntax:
			if line_text == "player":
				is_valid = true
				break
			if line_text.begins_with(syntax + "(") and line_text.ends_with(")"):
				var arg_str = line_text.substr(syntax.length() + 1, line_text.length() - syntax.length() - 2)
				
				if arg_str == "" or arg_str.is_valid_int():
					is_valid = true
				break

		if is_valid:
			commands[i] = line_text
		else:
			commands[i] = "ERROR"
	
	for key in commands:
		var command = commands[key]
		command_queue.append(command)
		command_lines.append(key)
	on_execute_next_command()

func executing_line(line_number: int, is_error := false):
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
	code_box.set_line_background_color(last_line, Color(0, 0, 0, 0))
	
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
	player.reset()
	
	command_queue.clear()
	command_lines.clear()
	
	
	
	
