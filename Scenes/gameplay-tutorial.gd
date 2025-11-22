extends Node2D

@onready var dialogue_box = $DialogueBox
@onready var plate = $Plate
@onready var foodplate = $FoodPlate
@onready var pointer = $Pointer

# --- Section Labels (from before) ---
# NOTE: Keeping these @onready vars for now, even if not used in the match block, 
# to avoid errors if they are used elsewhere.
@onready var go_label = $Plate/Go
@onready var grow_label = $Plate/Grow
@onready var glow_veggie_label = $Plate/GlowV
@onready var glow_fruit_label = $Plate/GlowF

# --- NEW: References to Stations (Tabs and Buttons removed) ---
@onready var go_station = $GoStation
@onready var grow_station = $GrowStation
@onready var glow_station = $GlowStation
# @onready var tab_buttons_container = $Tabs # REMOVED
# @onready var go_button = $Tabs/Label/Go # REMOVED
# @onready var grow_button = $Tabs/Label2/Grow # REMOVED
# @onready var glow_button = $Tabs/Label3/Glow # REMOVED

# --- NEW/FIXED: Initialize scene state on load ---
func _ready() -> void:
	# 1. Hide all stations immediately when the scene starts
	hide_all_stations()
	# 2. Hide tabs container (if it still exists in the scene tree)
	# If $Tabs no longer exists, delete this line: $Tabs.hide() 
	
# --- REVISED Helper function to hide section labels (used in match block) ---
# NOTE: You need this to clear the labels before showing the pointer.
func hide_all_section_labels():
	go_label.hide()
	grow_label.hide()
	glow_veggie_label.hide()
	glow_fruit_label.hide()

# --- NEW/FIXED: Helper function to hide stations ---
func hide_all_stations():
	go_station.hide()
	grow_station.hide()
	glow_station.hide()

# --- This is your main tutorial logic function ---
func _on_dialogue_box_line_changed(text_line: String):
	
	pointer.hide()
	hide_all_section_labels() # Keep this to clear labels from previous lines
	
	match text_line:
		"This is the plate, which has 4 sections, one for each food group.":
			plate.position = Vector2(600.0, 320.0)
			pointer.position = Vector2(812.0, 316.0)
			pointer.rotation_degrees = 0.0
			pointer.show()
			
		"This is for GO food.":
			pointer.position = Vector2(410.0, 456.0)
			pointer.rotation_degrees = 141.8
			pointer.show()
			go_label.show()
			
		"This is for GROW food.":
			pointer.position = Vector2(739.0, 469.0)
			pointer.rotation_degrees = 36.3
			pointer.show()
			grow_label.show()
			
		"This is for GLOW food, like fruits.":
			pointer.position = Vector2(751.0, 164.0)
			pointer.rotation_degrees = -43.7
			pointer.show()
			glow_fruit_label.show()
			
		"And this is for other GLOW food, like vegetables.":
			pointer.position = Vector2(417.0, 165.0)
			pointer.rotation_degrees = -138.2
			pointer.show()
			glow_veggie_label.show()
			
		"Great! Now let's try now with the full set!":
			# This line's ONLY job is to start the animation.
			plate.hide()
			transition_to_stations()
			
		_:
			pointer.hide()

# --- NEW: Helper functions to show stations (Simplified) ---
func show_go_station():
	hide_all_stations()
	go_station.show()

func show_grow_station():
	hide_all_stations()
	grow_station.show()

func show_glow_station():
	hide_all_stations()
	glow_station.show()

# --- REVISED Transition Function ---
func transition_to_stations():
	var tween = create_tween()
	# The FoodPlate is already the root of the plate assets, so moving it is sufficient
	tween.tween_property($FoodPlate, "position", Vector2(280.0, $FoodPlate.position.y), 1.0).set_ease(Tween.EASE_IN_OUT)
	
	# Wait for the plate to finish moving
	await tween.finished
	show_go_station() # Show the Go station by default
	show_grow_station()
	show_glow_station()
