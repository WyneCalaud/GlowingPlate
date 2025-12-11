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
	$NextCustomer.show()
	$BottomButtons/Almanac/Almanac.hide()
	$"BottomButtons/Bulletin Board/Bulletin Board".hide()
	$"BottomButtons/Day/Day Button".hide()
	
func _on_fade_timer_timeout() -> void:
	#if button_type == "day" :
		#get_tree().change_scene_to_file("res://Scenes/Gameplay/fullgameplay.tscn")
	if button_type == "menu" :
		get_tree().change_scene_to_file("res://Scenes/Main Menu/Main_menu.tscn")

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

func _ready():
	# existing code...
	# AFTER your popup setup, check if we returned from kitchen with a plate
	_check_for_returned_plate()

func _check_for_returned_plate():
	if not is_instance_valid(get_node("/root/GameData")):
		return
	var GD = get_node("/root/GameData")
	if GD.prepared_plate_contents.size() > 0:
		show_final_plate(GD.prepared_plate_contents)
	else:
		$FinalPlateDisplay.hide()

func show_final_plate(contents: Array) -> void:
	$FinalPlateDisplay.show()

	# Always show the plate base
	$FinalPlateDisplay/PlateDisplay.texture = preload("res://Items/Plates/Plate Final.png")

	# Hide all category slots
	$FinalPlateDisplay/PlateSpriteGo.hide()
	$FinalPlateDisplay/PlateSpriteGrow.hide()
	$FinalPlateDisplay/PlateSpriteVeg.hide()
	$FinalPlateDisplay/PlateSpriteFru.hide()

	# Desired scale factor (adjust this to make items smaller/bigger)
	var food_scale = Vector2(0.1, 0.1)

	for entry in contents:
		var res = entry.get("item")
		var category = entry.get("accepted_type")

		if not res:
			continue

		var tex = null

		# 1) default plated texture
		if "default_plated_texture" in res:
			tex = res.default_plated_texture

		# 2) rice special case
		if res.has_meta("RiceAmount"):
			match res.get_meta("RiceAmount"):
				"Small":  tex = res.plated_texture_small
				"TooHigh": tex = res.plated_texture_too_high

		# Assign to correct sprite
		var sprite: Sprite2D = null
		match category:
			"Go":
				sprite = $FinalPlateDisplay/PlateSpriteGo
			"Grow":
				sprite = $FinalPlateDisplay/PlateSpriteGrow
			"GlowVeg":
				sprite = $FinalPlateDisplay/PlateSpriteVeg
			"GlowFru":
				sprite = $FinalPlateDisplay/PlateSpriteFru
			_:
				print("Unknown food category:", category)

		if sprite and tex:
			sprite.texture = tex
			sprite.scale = food_scale  # <-- THIS MAKES IT SMALLER
			sprite.show()



func _on_BtnFinalServe_pressed():
	# Final serving: evaluate, finalize service, show reaction then clean.
	var GD = get_node("/root/GameData")
	# OPTION: Evaluate correctness again here by comparing prepared_plate_contents vs current_customer_order
	var correct = true
	# (If you stored 'correct' earlier in GameData you can use it; else re-run a small check.)
	# For now assume Kitchen already determined correctness; you can set GameData.prepared_is_correct before transition.
	if GD.has("prepared_is_correct") and GD.prepared_is_correct == true:
		correct = true
	else:
		# fallback: assume correct, or implement a re-check as above
		correct = true

	# Play reaction (simple text update or animation)
	if correct:
		print("Customer happy!")
	else:
		print("Customer unhappy!")

	# finalize day result: compute earned money/reputation
	var day_result = {"earned_money": 10 if correct else 0, "reputation_change": 1.0 if correct else -0.5}
	GD.finalize_service(day_result)

	# cleanup UI and stored plate
	GD.prepared_plate_contents.clear()
	if GD.has("prepared_is_correct"):
		GD.prepared_is_correct = null
	$FinalPlateDisplay.hide()
