extends Control

@onready var music_slider: Slider = $SettingsPanel/VolumeSettings/MusicGroup/MusicSlider

signal close

func _on_close_button_pressed() -> void:
	close.emit()
	hide()

func _ready() -> void:
	# Make sure the slider exists before connecting it
	if is_instance_valid(music_slider):
		# 1. Connect the slider's signal to our custom function
		music_slider.value_changed.connect(_on_music_slider_value_changed)
		
		# 2. Sync the slider to the CURRENT volume when the scene loads
		# (Assuming BGMusic is an AutoLoad/Singleton)
		if has_node("/root/BGMusic"):
			var bg_music = get_node("/root/BGMusic")
			# Convert current decibels back to a 0.0-1.0 linear scale for the slider
			music_slider.value = db_to_linear(bg_music.volume_db)

# This function runs every single time you drag the slider
func _on_music_slider_value_changed(value: float) -> void:
	# Locate the BGMusic AutoLoad node
	if has_node("/root/BGMusic"):
		var bg_music = get_node("/root/BGMusic")
		
		# Convert the slider's linear value (0.0 to 1.0) into Decibels
		# Godot handles 0.0 nicely by converting it to -80db (completely muted)
		bg_music.volume_db = linear_to_db(value)
		
		# OPTIONAL: If you want to save the volume to GameData so it remembers
		# it next time the player opens the game, uncomment below:
		if has_node("/root/GameData"):
			GameData.music_volume = value
			GameData.save_game()
