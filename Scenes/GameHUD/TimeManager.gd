extends TextureRect

# Drag and drop your 4 textures into these slots in the Inspector
@export_group("Cycle Textures")
@export var first_cycle: Texture2D
@export var second_cycle: Texture2D
@export var third_cycle: Texture2D
@export var fourth_cycle: Texture2D

@onready var time_label: Label = $Time

func _ready():
	# Add this node to the HUD group so GameData can find it
	add_to_group("HUD")
	refresh_cycle_visuals()

func refresh_cycle_visuals():
	# 1. Update the Sun Texture
	var stage = GameData.get_sun_stage_index()
	match stage:
		0: texture = first_cycle
		1: texture = second_cycle
		2: texture = third_cycle
		3: texture = fourth_cycle
	
	# 2. Update the Clock Text
	if time_label:
		time_label.text = GameData.get_current_time_string()
