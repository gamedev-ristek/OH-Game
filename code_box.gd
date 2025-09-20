extends CodeEdit

var colorText = CodeHighlighter.new()
func _ready():
	
	text_changed.connect(code_request_code_completion)
	syntax_highlighter = colorText
	
	colorText.number_color = Color("#D7437E")
	colorText.function_color = Color("#E29D39")
	colorText.member_variable_color = Color("#5096D4")  
	
	colorText.symbol_color = Color.WHITE

	colorText.add_keyword_color("player", Color.MEDIUM_PURPLE)

	colorText.add_color_region("\"", "\"", Color("#489E7C"))
	colorText.add_color_region("'", "'", Color("#489E7C"))
	colorText.add_color_region("#", "", Color(0.5, 0.5, 0.5))

func _process(delta):
	pass

func code_request_code_completion():
	
	var line = get_caret_line()
	var text = get_line(line).strip_edges()

	if text.begins_with("#"):
		return
	
	add_code_completion_option(CodeEdit.KIND_FUNCTION, "player.move_up(steps)", "player.move_up()")
	add_code_completion_option(CodeEdit.KIND_FUNCTION, "player.move_right(steps)", "player.move_right()")
	add_code_completion_option(CodeEdit.KIND_FUNCTION, "player.move_left(steps)", "player.move_left()")
	add_code_completion_option(CodeEdit.KIND_FUNCTION, "player.move_down(steps)", "player.move_down()")
	
	update_code_completion_options(true)
	
