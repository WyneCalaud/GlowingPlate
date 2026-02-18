extends Control
signal closed

func _on_texture_button_pressed() -> void:
	closed.emit()

# --- SCENE REFERENCES ---
@onready var exit_button: TextureButton = $Almanac/Exitbutton
@onready var category_sign: TextureRect = $Almanac/LeftPage/CategorySign
@onready var right_info: TextureRect = $Almanac/RightPage/RighSideInfo

# Tabs
@onready var tab_go: TextureButton = $Almanac/GoTab
@onready var tab_grow: TextureButton = $Almanac/GrowTab
@onready var tab_glow: TextureButton = $Almanac/GlowTab
@onready var tab_portion: BaseButton = $Almanac/PortionTab # NEW: Portion Tab

# Grids
@onready var grid_2x2: GridContainer = $"Almanac/LeftPage/2x2"
@onready var grid_3x3: GridContainer = $"Almanac/LeftPage/3x3"

# --- CONFIGURATION (Assign in Inspector) ---

@export_group("Signs")
@export var sign_go_texture: Texture2D
@export var sign_grow_texture: Texture2D
@export var sign_glow_texture: Texture2D

@export_group("Go Data")
@export var go_default_info: Texture2D # Shown when tab is opened
@export var go_btn_icons: Array[Texture2D] # Textures for the 4 buttons
@export var go_info_pages: Array[Texture2D] # Textures for the Right Page (Standard)
@export var go_portion_pages: Array[Texture2D] # NEW: Textures for Portion Info

@export_group("Grow Data")
@export var grow_default_info: Texture2D
@export var grow_btn_icons: Array[Texture2D]
@export var grow_info_pages: Array[Texture2D]
@export var grow_portion_pages: Array[Texture2D] # NEW: Textures for Portion Info

@export_group("Glow Data")
@export var glow_default_info: Texture2D
@export var glow_btn_icons: Array[Texture2D]
@export var glow_info_pages: Array[Texture2D]
@export var glow_portion_pages: Array[Texture2D] # NEW: Textures for Portion Info

# --- STATE ---
var current_category: String = "Go"
var active_buttons: Array = []
var current_food_index: int = -1 # Tracks which food is currently selected (-1 if none)

func _ready():
	# 1. Setup Category Tabs
	tab_go.pressed.connect(func(): _switch_category("Go"))
	tab_grow.pressed.connect(func(): _switch_category("Grow"))
	tab_glow.pressed.connect(func(): _switch_category("Glow"))
	
	# 2. Setup Portion Tab
	if tab_portion:
		tab_portion.toggle_mode = true # Ensure it behaves like a toggle
		tab_portion.toggled.connect(_on_portion_tab_toggled)
	
	# 3. Connect Button Signals
	# We connect all children of both grids. 
	# We use bind() to pass the button's index.
	var index = 0
	for btn in grid_2x2.get_children():
		if btn is BaseButton:
			btn.toggle_mode = true
			btn.pressed.connect(_on_food_button_pressed.bind(btn, index))
			index += 1
			
	index = 0
	for btn in grid_3x3.get_children():
		if btn is BaseButton:
			btn.toggle_mode = true
			btn.pressed.connect(_on_food_button_pressed.bind(btn, index))
			index += 1

	# 4. Initialize
	_switch_category("Go")

func _switch_category(category: String):
	current_category = category
	current_food_index = -1 # Reset selection
	
	# Reset food button highlights
	_deselect_all_buttons()
	
	# Reset Tab highlights
	tab_go.modulate = Color.WHITE
	tab_grow.modulate = Color.WHITE
	tab_glow.modulate = Color.WHITE
	
	# Reset Portion Tab
	if tab_portion:
		tab_portion.button_pressed = false # Reset toggle state
		# Note: Setting button_pressed = false triggers the toggled signal with false,
		# which handles the color reset via _on_portion_tab_toggled.
	
	# --- 1. SETUP UI BASED ON CATEGORY ---
	if category == "Go":
		tab_go.modulate = Color(1.5, 1.5, 1.5) # Highlight selected tab
		
		category_sign.texture = sign_go_texture
		right_info.texture = go_default_info
		
		grid_2x2.visible = true
		grid_3x3.visible = false
		active_buttons = grid_2x2.get_children()
		
		_apply_button_textures(active_buttons, go_btn_icons)

	elif category == "Grow":
		tab_grow.modulate = Color(1.5, 1.5, 1.5) # Highlight selected tab
		
		category_sign.texture = sign_grow_texture
		right_info.texture = grow_default_info
		
		grid_2x2.visible = true
		grid_3x3.visible = false
		active_buttons = grid_2x2.get_children()
		
		_apply_button_textures(active_buttons, grow_btn_icons)

	elif category == "Glow":
		tab_glow.modulate = Color(1.5, 1.5, 1.5) # Highlight selected tab
		
		category_sign.texture = sign_glow_texture
		right_info.texture = glow_default_info
		
		grid_2x2.visible = false
		grid_3x3.visible = true
		active_buttons = grid_3x3.get_children()
		
		_apply_button_textures(active_buttons, glow_btn_icons)

func _apply_button_textures(buttons: Array, textures: Array):
	for i in range(buttons.size()):
		var btn = buttons[i]
		if i < textures.size():
			btn.texture_normal = textures[i]
			btn.visible = true
		else:
			# Hide button if we don't have a texture for it
			btn.visible = false

func _on_food_button_pressed(pressed_btn: BaseButton, index: int):
	# Radio Button Logic: Deselect others
	for btn in active_buttons:
		if btn != pressed_btn:
			btn.button_pressed = false
			btn.modulate = Color.WHITE
	
	# visual feedback for selected
	pressed_btn.button_pressed = true
	pressed_btn.modulate = Color(1.5, 1.5, 1.5) # Glow effect
	
	# Update Right Info Page
	current_food_index = index
	_update_info_page()

func _on_portion_tab_toggled(toggled_on: bool):
	# Highlight logic for the Portion Tab
	if toggled_on:
		tab_portion.modulate = Color(1.5, 1.5, 1.5)
	else:
		tab_portion.modulate = Color.WHITE

	# Refresh the info page to show either the standard info or portion info
	_update_info_page()

func _update_info_page():
	var index = current_food_index
	
	# If no food is selected, ensure we stick to default category info 
	# (or you could choose to disable the portion tab here)
	if index == -1:
		match current_category:
			"Go": right_info.texture = go_default_info
			"Grow": right_info.texture = grow_default_info
			"Glow": right_info.texture = glow_default_info
		return

	var standard_list = []
	var portion_list = []
	
	match current_category:
		"Go": 
			standard_list = go_info_pages
			portion_list = go_portion_pages
		"Grow": 
			standard_list = grow_info_pages
			portion_list = grow_portion_pages
		"Glow": 
			standard_list = glow_info_pages
			portion_list = glow_portion_pages
	
	# Determine which list to use based on Portion Tab state
	var target_list = standard_list
	if tab_portion and tab_portion.button_pressed:
		target_list = portion_list
	
	# Apply texture
	if index >= 0 and index < target_list.size():
		right_info.texture = target_list[index]
	else:
		print("Warning: No info texture found for index ", index)

func _deselect_all_buttons():
	for btn in grid_2x2.get_children():
		btn.button_pressed = false
		btn.modulate = Color.WHITE
	for btn in grid_3x3.get_children():
		btn.button_pressed = false
		btn.modulate = Color.WHITE
