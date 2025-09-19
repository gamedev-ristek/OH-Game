extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_outfit_left_pressed() -> void:
	CharacterInformation.update_outfit(CharacterInformation.outfit_index-1)
	
func _on_outfit_right_pressed() -> void:
	CharacterInformation.update_outfit(CharacterInformation.outfit_index+1)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level/level_1.tscn")

func _on_male_button_pressed() -> void:
	CharacterInformation.update_type("male")

func _on_female_button_pressed() -> void:
	CharacterInformation.update_type("female")

func _on_panda_button_pressed() -> void:
	CharacterInformation.update_type("panda")
