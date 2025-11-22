extends CanvasLayer

signal line_changed(text_line: String)

const CHAR_READ_RATE = 0.05

# --- Node References ---
@onready var textbox_container = $TextboxContainer
@onready var start_symbol = $TextboxContainer/MarginContainer/HBoxContainer/Start
@onready var end_symbol = $TextboxContainer/MarginContainer/HBoxContainer/End
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label

# This will hold the tween that is currently running the animation.
var active_tween: Tween

# --- State Machine ---
enum State {
	READY,    # Waiting to show the next line of text
	READING,  # Text is currently being typed out
	FINISHED  # Text is finished typing, waiting for input
}

var current_state = State.READY
var text_queue = []


func _ready() -> void:
	# Hide the textbox immediately so it's not visible during the transition
	hide_textbox()
	
	# --- ADD THIS LINE ---
	# This creates a temporary 2-second timer and waits for it to finish.
	await get_tree().create_timer(2.0).timeout
	
	print("Starting state: State.READY")
	hide_textbox()
	
	# Add all your dialogue lines here
	queue_text("You are building a balanced meal.")
	queue_text("This is the plate, which has 4 sections, one for each food group.")
	queue_text("This is for the GO food.")
	queue_text("This is for the GROW food.")
	queue_text("This is for the GLOW food, like fruits.")
	queue_text("And this is for the other GLOW food, like vegetables.")
	queue_text("Great! Now let's try with the full set!")
	
# --- This is our "Command Center" for Player Input ---
func handle_player_input():
	if current_state == State.READING:
		# If text is typing, skip the animation to the end
		if active_tween and active_tween.is_valid():
			active_tween.kill()
		
		label.visible_characters = -1
		on_tween_finished() # Call this manually to finish the state change
		
	elif current_state == State.FINISHED:
		# If text is finished, advance to the next line
		change_state(State.READY)
		hide_textbox()

# --- Input Triggers ---
func _input(event: InputEvent) -> void:
	# Trigger for Mobile Screen Taps
	if event is InputEventScreenTouch and event.is_pressed():
		handle_player_input()

func _process(delta):
	# Trigger for showing the next line automatically
	if current_state == State.READY and not text_queue.is_empty():
		display_text()

	# Trigger for Keyboard/Controller Input
	if Input.is_action_just_pressed("ui_accept"):
		handle_player_input()

# --- Helper Functions ---
func queue_text(next_text: String):
	text_queue.push_back(next_text)

func hide_textbox():
	start_symbol.text = ""
	end_symbol.text = ""
	label.text = ""
	label.visible_characters = 0
	textbox_container.hide()

func show_textbox():
	start_symbol.text = ""
	end_symbol.text = ""
	textbox_container.show()

func display_text():
	var next_text = text_queue.pop_front()
	line_changed.emit(next_text)
	label.text = next_text
	change_state(State.READING)
	show_textbox()
	
	active_tween = create_tween()
	active_tween.finished.connect(on_tween_finished)
	active_tween.tween_property(label, "visible_characters", len(next_text), len(next_text) * CHAR_READ_RATE).from(0)

func on_tween_finished():
	if current_state == State.READING:
		end_symbol.text = ">"
		change_state(State.FINISHED)

func change_state(next_state):
	current_state = next_state
	# print("Changing state to: ", State.keys()[next_state]) # A helpful debug print
