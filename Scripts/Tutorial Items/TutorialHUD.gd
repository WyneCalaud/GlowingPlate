extends CanvasLayer

# --- UI REFERENCES ---
@onready var menu_button: TextureButton = $TopBarRight/MenuGroup/MenuButton
@onready var almanac_button: TextureButton = $TopBarRight/MenuGroup/MenuButton/AlmanacButton

# Assuming you have your Almanac UI in this scene too. 
# Adjust this path if your AlmanacUI is named or placed differently!
@onready var almanac_ui: Control = $AlmanacUI

# --- ANIMATION SETTINGS ---
var is_menu_open: bool = false
var menu_tween: Tween
const ANIM_DURATION: float = 0.3
const BUTTON_SPACING: float = 70.0 # Distance the button drops down

func _ready() -> void:
	# 1. Ensure the CanvasLayer renders on top of the game world
	self.layer = 1
	
	# 2. Setup the MenuButton Z-index so it stays in front of the dropping button
	if menu_button:
		menu_button.z_index = 0
	
	# 3. Setup the Almanac Button initial state (Hidden, tucked behind the MenuButton)
	if almanac_button:
		almanac_button.top_level = false
		almanac_button.z_index = -1 # Render BEHIND the menu button
		almanac_button.position = Vector2.ZERO # Start at exactly the same spot
		almanac_button.visible = false
		almanac_button.modulate.a = 0.0 # Make it fully transparent initially
		almanac_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 4. Connect button clicks
	if menu_button and not menu_button.is_connected("pressed", _on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)
		
	if almanac_button and not almanac_button.is_connected("pressed", _on_almanac_pressed):
		almanac_button.pressed.connect(_on_almanac_pressed)
		
	# 5. Connect Almanac UI close signal (if it exists)
	if almanac_ui and almanac_ui.has_signal("closed") and not almanac_ui.is_connected("closed", _on_almanac_closed):
		almanac_ui.closed.connect(_on_almanac_closed)


func _on_menu_button_pressed() -> void:
	# ---> TRIGGER THE TUTORIAL ACTION HERE <---
	# This shouts out to Interactive.gd to let it know the menu was pressed
	get_tree().call_group("InteractiveTutorial", "action_completed", "Menu_Pressed")
	
	is_menu_open = !is_menu_open
	
	# Stop any currently playing animation
	if menu_tween: 
		menu_tween.kill()
		
	# Create a new animation
	menu_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	if is_menu_open:
		# --- OPEN MENU ---
		almanac_button.visible = true
		almanac_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Animate Y position downwards (slides out from behind)
		menu_tween.tween_property(almanac_button, "position:y", BUTTON_SPACING, ANIM_DURATION)
		# Fade in
		menu_tween.tween_property(almanac_button, "modulate:a", 1.0, ANIM_DURATION)
		
	else:
		# --- CLOSE MENU ---
		almanac_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Animate Y position back up to 0 (slides back behind menu button)
		menu_tween.tween_property(almanac_button, "position:y", 0.0, ANIM_DURATION)
		# Fade out
		menu_tween.tween_property(almanac_button, "modulate:a", 0.0, ANIM_DURATION)
		
		# Once the animation finishes, completely hide the node
		menu_tween.chain().tween_callback(func(): 
			almanac_button.visible = false
		)

func _on_almanac_pressed() -> void:
	# ---> TRIGGER THE TUTORIAL ACTION HERE <---
	# This shouts out to Interactive.gd to let it know the almanac was pressed
	get_tree().call_group("InteractiveTutorial", "action_completed", "Almanac_Pressed")
	
	if almanac_ui:
		almanac_ui.visible = true
		almanac_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Automatically close the dropdown menu when Almanac is opened
	_on_menu_button_pressed() 

func _on_almanac_closed() -> void:
	if almanac_ui:
		almanac_ui.visible = false
		almanac_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
