extends Control

signal closed

# --- SETTINGS ---
const PRICE_ACT2 = 15
const PRICE_ACT3 = 30

# --- SLIDE DATA (Assign in Inspector) ---
@export_group("Leo's Acts")
@export var leo_act1: Array[Texture2D]
@export var leo_act2: Array[Texture2D]
@export var leo_act3: Array[Texture2D]

@export_group("Maya's Acts")
@export var maya_act1: Array[Texture2D]
@export var maya_act2: Array[Texture2D]
@export var maya_act3: Array[Texture2D]

@export_group("Norma's Acts")
@export var norma_act1: Array[Texture2D]
@export var norma_act2: Array[Texture2D]
@export var norma_act3: Array[Texture2D]

# --- DYNAMIC PORTRAITS (Assign in Inspector) ---
@export_group("Character Portraits (Dynamic)")
@export var leo_dim: Texture2D
@export var leo_better: Texture2D
@export var leo_glowing: Texture2D

@export var maya_dim: Texture2D
@export var maya_better: Texture2D
@export var maya_glowing: Texture2D

@export var norma_dim: Texture2D
@export var norma_better: Texture2D
@export var norma_glowing: Texture2D

# --- PROGRESS UI SIGNS (Assign in Inspector) ---
@export_group("Progress UI")
@export var progress_act1_tex: Texture2D
@export var progress_act2_tex: Texture2D
@export var progress_act3_tex: Texture2D

# Tracking purchased acts (CharacterName -> Array of bought acts)
var purchased_acts = {
	"Leo": ["Act1"],
	"Maya": ["Act1"],
	"Norma": ["Act1"]
}

var current_character_name = ""
var current_act_slides: Array[Texture2D] = []
var current_slide_index: int = 0
var is_slide_transitioning: bool = false
var is_transitioning: bool = false # NEW: Global transition lock prevents UI spam overlaps

# --- NODES ---
@onready var layout1 = $Layout1
@onready var layout2 = $Layout2
@onready var layout3 = $Layout3
@onready var back_button = $UI/BackButtonImage/TopLeftButton/BackButton
@onready var key_amount_label = $UI/KeysUI/TopRightKeys/KeyImage/KeyAmount

# Audio Nodes
@onready var success_sfx = get_node_or_null("SuccessSFX")
@onready var fail_sfx = get_node_or_null("FailedSFX")

# Layout 1 - Portraits
@onready var leo_pic = $Layout1/CharacterCards/LeoCard/LeoPicture
@onready var maya_pic = $Layout1/CharacterCards/MayaCard/MayaPicture
@onready var norma_pic = $Layout1/CharacterCards/NormaCard/NormaPicture

# Layout 1 - Progress Buttons
@onready var leo_progress = $Layout1/CharacterCards/LeoCard/ProgressButton
@onready var maya_progress = $Layout1/CharacterCards/MayaCard/ProgressButton
@onready var norma_progress = $Layout1/CharacterCards/NormaCard/ProgressButton

# Layout 2
@onready var character_picture_l2 = $Layout2/SelectedCharacter/CharacterPicture
@onready var act1_btn = $Layout2/Parts/Part1
@onready var act2_btn = $Layout2/Parts/Part2
@onready var act3_btn = $Layout2/Parts/Part3

# Key Price Labels (Layout 2)
@onready var act2_price_label = $Layout2/Parts/Part2/KeyPrice
@onready var act3_price_label = $Layout2/Parts/Part3/KeyPrice

# Layout 3
@onready var character_picture_l3 = $Layout3/SelectedCharacter/CharacterPicture
@onready var lore_paper = $Layout3/BackstoryCharacter/LorePaper
@onready var lore_part = $Layout3/BackstoryCharacter/LorePaper/LorePart
@onready var next_button = $Layout3/BackstoryCharacter/LorePaper/NextButton
@onready var prev_button = $Layout3/BackstoryCharacter/LorePaper/PrevButton

# --- TEXTURES ---
var tex_act1_unlocked = preload("res://Assets/UI/GlowBoard/UnlockedPart1.png")

var tex_act2_available = preload("res://Assets/UI/GlowBoard/AvailableButtonPart2.png")
var tex_act2_bought = preload("res://Assets/UI/GlowBoard/UnlockedPart2.png")

var tex_act3_locked = preload("res://Assets/UI/GlowBoard/LockedPart3.png") 
var tex_act3_available = preload("res://Assets/UI/GlowBoard/AvailableButtonPart3.png")
var tex_act3_bought = preload("res://Assets/UI/GlowBoard/UnlockedPart3.png")

func _ready():
	# ⭐ LOAD SAVED PURCHASES SAFELY
	var gd = get_node_or_null("/root/GameData")
	if gd:
		for char_name in ["Leo", "Maya", "Norma"]:
			if gd.purchased_upgrades.has(char_name):
				var saved_data = gd.purchased_upgrades[char_name]
				if saved_data is Array:
					purchased_acts[char_name] = saved_data
				
	_setup_ui()
	update_key_display()

func update_key_display():
	if key_amount_label:
		var gd = get_node_or_null("/root/GameData")
		if gd: key_amount_label.text = str(gd.keys)

func _setup_ui():
	layout1.visible = true
	layout1.modulate.a = 1.0
	layout2.visible = false
	layout3.visible = false
	
	# Pre-update the L1 portraits in case acts were already bought
	var saved_name = current_character_name
	
	current_character_name = "Leo"
	if _get_current_character_portrait(): leo_pic.texture_normal = _get_current_character_portrait()
	
	current_character_name = "Maya"
	if _get_current_character_portrait(): maya_pic.texture_normal = _get_current_character_portrait()
	
	current_character_name = "Norma"
	if _get_current_character_portrait(): norma_pic.texture_normal = _get_current_character_portrait()
	
	current_character_name = saved_name
	
	# Update Progress Buttons for L1
	_update_all_progress_buttons()
	
	leo_pic.pressed.connect(func(): _on_character_selected("Leo", leo_pic))
	maya_pic.pressed.connect(func(): _on_character_selected("Maya", maya_pic))
	norma_pic.pressed.connect(func(): _on_character_selected("Norma", norma_pic))
	
	act1_btn.pressed.connect(func(): _handle_act_interaction("Act1", act1_btn))
	act2_btn.pressed.connect(func(): _handle_act_interaction("Act2", act2_btn))
	act3_btn.pressed.connect(func(): _handle_act_interaction("Act3", act3_btn))
	
	if next_button: next_button.pressed.connect(_on_next_button_pressed)
	if prev_button: prev_button.pressed.connect(_on_prev_button_pressed)
	
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

# --- PROGRESS BUTTON LOGIC ---
func _update_all_progress_buttons():
	_apply_progress_texture("Leo", leo_progress)
	_apply_progress_texture("Maya", maya_progress)
	_apply_progress_texture("Norma", norma_progress)

func _apply_progress_texture(char_name: String, btn: TextureButton):
	if not is_instance_valid(btn): return
	
	var acts = purchased_acts[char_name]
	if acts.has("Act3") and progress_act3_tex:
		btn.texture_normal = progress_act3_tex
	elif acts.has("Act2") and progress_act2_tex:
		btn.texture_normal = progress_act2_tex
	elif progress_act1_tex:
		btn.texture_normal = progress_act1_tex

# --- PORTRAIT LOGIC ---
func _get_current_character_portrait() -> Texture2D:
	if not purchased_acts.has(current_character_name): return null
	
	var acts = purchased_acts[current_character_name]
	var level = 1
	if acts.has("Act3"): level = 3
	elif acts.has("Act2"): level = 2
	
	match current_character_name:
		"Leo":
			if level == 3: return leo_glowing
			elif level == 2: return leo_better
			else: return leo_dim
		"Maya":
			if level == 3: return maya_glowing
			elif level == 2: return maya_better
			else: return maya_dim
		"Norma":
			if level == 3: return norma_glowing
			elif level == 2: return norma_better
			else: return norma_dim
			
	return null

# ⭐ RE-ADDED: WHITE SHEEN / CARD POP ANIMATION
func _celebrate_card(node: Control):
	if not is_instance_valid(node): return
	if node.has_meta("is_celebrating") and node.get_meta("is_celebrating"): return
	node.set_meta("is_celebrating", true)

	node.pivot_offset = node.size / 2

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	node.scale = Vector2(0.6, 0.6)
	tween.tween_property(node, "scale", Vector2.ONE, 0.8)

	node.modulate = Color(3.5, 3.5, 3.5, 1.0) 
	tween.tween_property(node, "modulate", Color.WHITE, 0.6) # FIX: Enforced target color

	var shake_tween = create_tween()
	shake_tween.tween_property(node, "rotation_degrees", 4.0, 0.05)
	shake_tween.tween_property(node, "rotation_degrees", -4.0, 0.1)
	shake_tween.tween_property(node, "rotation_degrees", 0.0, 0.05)
	
	tween.chain().tween_callback(func(): node.set_meta("is_celebrating", false))

# --- PURCHASE LOGIC ---
func _handle_act_interaction(act_key: String, btn: TextureButton):
	if is_transitioning: return
	
	if purchased_acts[current_character_name].has(act_key):
		_on_act_selected(btn, act_key)
		return

	if act_key == "Act3" and not purchased_acts[current_character_name].has("Act2"):
		_purchase_failed(btn) 
		return

	var price = PRICE_ACT2 if act_key == "Act2" else PRICE_ACT3
	var gd = get_node_or_null("/root/GameData")
	
	if gd and gd.keys >= price:
		_purchase_success(act_key, btn, price)
	else:
		_purchase_failed(btn)

func _purchase_success(act_key: String, btn: TextureButton, price: int):
	var gd = get_node_or_null("/root/GameData")
	if not gd: return
	
	gd.keys -= price
	purchased_acts[current_character_name].append(act_key)

	gd.purchased_upgrades[current_character_name] = purchased_acts[current_character_name]

	update_key_display()
	_sync_character_progress()
	if gd.has_method("save_game"): gd.save_game()

	get_tree().call_group("HUD", "update_all_labels")

	var updated_portrait = _get_current_character_portrait()
	if updated_portrait:
		character_picture_l2.texture_normal = updated_portrait
		character_picture_l3.texture_normal = updated_portrait
		
		match current_character_name:
			"Leo": leo_pic.texture_normal = updated_portrait
			"Maya": maya_pic.texture_normal = updated_portrait
			"Norma": norma_pic.texture_normal = updated_portrait

	_update_all_progress_buttons()

	_celebrate_card(btn) 
	_celebrate_card(character_picture_l2) 
	
	match current_character_name:
		"Leo": _celebrate_card(leo_pic)
		"Maya": _celebrate_card(maya_pic)
		"Norma": _celebrate_card(norma_pic)

	if success_sfx:
		success_sfx.play()

	_refresh_act_textures()

	# ⚠️ SAFETY GUARD: Check that they haven't pressed "back" before opening
	var cached_layout = layout2
	await get_tree().create_timer(0.6).timeout
	if is_inside_tree() and is_instance_valid(btn) and cached_layout.visible:
		is_transitioning = false # Bypass lock for auto-open
		_on_act_selected(btn, act_key)

func _purchase_failed(btn: TextureButton):
	if not is_instance_valid(btn): return
	if btn.has_meta("is_shaking") and btn.get_meta("is_shaking"): return
	btn.set_meta("is_shaking", true)
	
	if fail_sfx: fail_sfx.play()
	
	btn.pivot_offset = btn.size / 2
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var color_tween = create_tween()
	btn.modulate = Color(1.5, 0.2, 0.2, 1.0) 
	color_tween.tween_property(btn, "modulate", Color.WHITE, 0.4)
	
	tween.tween_property(btn, "rotation_degrees", 8.0, 0.05)
	tween.tween_property(btn, "rotation_degrees", -8.0, 0.05)
	tween.tween_property(btn, "rotation_degrees", 6.0, 0.05)
	tween.tween_property(btn, "rotation_degrees", -6.0, 0.05)
	tween.tween_property(btn, "rotation_degrees", 0.0, 0.05)
	
	tween.chain().tween_callback(func(): btn.set_meta("is_shaking", false))

# --- TRANSITION: L1 -> L2 ---
func _on_character_selected(char_name: String, source_button: TextureButton):
	if is_transitioning: return
	is_transitioning = true
	
	current_character_name = char_name
	
	var target_portrait = _get_current_character_portrait()
	if target_portrait:
		source_button.texture_normal = target_portrait
		
	character_picture_l2.texture_normal = source_button.texture_normal
	_refresh_act_textures()
	
	var ghost = _create_ghost(source_button)
	layout2.modulate.a = 0.0
	layout2.visible = true
	
	# GPU CRASH PREVENTION: Safely fallback positions
	var target_size = character_picture_l2.size
	if target_size.x <= 1 or target_size.y <= 1: target_size = Vector2(250, 400)
	var target_pos = character_picture_l2.global_position
	if target_pos == Vector2.ZERO: target_pos = Vector2(200, 150)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(layout1, "modulate:a", 0.0, 0.4)
	tween.tween_property(ghost, "global_position", target_pos, 0.6)
	tween.tween_property(ghost, "size", target_size, 0.6)
	
	tween.chain().tween_callback(func():
		layout2.modulate.a = 1.0
		ghost.queue_free()
		layout1.visible = false
		is_transitioning = false
	)

func _refresh_act_textures():
	act1_btn.texture_normal = tex_act1_unlocked
	
	if purchased_acts[current_character_name].has("Act2"):
		act2_btn.texture_normal = tex_act2_bought
		act2_price_label.visible = false
	else:
		act2_btn.texture_normal = tex_act2_available
		act2_price_label.visible = true
		
	if purchased_acts[current_character_name].has("Act3"):
		act3_btn.texture_normal = tex_act3_bought
		act3_price_label.visible = false
	elif purchased_acts[current_character_name].has("Act2"):
		act3_btn.texture_normal = tex_act3_available
		act3_price_label.visible = true
	else:
		act3_btn.texture_normal = tex_act3_locked
		act3_price_label.visible = false

# --- TRANSITION: L2 -> L3 & SLIDE LOGIC ---
func _get_act_array(char_name: String, act_key: String) -> Array[Texture2D]:
	match char_name:
		"Leo":
			if act_key == "Act1": return leo_act1
			elif act_key == "Act2": return leo_act2
			elif act_key == "Act3": return leo_act3
		"Maya":
			if act_key == "Act1": return maya_act1
			elif act_key == "Act2": return maya_act2
			elif act_key == "Act3": return maya_act3
		"Norma":
			if act_key == "Act1": return norma_act1
			elif act_key == "Act2": return norma_act2
			elif act_key == "Act3": return norma_act3
	return []

func _on_act_selected(clicked_btn: TextureButton, act_key: String):
	if is_transitioning: return
	is_transitioning = true
	
	character_picture_l3.texture_normal = character_picture_l2.texture_normal
	
	current_act_slides = _get_act_array(current_character_name, act_key)
	current_slide_index = 0
	_update_slide_display(false) 
	
	layout3.visible = true
	layout3.modulate.a = 0.0
	
	var ghost_char = _create_ghost(character_picture_l2)
	
	var original_lore_pos = lore_paper.global_position
	if original_lore_pos == Vector2.ZERO: original_lore_pos = Vector2(640, 360) # Fallback center
	
	lore_paper.pivot_offset = lore_paper.size / 2
	lore_paper.scale = Vector2(0.1, 0.1)
	lore_paper.global_position = clicked_btn.global_position
	
	# GPU CRASH PREVENTION: Safely fallback positions
	var target_size = character_picture_l3.size
	if target_size.x <= 1 or target_size.y <= 1: target_size = Vector2(250, 400)
	var target_pos = character_picture_l3.global_position
	if target_pos == Vector2.ZERO: target_pos = Vector2(150, 150)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(layout2, "modulate:a", 0.0, 0.3)
	tween.tween_property(layout3, "modulate:a", 1.0, 0.4)
	tween.tween_property(ghost_char, "global_position", target_pos, 0.5)
	tween.tween_property(ghost_char, "size", target_size, 0.5)
	tween.tween_property(lore_paper, "scale", Vector2(1, 1), 0.6)
	tween.tween_property(lore_paper, "global_position", original_lore_pos, 0.6)
	
	tween.chain().tween_callback(func():
		ghost_char.queue_free()
		layout2.visible = false
		is_transitioning = false
	)

func _update_slide_display(animate: bool = true):
	if animate:
		is_slide_transitioning = true
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(lore_part, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func():
			_set_slide_texture_and_buttons()
		)
		tween.tween_property(lore_part, "modulate:a", 1.0, 0.15)
		tween.tween_callback(func():
			is_slide_transitioning = false
		)
	else:
		lore_part.modulate.a = 1.0
		_set_slide_texture_and_buttons()

func _set_slide_texture_and_buttons():
	if current_act_slides.size() > 0 and current_slide_index < current_act_slides.size():
		lore_part.texture = current_act_slides[current_slide_index]
	else:
		lore_part.texture = null
		
	if next_button:
		next_button.visible = (current_slide_index < current_act_slides.size() - 1)
			
	if prev_button:
		prev_button.visible = (current_slide_index > 0)

func _on_next_button_pressed():
	if is_slide_transitioning: return
	if current_slide_index < current_act_slides.size() - 1:
		current_slide_index += 1
		_update_slide_display(true)

func _on_prev_button_pressed():
	if is_slide_transitioning: return
	if current_slide_index > 0:
		current_slide_index -= 1
		_update_slide_display(true)

# --- HELPERS & BACK BUTTON ---

func _create_ghost(source: TextureButton) -> TextureRect:
	var ghost = TextureRect.new()
	ghost.texture = source.texture_normal
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# ⭐ CRITICAL FIX: NEVER allow 0 size (This caused the GPU Driver Crash)
	var safe_size = source.size
	if safe_size.x <= 1: safe_size.x = 150
	if safe_size.y <= 1: safe_size.y = 150
	
	ghost.size = safe_size
	ghost.global_position = source.global_position
	add_child(ghost)
	return ghost

func _on_back_button_pressed():
	if is_transitioning: return
	
	if layout3.visible:
		_fade_transition(layout3, layout2)
	elif layout2.visible:
		_fade_transition(layout2, layout1)
	else:
		closed.emit()

func _fade_transition(from: Control, to: Control):
	is_transitioning = true
	to.visible = true
	if from == layout3:
		lore_paper.scale = Vector2(1, 1)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(from, "modulate:a", 0.0, 0.3)
	tween.tween_property(to, "modulate:a", 1.0, 0.3)
	tween.chain().tween_callback(func(): 
		from.visible = false
		is_transitioning = false
	)
	
func _sync_character_progress():
	var gd = get_node_or_null("/root/GameData")
	if not gd: return
	
	for char_name in purchased_acts.keys():
		var parts = purchased_acts[char_name]
		var stage := 1

		if parts.has("Act3"):
			stage = 3
		elif parts.has("Act2"):
			stage = 2
		else:
			stage = 1

		# ⭐ REAL visual stage (NO VALUES)
		gd.character_stage[char_name] = stage
