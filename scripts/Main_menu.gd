extends Control

# --- NEW: Drag and drop your Intro Scene here in the Inspector! ---
@export_file("*.tscn") var intro_scene_path: String = "res://Scenes/Intro/Intro.tscn"

# UI Node References with safety checks
@onready var btn_settings: BaseButton = get_node_or_null("Background/TopBarRight/SettingsButton")
@onready var sound_control: Control = get_node_or_null("SoundControl")
@onready var video_player: VideoStreamPlayer = get_node_or_null("VideoStreamPlayer")
@onready var background: Control = get_node_or_null("Background")
@onready var start_button: BaseButton = $UI/Start

var button_type = null
var is_playing_intro: bool = false
var anti_flash_overlay: ColorRect
var active_tween: Tween

func _enter_tree():
	# Ensure the background clear color is black at the engine level immediately
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	# Create a CanvasLayer for a high-priority overlay
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)

	anti_flash_overlay = ColorRect.new()
	anti_flash_overlay.color = Color.BLACK
	anti_flash_overlay.set_anchors_preset(PRESET_FULL_RECT)
	anti_flash_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(anti_flash_overlay)

func _ready():
	_hide_menu_ui()
	
	# Handle Video vs Menu Logic
	if GameData.intro_completed:
		if video_player:
			video_player.stop()
			video_player.hide()
		_show_menu_ui()
		_safe_fade_reveal(0.2)
	else:
		if video_player:
			is_playing_intro = true
			video_player.show()
			video_player.play()
			if not video_player.finished.is_connected(_on_video_finished):
				video_player.finished.connect(_on_video_finished)
			_safe_fade_reveal(0.5) # Longer delay for video buffer
		else:
			_show_menu_ui()
			_safe_fade_reveal(0.2)

func _safe_fade_reveal(delay: float):
	if active_tween: active_tween.kill()
	active_tween = create_tween().bind_node(self)
	active_tween.tween_interval(delay)
	active_tween.tween_property(anti_flash_overlay, "modulate:a", 0.0, 0.4)
	active_tween.tween_callback(func():
		if anti_flash_overlay and is_instance_valid(anti_flash_overlay):
			var parent = anti_flash_overlay.get_parent()
			if parent is CanvasLayer: parent.queue_free()
	)

func _input(event):
	if is_playing_intro and (event is InputEventMouseButton or event is InputEventKey):
		if event.is_pressed():
			get_viewport().set_input_as_handled()
			_on_video_finished()

func _on_video_finished() -> void:
	if not is_playing_intro: return 
	is_playing_intro = false
	if video_player:
		video_player.stop()
		# Explicitly clear the stream to release GPU/Memory handles
		video_player.stream = null 
		video_player.hide()
	_show_menu_ui()

func _hide_menu_ui():
	if background: background.hide()
	if start_button: start_button.hide()
	if btn_settings: btn_settings.hide()

func _show_menu_ui():
	if background: background.show()

	# --- 🟢 NEW: BOUNCY POP-OUT ANIMATION ---
	var pop_tween = create_tween().bind_node(self).set_parallel(true).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	if is_instance_valid(start_button):
		start_button.show()
		# Center the pivot so it scales out from the middle instead of the top-left
		start_button.pivot_offset = start_button.size / 2
		start_button.scale = Vector2.ZERO
		pop_tween.tween_property(start_button, "scale", Vector2.ONE, 0.8)
		
	if is_instance_valid(btn_settings):
		btn_settings.show()
		btn_settings.pivot_offset = btn_settings.size / 2
		btn_settings.scale = Vector2.ZERO
		# Delay the settings button by 0.15s for a nice cascading 1-2 sequence
		pop_tween.tween_property(btn_settings, "scale", Vector2.ONE, 0.8).set_delay(0.15)

# --- Transition Logic ---
func _on_start_pressed() -> void:
	if button_type != null: return # Prevent double trigger
	button_type = "start"
	_play_transition_animation()

func _on_settings_pressed() -> void:
	# Fixed bug where clicking settings caused a black screen
	_on_settings_button_pressed()

func _on_settings_button_pressed() -> void:
	if sound_control:
		sound_control.visible = true
		sound_control.move_to_front()
		
		# Optional: Give the settings panel a tiny pop animation too!
		sound_control.scale = Vector2(0.8, 0.8)
		sound_control.pivot_offset = sound_control.size / 2
		var panel_tween = create_tween().bind_node(self).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		panel_tween.tween_property(sound_control, "scale", Vector2.ONE, 0.3)

func _play_transition_animation():
	# --- 🟢 NEW: SMOOTH PROGRAMMATIC LONG FADE ---
	# This generates a pure-code fade out that guarantees a smooth 1.5-second 
	# transition without relying on AnimationPlayer nodes.
	var fade_canvas = CanvasLayer.new()
	fade_canvas.layer = 150 # Absolute topmost layer
	add_child(fade_canvas)
	
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0) # Start fully transparent
	fade_rect.set_anchors_preset(PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP # Blocks all clicking while fading
	fade_canvas.add_child(fade_rect)
	
	# Tween the screen to pure black over 1.5 seconds (slower & smoother)
	var fade_tween = create_tween().bind_node(self)
	fade_tween.tween_property(fade_rect, "color:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Once it goes black, load the next scene!
	fade_tween.tween_callback(_execute_scene_change)

func _execute_scene_change() -> void:
	if button_type == "start":

		# FIRST TIME PLAY (Intro not finished yet)
		if not GameData.intro_completed:
			print("First time player. Starting Intro...")

			if intro_scene_path != "":
				get_tree().change_scene_to_file(intro_scene_path)
			else:
				printerr("Intro scene path is empty!")
				get_tree().change_scene_to_file(GameData.LOBBY_CANTEEN_PATH)

			return

		# EXISTING PLAYER
		print("Returning player. Loading lobby...")
		get_tree().change_scene_to_file(GameData.LOBBY_CANTEEN_PATH)

func _on_exit_pressed() -> void:
	get_tree().quit()

# Note: We leave this function here just in case the Timer node in the Editor 
# is still connected to it, preventing Godot from throwing a missing function error.
func _on_fade_timer_timeout() -> void:
	pass
