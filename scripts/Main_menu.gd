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
	if FileAccess.file_exists("user://save_data.json"):
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
	active_tween = create_tween()
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

func _show_menu_ui():
	if background: background.show()
	if start_button: start_button.show()

# --- Transition Logic ---
func _on_start_pressed() -> void:
	if button_type != null: return # Prevent double trigger
	button_type = "start"
	_play_transition_animation()

func _on_settings_pressed() -> void:
	if button_type != null: return
	button_type = "options"
	_play_transition_animation()

func _play_transition_animation():
	var trans = get_node_or_null("fade_transition")
	if trans:
		trans.show()
		var anim = trans.get_node_or_null("AnimationPlayer")
		var timer = trans.get_node_or_null("Fade_timer")
		if anim: anim.play("Fade_In")
		if timer: timer.start()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_fade_timer_timeout() -> void:
	if button_type == "start":
		# --- SAVE STATE DETECTION / ROUTING ---
		if FileAccess.file_exists("user://save_data.json"):
			# Player has played before, load right into the canteen!
			print("Save found! Resuming game...")
			get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
		else:
			# Brand new player, play the Intro Scene!
			print("No save found. Starting New Game / Intro...")
			if intro_scene_path != "":
				get_tree().change_scene_to_file(intro_scene_path)
			else:
				printerr("Intro scene path is empty! Please assign it in the inspector.")
				get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn") # Fallback

func _on_settings_button_pressed() -> void:
	if sound_control:
		sound_control.visible = true
		sound_control.move_to_front()
