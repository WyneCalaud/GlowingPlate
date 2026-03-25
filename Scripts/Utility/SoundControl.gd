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
		
		# 2. Sync the slider
		# DEFENSIVE FIX: Read from GameData first. If we read from BGMusic while 
		# inside QuizScene, the slider would show the incorrectly lowered volume.
		if has_node("/root/GameData") and "music_volume" in get_node("/root/GameData"):
			music_slider.value = get_node("/root/GameData").music_volume
		elif has_node("/root/BGMusic"):
			var bg_music = get_node("/root/BGMusic")
			var current_db = bg_music.volume_db
			
			# Fallback: if GameData isn't ready but we are in QuizScene, offset it back to normal for the UI
			var current_scene = get_tree().current_scene
			if is_instance_valid(current_scene) and current_scene.scene_file_path.ends_with("QuizScene.tscn"):
				current_db += 10.0
				
			music_slider.value = db_to_linear(current_db)

# This function runs every single time you drag the slider
func _on_music_slider_value_changed(value: float) -> void:
	# Locate the BGMusic AutoLoad node
	if has_node("/root/BGMusic"):
		var bg_music = get_node("/root/BGMusic")
		var target_db = linear_to_db(value)
		
		# DEFENSIVE FIX: If they adjust settings while in the QuizScene, 
		# keep it 10dB lower so it doesn't suddenly blast at full volume.
		var current_scene = get_tree().current_scene
		if is_instance_valid(current_scene) and current_scene.scene_file_path.ends_with("QuizScene.tscn"):
			target_db -= 10.0
			
		# Convert the slider's linear value (0.0 to 1.0) into Decibels
		bg_music.volume_db = target_db
		
	# Save the TRUE baseline volume to GameData
	if has_node("/root/GameData"):
		var gd = get_node("/root/GameData")
		if "music_volume" in gd:
			gd.music_volume = value
		if gd.has_method("save_game"):
			gd.save_game()
