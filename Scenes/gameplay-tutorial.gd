extends Node2D

@onready var dialogue_box = $DialogueBox
@onready var plate = $Plate
@onready var pointer = $Pointer

# --- Section Labels (from before) ---
@onready var go_label = $Plate/Go
@onready var grow_label = $Plate/Grow
@onready var glow_veggie_label = $Plate/GlowV
@onready var glow_fruit_label = $Plate/GlowF

# --- NEW: References to Stations and Tabs ---
@onready var go_station = $GoStation
@onready var grow_station = $GrowStation
@onready var glow_station = $GlowStation
@onready var tab_buttons_container = $Tabs
@onready var go_button = $Tabs/Label/Go
@onready var grow_button = $Tabs/Label2/Grow
@onready var glow_button = $Tabs/Label3/Glow

# --- CHANGED: Define unique positions for each station ---
var go_station_pos = Vector2(697.0, 236.0) # The original position
var grow_station_pos = Vector2(403.0, 197.0) # The new position
var glow_station_pos = Vector2(403.0, 197.0) # The new position

func _ready():
	# --- NEW: Connect button signals to our functions ---
	go_button.pressed.connect(show_go_station)
	grow_button.pressed.connect(show_grow_station)
	glow_button.pressed.connect(show_glow_station)
	
	# --- NEW: Set up the initial scene state ---
	go_station.hide()
	grow_station.hide()
	glow_station.hide()
	tab_buttons_container.hide()
	
	# --- CHANGED: Set all stations to their unique positions ---
	go_station.position = go_station_pos
	grow_station.position = grow_station_pos
	glow_station.position = glow_station_pos

# --- This is your main tutorial logic function ---
func _on_dialogue_box_line_changed(text_line: String):
	pointer.hide()
	hide_all_section_labels()
	
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
			
		"Great! Now let's prepare the GO foods.":
			# This line's ONLY job is to start the animation.
			transition_to_stations()
			
		"This is a rice cooker. We use it to cook rice,":
			# This line points at the rice cooker (which is inside GoStation)
			pointer.position = Vector2(610.0, 252.0)
			pointer.rotation_degrees = 180.0
			pointer.show()
			
		"also a measuring cup for the rice.":
			# This line points at the rice cup
			pointer.position = Vector2(610.0, 420.0)
			pointer.rotation_degrees = 180.0
			pointer.show()
			
		"This is a locked Go food that you will need to play more to unlock!":
			pointer.position = Vector2(1013.0, 308.0)
			pointer.rotation_degrees = -90.0
			pointer.show()
			
		_:
			pointer.hide()

# --- Helper function to hide labels ---
func hide_all_section_labels():
	go_label.hide()
	grow_label.hide()
	glow_veggie_label.hide()
	glow_fruit_label.hide()

# --- NEW: Helper function to hide stations ---
func hide_all_stations():
	go_station.hide()
	grow_station.hide()
	glow_station.hide()

# --- NEW: Functions called by button presses ---
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
# Note: This function still needs the 'async' keyword to use 'await'.
# If you are still having trouble with 'async', you must fix the indentation
# of the function directly BEFORE this one.
func transition_to_stations():
	var tween = create_tween()
	tween.tween_property($Plate, "position", Vector2(280.0, $Plate.position.y), 1.0).set_ease(Tween.EASE_IN_OUT)
	
	# Wait for the plate to finish moving
	await tween.finished
	
	# --- NEW: After animation, show the stations and tabs ---
	tab_buttons_container.show() # Show the "Go, Grow, Glow" buttons
	show_go_station() # Show the Go station by default
	
