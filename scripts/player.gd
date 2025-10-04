extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var stuck_timer: Timer = Timer.new()
@export var code_editor : Node2D
@export var mark_scene : PackedScene

const STEP = 48
const STUCK_TIMEOUT = 5.0
enum DIRECTION {LEFT, RIGHT, UP, DOWN}

var reset_pos
var direction = DIRECTION.UP
var is_moving = false
var target_pos = Vector2.ZERO
var is_stuck = false
var movement_aborted = false

func _ready() -> void:
	reset_pos = global_position
	
	add_child(stuck_timer)
	stuck_timer.one_shot = true
	stuck_timer.timeout.connect(_on_stuck_timeout)

func move_up(steps: int = 1):
	if steps <= 0 or steps > 10 or is_stuck or movement_aborted:
		return
	_execute_movement(Vector2(0, -1), steps, "move_up", DIRECTION.UP)

func move_down(steps: int = 1):
	if steps <= 0 or steps > 10 or is_stuck or movement_aborted:
		return
	_execute_movement(Vector2(0, 1), steps, "move_down", DIRECTION.DOWN)

func move_left(steps: int = 1):
	if steps <= 0 or steps > 10 or is_stuck or movement_aborted:
		return
	_execute_movement(Vector2(-1, 0), steps, "move_left", DIRECTION.LEFT)

func move_right(steps: int = 1):
	if steps <= 0 or steps > 10 or is_stuck or movement_aborted:
		return
	_execute_movement(Vector2(1, 0), steps, "move_right", DIRECTION.RIGHT)

func _execute_movement(dir_vec: Vector2, steps: int, anim_name: String, dir: DIRECTION):
	is_moving = true
	movement_aborted = false
	direction = dir
	velocity = dir_vec * STEP * steps
	sprite.play(anim_name)
	target_pos = global_position + velocity
	create_mark(target_pos)
	
	stuck_timer.start(STUCK_TIMEOUT)

func _process(delta: float) -> void:
	if is_moving and global_position.distance_to(target_pos) < 1:
		global_position = target_pos
		velocity = Vector2.ZERO
		is_moving = false
		movement_aborted = false
		stuck_timer.stop()
	elif not is_moving and not is_stuck:
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
	if is_moving and not movement_aborted:
		var move_dir = (target_pos - global_position).normalized()
		velocity = move_dir * STEP * 3
		var collision = move_and_slide()
		
		if get_slide_collision_count() > 0:
			var current_pos = global_position
			await get_tree().process_frame
			if is_moving and global_position.distance_to(current_pos) < 0.5:
				print("collision detected")
	else:
		velocity = Vector2.ZERO

func _on_stuck_timeout():
	if is_moving:
		print("aborted")
		_abort_movement()

func _abort_movement():
	is_moving = false
	movement_aborted = true
	is_stuck = true
	velocity = Vector2.ZERO
	stuck_timer.stop()
	
	match direction:
		DIRECTION.UP:
			sprite.play("idle_up")
		DIRECTION.LEFT:
			sprite.play("idle_left")	
		DIRECTION.RIGHT:
			sprite.play("idle_right")
		DIRECTION.DOWN:
			sprite.play("idle_down")
	
	if code_editor and code_editor.has_method("abort_execution"):
		code_editor.abort_execution()

func reset():
	#global_position = reset_pos
	clear_marks()
	is_stuck = false
	is_moving = false
	movement_aborted = false
	velocity = Vector2.ZERO
	stuck_timer.stop()
	
	match direction:
		DIRECTION.UP:
			sprite.play("idle_up")
		DIRECTION.LEFT:
			sprite.play("idle_left")	
		DIRECTION.RIGHT:
			sprite.play("idle_right")
		DIRECTION.DOWN:
			sprite.play("idle_down")
	
func create_mark(target_pos):
	var mark = mark_scene.instantiate()
	mark.global_position = target_pos + Vector2(0, 20)
	get_parent().find_child("Marks").add_child(mark)

func clear_marks():
	var marks = get_parent().find_child("Marks")
	for mark in marks.get_children():
		mark.queue_free()

func is_movement_aborted() -> bool:
	return movement_aborted
