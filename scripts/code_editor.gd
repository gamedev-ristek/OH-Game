extends Node2D

var player: CharacterBody2D
var is_executing = false
var should_abort = false
var current_movement_index = 0

const STUCK_TIMEOUT = 5.0

@onready var code_box: CodeEdit = $CodeBox
@onready var error_label: Label = $ErrorLabel
@onready var run_button: Button = $RunButton

func _ready() -> void:
	player = get_parent().find_child("Player")
	print("player: ", player != null)
	
	if error_label:
		error_label.visible = false
	
	if run_button:
		run_button.disabled = false

func _on_run_button_pressed() -> void:
	if is_executing:
		show_error("still executing previous code")
		return

	hide_error()
	reset()
	
	if run_button:
		run_button.disabled = true
	
	var full_code = _get_code_from_editor()
	
	var validation = CodeExecutor.validate_code(full_code)
	if not validation.valid:
		print("code failed: ", validation.error)
		show_error(validation.error)
		_enable_run_button()
		return
	
	await _execute_user_code(full_code)
	
	_enable_run_button()

func _get_code_from_editor() -> String:
	var full_code = ""
	for i in range(code_box.get_line_count()):
		var line = code_box.get_line(i)
		if not line.strip_edges().begins_with("#") and line.strip_edges() != "":
			full_code += line + "\n"
	return full_code

func _execute_user_code(code: String):
	should_abort = false
	current_movement_index = 0
	
	var result = await _safe_execute(code)
	
	if should_abort:
		show_error("stuck")
		return
	
	if not result.success:
		show_error(result.error)
		return
	
	if result.movements.size() == 0:
		show_error("no movements")
		return
	
	await execute_movements(result.movements)

func _safe_execute(code: String) -> Dictionary:
	var result = CodeExecutor.execute_code(code)
	await get_tree().process_frame
	return result

func execute_movements(movements: Array):
	is_executing = true
	should_abort = false
	
	for i in range(movements.size()):
		if should_abort:
			print("aborting exec", i)
			break
			
		current_movement_index = i
		var movement = movements[i]
		var method = movement.get("method", "")
		var steps = movement.get("steps", 1)
		
		if not is_instance_valid(player):
			should_abort = true
			break
		
		if player.is_movement_aborted():
			should_abort = true
			break
		
		print("executing movement ", i + 1, "/", movements.size(), ": ", method, "(", steps, ")")
		
		match method:
			"move_up":
				player.move_up(steps)
			"move_down":
				player.move_down(steps)
			"move_left":
				player.move_left(steps)
			"move_right":
				player.move_right(steps)
			_:
				continue
		
		await wait_for_movement_complete()
		
		if should_abort or (is_instance_valid(player) and player.is_movement_aborted()):
			should_abort = true
			print("aborted")
			break
			
		await get_tree().create_timer(0.1).timeout
	
	is_executing = false
	print("executed ", current_movement_index + 1, " movements")

func wait_for_movement_complete():
	var max_wait = STUCK_TIMEOUT + 2.0
	var elapsed = 0.0
	var check_interval = 0.1
	
	while (is_instance_valid(player) and 
		   player.is_moving and 
		   not player.is_movement_aborted() and 
		   elapsed < max_wait and 
		   not should_abort):
		
		await get_tree().create_timer(check_interval).timeout
		elapsed += check_interval
		
		if player.is_movement_aborted():
			should_abort = true
			break
	
	if elapsed >= max_wait:
		should_abort = true
		if is_instance_valid(player):
			player._abort_movement_forcefully()

func abort_execution():
	print("abort exec")
	should_abort = true
	is_executing = false
	
	if is_instance_valid(player):
		player._abort_movement_forcefully()

func reset():
	if is_instance_valid(player):
		player.reset()
	is_executing = false
	should_abort = false
	current_movement_index = 0

func show_error(error_message: String):
	print("ERROR: ", error_message)
	
	if error_label:
		error_label.text = "❌ " + error_message
		error_label.visible = true
		error_label.modulate = Color(1, 0.3, 0.3)

func hide_error():
	if error_label:
		error_label.visible = false

func _enable_run_button():
	if run_button:
		run_button.disabled = false
