extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@export var code_editor : Node2D
@export var mark_scene : PackedScene
const STEP = 48 # 1 tile size
enum DIRECTION {LEFT, RIGHT, UP, DOWN}

var reset_pos
var direction = DIRECTION.UP
var is_moving = false
var target_pos = Vector2.ZERO


func set_movement(command: String):
	is_moving = true
	velocity = Vector2.ZERO
	var steps = 1
	
	var directions = {
		"up": {"offset": 15, "vec": Vector2(0, -1), "anim": "move_up"},
		"left": {"offset": 17, "vec": Vector2(-1, 0), "anim": "move_left"},
		"right": {"offset": 18, "vec": Vector2(1, 0), "anim": "move_right"},
		"down": {"offset": 17, "vec": Vector2(0, 1), "anim": "move_down"},
	}
	
	for dir in directions.keys():
		if command.contains(dir):
			var start = directions[dir]["offset"]
			var step_str = command.substr(start, command.length() - (start + 1))
			if step_str != "":
				steps = int(step_str)
			
			match dir:
				"up": direction = DIRECTION.UP
				"left": direction = DIRECTION.LEFT
				"right": direction = DIRECTION.RIGHT
				"down": direction = DIRECTION.DOWN
			
			var dir_vec: Vector2 = directions[dir]["vec"]
			velocity = dir_vec * STEP * steps
			sprite.play(directions[dir]["anim"])
			break
	
	target_pos = global_position + velocity
	create_mark(target_pos)

func _ready() -> void:
	reset_pos = global_position

func _process(delta: float) -> void:
	if is_moving and global_position.distance_to(target_pos) < 1:
		global_position = target_pos
		velocity = Vector2.ZERO
		is_moving = false
		code_editor.emit_signal("execute_next_command")
	elif not is_moving:
		match direction:
			DIRECTION.UP:
				sprite.play("idle_up")
			DIRECTION.LEFT:
				sprite.play("idle_left")	
			DIRECTION.RIGHT:
				sprite.play("idle_right")
			DIRECTION.DOWN:
				sprite.play("idle_down")

func _physics_process(delta: float) -> void:
	if is_moving:
		var move_dir = (target_pos - global_position).normalized()
		velocity = move_dir * STEP
		move_and_slide()
	else:
		velocity = Vector2.ZERO



func reset():
	global_position = reset_pos
	clear_marks()
	
func create_mark(target_pos):
	var mark = mark_scene.instantiate()
	mark.global_position = target_pos + Vector2(0, 20)
	get_parent().find_child("Marks").add_child(mark)



func clear_marks():
	var marks = get_parent().find_child("Marks")
	for mark in marks.get_children():
		mark.queue_free()
	
