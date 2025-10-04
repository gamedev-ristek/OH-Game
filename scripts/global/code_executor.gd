extends Node

var player_methods = ["move_up", "move_down", "move_left", "move_right"]
var is_executing = false

func execute_code(code: String) -> Dictionary:
	var result = {
		"success": false,
		"movements": [],
		"error": ""
	}
	
	if is_executing:
		result.error = "invalid code"
		return result
	
	var safety_check = validate_code(code)
	if not safety_check.valid:
		result.error = safety_check.error
		return result
	
	var has_func = code.contains("func ")
	
	var script = GDScript.new()
	var wrapped_code = ""
	
	if has_func:
		var indented_code = indent_code(code, 1)
		wrapped_code = """
extends Node

class PlayerProxy:
	var movements = []
	var has_error = false
	var error_message = ""
	
	func move_up(steps: int = 1):
		if not _validate_steps(steps, "move_up"):
			return
		movements.append({"method": "move_up", "steps": steps})
	
	func move_down(steps: int = 1):
		if not _validate_steps(steps, "move_down"):
			return
		movements.append({"method": "move_down", "steps": steps})
	
	func move_left(steps: int = 1):
		if not _validate_steps(steps, "move_left"):
			return
		movements.append({"method": "move_left", "steps": steps})
	
	func move_right(steps: int = 1):
		if not _validate_steps(steps, "move_right"):
			return
		movements.append({"method": "move_right", "steps": steps})
	
	func _validate_steps(steps: int, method_name: String) -> bool:
		if typeof(steps) != TYPE_INT:
			has_error = true
			error_message = "Invalid code"
			return false
		if steps < 0:
			has_error = true
			error_message = "Invalid code"
			return false
		return true

class UserCode:
	var player
	
	func _init(player_proxy):
		player = player_proxy
	
%s

func execute():
	var player_proxy = PlayerProxy.new()
	var user_code = UserCode.new(player_proxy)
	var result_data = {"movements": [], "error": "", "has_error": false}
	
	var iteration_count = 0
	var max_iterations = 100000
	
	if user_code.has_method("main"):
		user_code.main()
	
	if iteration_count > max_iterations:
		result_data.has_error = true
		result_data.error = "invalid code"
	elif player_proxy.has_error:
		result_data.has_error = true
		result_data.error = player_proxy.error_message
	else:
		result_data.movements = player_proxy.movements
	
	return result_data
""" % indented_code
	else:
		# ini semisal kl ga pake fungsi (func)
		var indented_code = indent_code(code, 1)
		wrapped_code = """
extends Node

class PlayerProxy:
	var movements = []
	var has_error = false
	var error_message = ""
	
	func move_up(steps: int = 1):
		if not _validate_steps(steps, "move_up"):
			return
		movements.append({"method": "move_up", "steps": steps})
	
	func move_down(steps: int = 1):
		if not _validate_steps(steps, "move_down"):
			return
		movements.append({"method": "move_down", "steps": steps})
	
	func move_left(steps: int = 1):
		if not _validate_steps(steps, "move_left"):
			return
		movements.append({"method": "move_left", "steps": steps})
	
	func move_right(steps: int = 1):
		if not _validate_steps(steps, "move_right"):
			return
		movements.append({"method": "move_right", "steps": steps})
	
	func _validate_steps(steps: int, method_name: String) -> bool:
		if typeof(steps) != TYPE_INT:
			has_error = true
			error_message = "Invalid code"
			return false
		if steps < 0:
			has_error = true
			error_message = "Invalid code"
			return false
		return true

func execute():
	var player = PlayerProxy.new()
	var result_data = {"movements": [], "error": "", "has_error": false}
	
	var iteration_count = 0
	var max_iterations = 100000
	
%s
	
	if iteration_count > max_iterations:
		result_data.has_error = true
		result_data.error = "invalid code"
	elif player.has_error:
		result_data.has_error = true
		result_data.error = player.error_message
	else:
		result_data.movements = player.movements
	
	return result_data
""" % indented_code
	
	script.source_code = wrapped_code
	
	is_executing = true
	var reload_error = script.reload()
	
	if reload_error != OK:
		is_executing = false
		result.error = "invalid code"
		return result
	
	var instance = Node.new()
	instance.set_script(script)
	add_child(instance)
	
	if not instance.has_method("execute"):
		instance.queue_free()
		is_executing = false
		result.error = "invalid code"
		return result
	
	var exec_result = instance.call("execute")
	
	instance.queue_free()
	is_executing = false
	
	if exec_result == null:
		result.error = "invalid code"
		return result
	
	if exec_result.has("has_error") and exec_result.has_error:
		result.success = false
		result.error = exec_result.get("error", "invalid code")
	else:
		result.success = true
		result.movements = exec_result.movements
		
		if result.movements.size() > 1000:
			result.success = false
			result.error = "too many movements"
	
	return result

func indent_code(code: String, tab_count: int = 1) -> String:
	var lines = code.split("\n")
	var indented_lines = []
	var base_indent = ""
	
	for i in range(tab_count):
		base_indent += "\t"
	
	for line in lines:
		if line.strip_edges() == "":
			indented_lines.append("")
		else:
			indented_lines.append(base_indent + line)
	
	return "\n".join(indented_lines)

func validate_code(code: String) -> Dictionary:
	var validation = {
		"valid": true,
		"error": ""
	}
	
	if code.strip_edges() == "":
		validation.valid = false
		validation.error = "invalid code"
		return validation
	
	var sus_patterns = [
		"OS.",
		"File.",
		"DirAccess.",
		"FileAccess.",
		"get_tree()",
		"queue_free()",
		"free()",
		"ProjectSettings.",
		"Engine.",
		"ResourceLoader.",
		"load(",
		"preload(",
		"ResourceSaver.",
		"IP.",
		"JavaScriptBridge.",
		"DisplayServer.",
		"RenderingServer.",
		"AudioServer.",
		"PhysicsServer",
		"NavigationServer",
		"Time.get_ticks",
		"ClassDB.",
		"GDScript.new()",
		".new_script",
		".set_script",
		"Thread.new()",
		"Mutex.new()",
		"Semaphore.new()",
		"UserCode",
		"PlayerProxy"
	]
	
	#var code_lower = code.to_lower()
	
	for pattern in sus_patterns:
		if code.contains(pattern):
			validation.valid = false
			validation.error = "Invalid code"
			return validation
	
	#if code_lower.contains("while true") and not (code_lower.contains("break") or code_lower.contains("return")):
		#validation.valid = false
		#validation.error = "Invalid code"
		#return validation
	
	return validation
