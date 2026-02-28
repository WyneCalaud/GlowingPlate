extends Control
signal closed

var is_updating: bool = false # Guard against recursive layout loops

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
@export var go_default_info: Texture2D 
@export var go_btn_icons: Array[Texture2D] 
@export var go_info_pages: Array[Texture2D] 
@export var go_portion_pages: Array[Texture2D] 

@export_group("Grow Data")
@export var grow_default_info: Texture2D
@export var grow_btn_icons: Array[Texture2D]
@export var grow_info_pages: Array[Texture2D]
@export var grow_portion_pages: Array[Texture2D] 

@export_group("Glow Data")
@export var glow_default_info: Texture2D
@export var glow_btn_icons: Array[Texture2D]
@export var glow_info_pages: Array[Texture2D]
@export var glow_portion_pages: Array[Texture2D] 

# --- STATE ---
var current_category: String = "Go"
var active_buttons: Array = []
var current_food_index: int = -1 

func _ready():
	# 1. Setup Category Tabs
	tab_go.pressed.connect(func(): _switch_category("Go"))
	tab_grow.pressed.connect(func(): _switch_category("Grow"))
	tab_glow.pressed.connect(func(): _switch_category("Glow"))
	
	# 2. Setup Portion Tab
	if tab_portion:
		tab_portion.toggle_mode = true 
		tab_portion.toggled.connect(_on_portion_tab_toggled)
	
	# 3. Connect Button Signals safely
	var index = 0
	if grid_2x2:
		for btn in grid_2x2.get_children():
			if btn is BaseButton:
				btn.toggle_mode = true
				btn.pressed.connect(_on_food_button_pressed.bind(btn, index))
				index += 1
			
	index = 0
	if grid_3x3:
		for btn in grid_3x3.get_children():
			if btn is BaseButton:
				btn.toggle_mode = true
				btn.pressed.connect(_on_food_button_pressed.bind(btn, index))
				index += 1

	# 4. Initialize
	call_deferred("_switch_category", "Go")

func _switch_category(category: String):
	if is_updating: return
	is_updating = true
	
	current_category = category
	current_food_index = -1 
	
	_deselect_all_buttons()
	
	# Reset Tab highlights
	tab_go.modulate = Color.WHITE
	tab_grow.modulate = Color.WHITE
	tab_glow.modulate = Color.WHITE
	
	# Reset Portion Tab without emitting a signal
	if tab_portion:
		tab_portion.set_pressed_no_signal(false) 
		tab_portion.modulate = Color.WHITE
	
	# --- 1. SETUP UI BASED ON CATEGORY ---
	# We use set_deferred for visibility to prevent UI layout loops that crash the GPU
	if category == "Go":
		tab_go.modulate = Color(1.5, 1.5, 1.5) 
		category_sign.set_deferred("texture", sign_go_texture)
		right_info.set_deferred("texture", go_default_info)
		
		grid_3x3.set_deferred("visible", false)
		grid_2x2.set_deferred("visible", true)
		active_buttons = grid_2x2.get_children()
		_apply_button_textures(active_buttons, go_btn_icons)

	elif category == "Grow":
		tab_grow.modulate = Color(1.5, 1.5, 1.5) 
		category_sign.set_deferred("texture", sign_grow_texture)
		right_info.set_deferred("texture", grow_default_info)
		
		grid_3x3.set_deferred("visible", false)
		grid_2x2.set_deferred("visible", true)
		active_buttons = grid_2x2.get_children()
		_apply_button_textures(active_buttons, grow_btn_icons)

	elif category == "Glow":
		tab_glow.modulate = Color(1.5, 1.5, 1.5) 
		category_sign.set_deferred("texture", sign_glow_texture)
		right_info.set_deferred("texture", glow_default_info)
		
		grid_2x2.set_deferred("visible", false)
		grid_3x3.set_deferred("visible", true)
		active_buttons = grid_3x3.get_children()
		_apply_button_textures(active_buttons, glow_btn_icons)
		
	is_updating = false

func _apply_button_textures(buttons: Array, textures: Array):
	var tex_index = 0
	for btn in buttons:
		if btn is BaseButton:
			if tex_index < textures.size():
				btn.texture_normal = textures[tex_index]
				btn.set_deferred("visible", true)
			else:
				btn.set_deferred("visible", false)
			tex_index += 1

func _on_food_button_pressed(pressed_btn: BaseButton, index: int):
	# NEW LOGIC: Untoggle portion tab when switching food
	if tab_portion and tab_portion.button_pressed:
		tab_portion.set_pressed_no_signal(false)
		tab_portion.modulate = Color.WHITE

	# Radio Button Logic
	for btn in active_buttons:
		if btn is BaseButton and btn != pressed_btn:
			btn.set_pressed_no_signal(false)
			btn.modulate = Color.WHITE
	
	pressed_btn.set_pressed_no_signal(true)
	pressed_btn.modulate = Color(1.5, 1.5, 1.5) 
	
	current_food_index = index
	call_deferred("_update_info_page") # Call deferred to prevent layout freeze

func _on_portion_tab_toggled(toggled_on: bool):
	if toggled_on:
		tab_portion.modulate = Color(1.5, 1.5, 1.5)
		
		# --- NEW: Auto-select the first food item if none is selected ---
		if current_food_index == -1 and active_buttons.size() > 0:
			current_food_index = 0
			var first_btn = active_buttons[0] as BaseButton
			if first_btn:
				# Manually set the pressed state to bypass _on_food_button_pressed
				first_btn.set_pressed_no_signal(true)
				first_btn.modulate = Color(1.5, 1.5, 1.5)
	else:
		tab_portion.modulate = Color.WHITE

	call_deferred("_update_info_page")

func _update_info_page():
	var index = current_food_index
	
	if index == -1:
		match current_category:
			"Go": right_info.set_deferred("texture", go_default_info)
			"Grow": right_info.set_deferred("texture", grow_default_info)
			"Glow": right_info.set_deferred("texture", glow_default_info)
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
	
	var target_list = standard_list
	if tab_portion and tab_portion.button_pressed:
		target_list = portion_list
	
	if index >= 0 and index < target_list.size():
		# Using set_deferred here is crucial to preventing the texture loop freeze
		right_info.set_deferred("texture", target_list[index])
	else:
		print("Warning: No info texture found for index ", index)

func _deselect_all_buttons():
	if grid_2x2:
		for btn in grid_2x2.get_children():
			if btn is BaseButton:
				btn.set_pressed_no_signal(false)
				btn.modulate = Color.WHITE
	if grid_3x3:
		for btn in grid_3x3.get_children():
			if btn is BaseButton:
				btn.set_pressed_no_signal(false)
				btn.modulate = Color.WHITE
