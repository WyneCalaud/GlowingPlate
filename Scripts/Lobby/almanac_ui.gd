extends Control
signal closed

var is_updating: bool = false # Guard against recursive layout loops

# --- NEW: CURRENT PLAYER DAY (SET THIS WHEN OPENING ALMANAC) ---
# Example: If player has finished Day 3, set this to 3 before showing the UI.
@export var player_completed_day: int = 1 

func _on_texture_button_pressed() -> void:
	# =========================================================
	# ---> TUTORIAL HOOK: Notify Interactive.gd when Almanac is closed
	# =========================================================
	var in_tutorial = get_tree().get_nodes_in_group("InteractiveTutorial").size() > 0
	
	if in_tutorial:
		get_tree().call_group("InteractiveTutorial", "action_completed", "Almanac_Close")
		hide() # Just hide the UI! Do NOT emit 'closed', which prevents the scene from changing to the Lobby.
	else:
		closed.emit() # Normal game behavior: Emit signal to let the parent script handle it.
	# =========================================================

# --- SCENE REFERENCES ---
@onready var exit_button: TextureButton = $Almanac/Exitbutton
@onready var category_sign: TextureRect = $Almanac/LeftPage/CategorySign
@onready var right_info: TextureRect = $Almanac/RightPage/RighSideInfo

# Tabs
@onready var tab_go: TextureButton = $Almanac/GoTab
@onready var tab_grow: TextureButton = $Almanac/GrowTab
@onready var tab_glow: TextureButton = $Almanac/GlowTab
@onready var tab_portion: BaseButton = $Almanac/PortionTab
@onready var left_portion: BaseButton = $Almanac/PortionTab/LeftButton
@onready var right_portion: BaseButton = $Almanac/PortionTab/RightButton

# Grids
@onready var grid_2x2: GridContainer = $"Almanac/LeftPage/2x2"
@onready var grid_3x3: GridContainer = $"Almanac/LeftPage/3x3"

# --- CONFIGURATION (Assign in Inspector) ---

@export_group("Signs")
@export var sign_go_texture: Texture2D
@export var sign_grow_texture: Texture2D
@export var sign_glow_texture: Texture2D

@export_group("Go Data")
@export var go_food_keys: Array[String] # Must match OrderSystem keys (e.g. "RICE", "PANDESAL")
@export var go_default_info: Texture2D 
@export var go_btn_icons: Array[Texture2D] 
@export var go_info_pages: Array[Texture2D] 
@export var go_portion_pages: Array[Texture2D] 

@export_group("Grow Data")
@export var grow_food_keys: Array[String] # Must match OrderSystem keys
@export var grow_default_info: Texture2D
@export var grow_btn_icons: Array[Texture2D]
@export var grow_info_pages: Array[Texture2D]
@export var grow_portion_pages: Array[Texture2D] 

@export_group("Glow Data")
@export var glow_food_keys: Array[String] # Must match OrderSystem keys
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
		
	# 3. Setup Left and Right Portion Buttons
	if left_portion and right_portion:
		left_portion.hide()
		right_portion.hide()
		left_portion.pressed.connect(_on_left_portion_pressed)
		right_portion.pressed.connect(_on_right_portion_pressed)
	
	# 4. Connect Button Signals safely
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

	# 5. Initialize
	call_deferred("_switch_category", "Go")


# --- CATEGORY LOGIC ---
func _switch_category(category: String, keep_portion_tab: bool = false):
	if is_updating: return
	is_updating = true
	
	current_category = category
	current_food_index = -1 
	
	_deselect_all_buttons()
	
	# Reset Tab highlights using self_modulate so it doesn't affect children
	tab_go.self_modulate = Color.WHITE
	tab_grow.self_modulate = Color.WHITE
	tab_glow.self_modulate = Color.WHITE
	
	# Reset Portion Tab ONLY if we are clicking a main tab (not using arrows)
	if tab_portion and not keep_portion_tab:
		tab_portion.set_pressed_no_signal(false) 
		tab_portion.self_modulate = Color.WHITE # Changed to self_modulate
		left_portion.hide()
		right_portion.hide()
	
	var GD = get_node("/root/GameData")
	var unlocked_foods = OrderSystem.get_unlocked_foods(GD.current_day - 1)
	
	# =========================================================
	# ---> NEW: TUTORIAL OVERRIDE <---
	# If the tutorial is active, forcefully add the required items to the unlocked list!
	# Make sure these strings match your OrderSystem keys exactly.
	# =========================================================
	if get_tree().get_nodes_in_group("InteractiveTutorial").size() > 0:
		var tutorial_foods = ["RICE", "CHICKEN", "SITAW", "MANGO"]
		for t_food in tutorial_foods:
			if not unlocked_foods.has(t_food):
				unlocked_foods.append(t_food)
	# =========================================================
	
	# --- 1. SETUP UI BASED ON CATEGORY ---
	if category == "Go":
		tab_go.self_modulate = Color(1.5, 1.5, 1.5) # Changed to self_modulate
		category_sign.set_deferred("texture", sign_go_texture)
		right_info.set_deferred("texture", go_default_info)
		
		grid_3x3.set_deferred("visible", false)
		grid_2x2.set_deferred("visible", true)
		active_buttons = grid_2x2.get_children()
		_apply_button_textures(active_buttons, go_btn_icons, go_food_keys, unlocked_foods)

	elif category == "Grow":
		tab_grow.self_modulate = Color(1.5, 1.5, 1.5) # Changed to self_modulate
		category_sign.set_deferred("texture", sign_grow_texture)
		right_info.set_deferred("texture", grow_default_info)
		
		grid_3x3.set_deferred("visible", false)
		grid_2x2.set_deferred("visible", true)
		active_buttons = grid_2x2.get_children()
		_apply_button_textures(active_buttons, grow_btn_icons, grow_food_keys, unlocked_foods)

	elif category == "Glow":
		tab_glow.self_modulate = Color(1.5, 1.5, 1.5) # Changed to self_modulate
		category_sign.set_deferred("texture", sign_glow_texture)
		right_info.set_deferred("texture", glow_default_info)
		
		grid_2x2.set_deferred("visible", false)
		grid_3x3.set_deferred("visible", true)
		active_buttons = grid_3x3.get_children()
		_apply_button_textures(active_buttons, glow_btn_icons, glow_food_keys, unlocked_foods)

	# If we switched via the arrows, keep the portion UI active!
	if keep_portion_tab and tab_portion:
		left_portion.show()
		right_portion.show()
		
		left_portion.modulate = Color.WHITE
		right_portion.modulate = Color.WHITE
		
		# Auto-select the very first UNLOCKED food in this new category
		if active_buttons.size() > 0:
			for i in range(active_buttons.size()):
				var btn = active_buttons[i] as BaseButton
				if btn.get_meta("is_locked", true) == false:
					current_food_index = i
					btn.set_pressed_no_signal(true)
					btn.self_modulate = Color(1.5, 1.5, 1.5)
					break
		
		call_deferred("_update_info_page")
		
	is_updating = false


func _apply_button_textures(buttons: Array, textures: Array, category_keys: Array, unlocked_foods: Array):
	var tex_index = 0
	for btn in buttons:
		if btn is BaseButton:
			if tex_index < textures.size():
				btn.texture_normal = textures[tex_index]
				btn.set_deferred("visible", true)
				
				# CHECK LOCK STATUS
				var food_key = category_keys[tex_index] if tex_index < category_keys.size() else ""
				
				if food_key != "" and unlocked_foods.has(food_key):
					btn.set_meta("is_locked", false)
					btn.self_modulate = Color.WHITE # Changed to self_modulate
				else:
					btn.set_meta("is_locked", true)
					btn.self_modulate = Color(0.2, 0.2, 0.2, 1.0) # Changed to self_modulate
			else:
				btn.set_deferred("visible", false)
			tex_index += 1


func _on_food_button_pressed(pressed_btn: BaseButton, index: int):
	# BLOCK CLICK IF LOCKED
	if pressed_btn.get_meta("is_locked", true) == true:
		_play_error_animation(pressed_btn)
		pressed_btn.set_pressed_no_signal(false) # Force untoggle immediately
		return

	# Untoggle portion tab when switching food manually
	if tab_portion and tab_portion.button_pressed:
		tab_portion.set_pressed_no_signal(false)
		tab_portion.self_modulate = Color.WHITE # Changed to self_modulate
		left_portion.hide() 
		right_portion.hide() 

	# Radio Button Logic
	for btn in active_buttons:
		if btn is BaseButton and btn != pressed_btn:
			btn.set_pressed_no_signal(false)
			btn.self_modulate = Color(0.2, 0.2, 0.2, 1.0) if btn.get_meta("is_locked", false) else Color.WHITE
	
	pressed_btn.set_pressed_no_signal(true)
	pressed_btn.self_modulate = Color(1.5, 1.5, 1.5) 
	
	current_food_index = index
	call_deferred("_update_info_page") 

	# =========================================================
	# ---> TUTORIAL HOOK: Notify Interactive.gd when a food is clicked
	# =========================================================
	var category_keys = []
	match current_category:
		"Go": category_keys = go_food_keys
		"Grow": category_keys = grow_food_keys
		"Glow": category_keys = glow_food_keys
		
	if index < category_keys.size():
		var food_key = category_keys[index]
		# Example output: "Almanac_Food_Clicked_RICE"
		get_tree().call_group("InteractiveTutorial", "action_completed", "Almanac_Food_Clicked_" + food_key)
	# =========================================================

# --- NEW ERROR ANIMATION ---
func _play_error_animation(btn: BaseButton):
	btn.pivot_offset = btn.size / 2.0
	
	var tween = create_tween()
	tween.tween_property(btn, "rotation_degrees", 15.0, 0.05)
	tween.tween_property(btn, "rotation_degrees", -15.0, 0.05)
	tween.tween_property(btn, "rotation_degrees", 10.0, 0.05)
	tween.tween_property(btn, "rotation_degrees", -10.0, 0.05)
	tween.tween_property(btn, "rotation_degrees", 0.0, 0.05)
	
	btn.self_modulate = Color(1, 0, 0)
	var color_tween = create_tween()
	color_tween.tween_property(btn, "self_modulate", Color(0.2, 0.2, 0.2, 1.0), 0.25)


# --- PORTION TAB LOGIC ---
func _on_portion_tab_toggled(toggled_on: bool):
	if toggled_on:
		
		# =========================================================
		# ---> TUTORIAL HOOK: Notify Interactive.gd when Portion Tab is toggled ON
		# =========================================================
		get_tree().call_group("InteractiveTutorial", "action_completed", "Portion_Pressed")
		# =========================================================
		
		tab_portion.self_modulate = Color(1.5, 1.5, 1.5) # Changed to self_modulate
		
		# Show navigation arrows
		left_portion.show()
		right_portion.show()
		
		# Explicitly make sure they are normal color
		left_portion.modulate = Color.WHITE
		right_portion.modulate = Color.WHITE
		
		# Auto-select the first food item if none is selected
		if current_food_index == -1 and active_buttons.size() > 0:
			for i in range(active_buttons.size()):
				var btn = active_buttons[i] as BaseButton
				if btn and btn.visible and btn.get_meta("is_locked", true) == false:
					current_food_index = i
					btn.set_pressed_no_signal(true)
					btn.self_modulate = Color(1.5, 1.5, 1.5)
					break
	else:
		tab_portion.self_modulate = Color.WHITE # Changed to self_modulate
		
		# Hide navigation arrows
		left_portion.hide()
		right_portion.hide()

	call_deferred("_update_info_page")


# --- NEW: LEFT AND RIGHT CYCLING TABS LOGIC ---

func _on_left_portion_pressed():
	_play_glow_animation(left_portion)
	_cycle_category(-1) # Move backwards in tabs

func _on_right_portion_pressed():
	_play_glow_animation(right_portion)
	_cycle_category(1) # Move forwards in tabs

func _play_glow_animation(btn: BaseButton):
	# Flash bright white/yellow, then fade back to normal color
	var tween = create_tween()
	tween.tween_property(btn, "modulate", Color(2.0, 2.0, 1.5, 1.0), 0.1)
	tween.tween_property(btn, "modulate", Color.WHITE, 0.15)

func _cycle_category(direction: int):
	# Defines the order of your tabs
	var categories = ["Go", "Grow", "Glow"]
	
	var current_idx = categories.find(current_category)
	if current_idx == -1: current_idx = 0
	
	# Safely cycles up and down the array (e.g. from Glow back to Go)
	var next_idx = (current_idx + direction + categories.size()) % categories.size()
	var next_category = categories[next_idx]
	
	# Call _switch_category but pass "true" so we stay locked in the Portion tab mode!
	_switch_category(next_category, true)


# --- INFO PAGE UPDATER ---
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
		right_info.set_deferred("texture", target_list[index])
	else:
		print("Warning: No info texture found for index ", index)

func _deselect_all_buttons():
	if grid_2x2:
		for btn in grid_2x2.get_children():
			if btn is BaseButton:
				btn.set_pressed_no_signal(false)
				btn.self_modulate = Color(0.2, 0.2, 0.2, 1.0) if btn.get_meta("is_locked", false) else Color.WHITE
	if grid_3x3:
		for btn in grid_3x3.get_children():
			if btn is BaseButton:
				btn.set_pressed_no_signal(false)
				btn.self_modulate = Color(0.2, 0.2, 0.2, 1.0) if btn.get_meta("is_locked", false) else Color.WHITE
