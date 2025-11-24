extends Node2D

# --- References ---
@onready var darken_overlay = $OverlayCanvas/DarkenOverlay
@onready var almanac_ui = $OverlayCanvas/AlmanacUI
@onready var bulletin_board_ui = $OverlayCanvas/BulletinBoardUI # <-- ADD THIS

# --- State Variables ---
# Replaced 'almanac_is_open' with a variable that can track ANY popup
var current_open_popup: Control = null 
var current_popup_tween: Tween # To control the fade animation
var button_type = null # This is for your scene transition, it's fine

# --- Scene Transition Functions (No changes) ---
func _start_transition(type: String):
	button_type = type
	$Fade_transition.show()
	$Fade_transition/Fade_timer.start()
	$Fade_transition/AnimationPlayer.play("Fade_In")

func _on_day_button_pressed() -> void:
	_start_transition("day")

func _on_fade_timer_timeout() -> void:
	if button_type == "day" :
		get_tree().change_scene_to_file("res://Scenes/Gameplay/fullgameplay.tscn")
	elif button_type == "menu" :
		get_tree().change_scene_to_file("res://Scenes/Main_menu.tscn")

func _on_settings_button_pressed() -> void:
	_start_transition("menu")

# --- Popup Button Triggers ---
func _on_almanac_pressed() -> void:
	if current_open_popup == almanac_ui:
		close_popup()
	elif current_open_popup == null:
		open_popup(almanac_ui)

func _on_bulletin_board_pressed() -> void:
	if current_open_popup == bulletin_board_ui:
		close_popup()
	elif current_open_popup == null:
		open_popup(bulletin_board_ui)

# --- Generic Popup Functions (Refactored) ---
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and current_open_popup != null:
		close_popup()

# This new function can open ANY popup node you pass to it
func open_popup(popup_node: Control) -> void:
	if current_popup_tween and current_popup_tween.is_valid():
		current_popup_tween.kill() # Stop any ongoing animation

	current_open_popup = popup_node # Set the current popup
	darken_overlay.show()
	current_open_popup.show()
	
	current_popup_tween = create_tween()
	current_popup_tween.set_parallel(true)
	
	current_popup_tween.tween_property(darken_overlay, "modulate:a", 0.5, 0.3)
	current_popup_tween.tween_property(current_open_popup, "modulate:a", 1.0, 0.3).from(0.0)
	
func close_popup() -> void:
	# Do nothing if no popup is open
	if current_open_popup == null:
		return
		
	if current_popup_tween and current_popup_tween.is_valid():
		current_popup_tween.kill()

	var popup_to_close = current_open_popup # Store which popup we're closing
	current_open_popup = null # Set state to "closing"
	
	current_popup_tween = create_tween()
	current_popup_tween.set_parallel(true)
	
	current_popup_tween.tween_property(darken_overlay, "modulate:a", 0.0, 0.3)
	current_popup_tween.tween_property(popup_to_close, "modulate:a", 0.0, 0.3)
	
	current_popup_tween.finished.connect(func(): 
		darken_overlay.hide()
		popup_to_close.hide()
		popup_to_close.modulate.a = 1.0 # Reset for next time
	)

# --- Popup Close Signal Handlers ---
func _on_almanac_ui_closed() -> void:
	close_popup()
func _on_bulletin_board_ui_closed() -> void:
	close_popup()
