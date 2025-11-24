extends Node2D

@onready var foodplate = $FoodPlate
@onready var pointer = $Pointer


func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
