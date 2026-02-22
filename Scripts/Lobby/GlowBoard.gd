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

# Tracking purchased acts (CharacterName -> Array of bought acts)
var purchased_acts = {
	"Leo": ["Act1"],
	"Maya": ["Act1"],
	"Norma": ["Act1"]
}

var current_character_name = ""
var current_act_slides: Array[Texture2D] = []
var current_slide_index: int = 0
var is_slide_transitioning: bool = false # NEW: Prevents spam clicking during transitions

# --- NODES ---
@onready var layout1 = $Layout1
@onready var layout2 = $Layout2
@onready var layout3 = $Layout3
@onready var back_button = $UI/BackButtonImage/TopLeftButton/BackButton
@onready var key_amount_label = $UI/KeysUI/TopRightKeys/KeyImage/KeyAmount

# Audio Nodes
@onready var success_sfx = $SuccessSFX
@onready var fail_sfx = $FailedSFX

# Layout 1
@onready var leo_pic = $Layout1/CharacterCards/LeoCard/LeoPicture
@onready var maya_pic = $Layout1/CharacterCards/MayaCard/MayaPicture
@onready var norma_pic = $Layout1/CharacterCards/NormaCard/NormaPicture

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
	_setup_ui()
	update_key_display()

func update_key_display():
	if key_amount_label:
		key_amount_label.text = str(GameData.keys)

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
	
	leo_pic.pressed.connect(func(): _on_character_selected("Leo", leo_pic))
	maya_pic.pressed.connect(func(): _on_character_selected("Maya", maya_pic))
	norma_pic.pressed.connect(func(): _on_character_selected("Norma", norma_pic))
	
	act1_btn.pressed.connect(func(): _handle_act_interaction("Act1", act1_btn))
	act2_btn.pressed.connect(func(): _handle_act_interaction("Act2", act2_btn))
	act3_btn.pressed.connect(func(): _handle_act_interaction("Act3", act3_btn))
	
	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)
		
	if prev_button:
		prev_button.pressed.connect(_on_prev_button_pressed)
	
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

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

func _celebrate_portrait(node: Control):
	if not is_instance_valid(node): return

	# Center the pivot for a nice scale/rotation effect
	node.pivot_offset = node.size / 2

	# Combine pop and flash simultaneously
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Scale pop effect
	node.scale = Vector2(0.5, 0.5)
	tween.tween_property(node, "scale", Vector2.ONE, 0.8)

	# Bright white card sheen flash effect
	var orig_modulate = Color.WHITE
	node.modulate = Color(2.5, 2.5, 2.5) 
	tween.tween_property(node, "modulate", orig_modulate, 0.6)

	# Subtle rotation shake
	var shake_tween = create_tween()
	shake_tween.tween_property(node, "rotation_degrees", 5.0, 0.05)
	shake_tween.tween_property(node, "rotation_degrees", -5.0, 0.1)
	shake_tween.tween_property(node, "rotation_degrees", 0.0, 0.05)

# --- PURCHASE LOGIC ---
func _handle_act_interaction(act_key: String, btn: TextureButton):
	if purchased_acts[current_character_name].has(act_key):
		_on_act_selected(btn, act_key)
		return

	if act_key == "Act3" and not purchased_acts[current_character_name].has("Act2"):
		_purchase_failed(btn) 
		return

	var price = PRICE_ACT2 if act_key == "Act2" else PRICE_ACT3
	
	if GameData.keys >= price:
		_purchase_success(act_key, btn, price)
	else:
		_purchase_failed(btn)

func _purchase_success(act_key: String, btn: TextureButton, price: int):
	GameData.keys -= price
	purchased_acts[current_character_name].append(act_key)
	update_key_display()

	# ⭐ Update HUD display
	get_tree().call_group("HUD", "update_all_labels")

	
	# Update the character portrait immediately based on new purchased act
	var updated_portrait = _get_current_character_portrait()
	if updated_portrait:
		character_picture_l2.texture_normal = updated_portrait
		character_picture_l3.texture_normal = updated_portrait
		
		# Animate the target L2 picture
		_celebrate_portrait(character_picture_l2)
		
		# Assign to L1 and animate so it looks awesome when they go back
		match current_character_name:
			"Leo": 
				leo_pic.texture_normal = updated_portrait
				_celebrate_portrait(leo_pic)
			"Maya": 
				maya_pic.texture_normal = updated_portrait
				_celebrate_portrait(maya_pic)
			"Norma": 
				norma_pic.texture_normal = updated_portrait
				_celebrate_portrait(norma_pic)
	
	# Play Success Sound
	if success_sfx: success_sfx.play()
	
	var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# Bright white sheen on the button instead of green
	btn.modulate = Color(2.5, 2.5, 2.5)
	tween.tween_property(btn, "modulate", Color.WHITE, 0.5)
	
	_refresh_act_textures()
	
	await get_tree().create_timer(0.6).timeout
	_on_act_selected(btn, act_key)

func _purchase_failed(btn: TextureButton):
	# Play Failure Sound
	if fail_sfx: fail_sfx.play()
	
	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	btn.modulate = Color.RED
	var orig_pos = btn.position
	tween.tween_property(btn, "position", orig_pos + Vector2(10, 0), 0.05)
	tween.chain().tween_property(btn, "position", orig_pos - Vector2(10, 0), 0.05)
	tween.chain().tween_property(btn, "position", orig_pos, 0.05)
	tween.chain().tween_property(btn, "modulate", Color.WHITE, 0.3)

# --- TRANSITION: L1 -> L2 ---
func _on_character_selected(char_name: String, source_button: TextureButton):
	current_character_name = char_name
	
	# Fetch correct portrait and apply it to both the source (L1) and target (L2)
	var target_portrait = _get_current_character_portrait()
	if target_portrait:
		source_button.texture_normal = target_portrait
		
	character_picture_l2.texture_normal = source_button.texture_normal
	
	_refresh_act_textures()
	
	var ghost = _create_ghost(source_button)
	layout2.modulate.a = 0.0
	layout2.visible = true
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(layout1, "modulate:a", 0.0, 0.4)
	tween.tween_property(ghost, "global_position", character_picture_l2.global_position, 0.6)
	tween.tween_property(ghost, "size", character_picture_l2.size, 0.6)
	
	tween.chain().tween_callback(func():
		layout2.modulate.a = 1.0
		ghost.queue_free()
		layout1.visible = false
	)

func _refresh_act_textures():
	act1_btn.texture_normal = tex_act1_unlocked
	
	# Act 2 Handling
	if purchased_acts[current_character_name].has("Act2"):
		act2_btn.texture_normal = tex_act2_bought
		act2_price_label.visible = false
	else:
		act2_btn.texture_normal = tex_act2_available
		act2_price_label.visible = true
		
	# Act 3 Handling
	if purchased_acts[current_character_name].has("Act3"):
		act3_btn.texture_normal = tex_act3_bought
		act3_price_label.visible = false
	elif purchased_acts[current_character_name].has("Act2"):
		# Act 2 is bought, so Act 3 is now "Available" to buy
		act3_btn.texture_normal = tex_act3_available
		act3_price_label.visible = true
	else:
		# Act 2 is not yet bought, so Act 3 is "Locked"
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
	character_picture_l3.texture_normal = character_picture_l2.texture_normal
	
	# Fetch slides for the selected character and act
	current_act_slides = _get_act_array(current_character_name, act_key)
	current_slide_index = 0
	_update_slide_display(false) # Initial load is instant
	
	layout3.visible = true
	layout3.modulate.a = 0.0
	
	var ghost_char = _create_ghost(character_picture_l2)
	var original_lore_pos = lore_paper.global_position
	lore_paper.pivot_offset = lore_paper.size / 2
	lore_paper.scale = Vector2(0.1, 0.1)
	lore_paper.global_position = clicked_btn.global_position
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(layout2, "modulate:a", 0.0, 0.3)
	tween.tween_property(layout3, "modulate:a", 1.0, 0.4)
	tween.tween_property(ghost_char, "global_position", character_picture_l3.global_position, 0.5)
	tween.tween_property(ghost_char, "size", character_picture_l3.size, 0.5)
	tween.tween_property(lore_paper, "scale", Vector2(1, 1), 0.6)
	tween.tween_property(lore_paper, "global_position", original_lore_pos, 0.6)
	
	tween.chain().tween_callback(func():
		ghost_char.queue_free()
		layout2.visible = false
	)

func _update_slide_display(animate: bool = true):
	if animate:
		is_slide_transitioning = true
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Fade out
		tween.tween_property(lore_part, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func():
			_set_slide_texture_and_buttons()
		)
		# Fade back in
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
		
	# Hide Next Button if we are on the last slide (or if there are no slides)
	if next_button:
		next_button.visible = (current_slide_index < current_act_slides.size() - 1)
			
	# Hide Prev Button if we are on the first slide
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
	ghost.size = source.size
	ghost.global_position = source.global_position
	add_child(ghost)
	return ghost

func _on_back_button_pressed():
	if layout3.visible:
		_fade_transition(layout3, layout2)
	elif layout2.visible:
		_fade_transition(layout2, layout1)
	else:
		closed.emit()

func _fade_transition(from: Control, to: Control):
	to.visible = true
	if from == layout3:
		lore_paper.scale = Vector2(1, 1)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(from, "modulate:a", 0.0, 0.3)
	tween.tween_property(to, "modulate:a", 1.0, 0.3)
	tween.chain().tween_callback(func(): from.visible = false)
	
	
	
func _sync_character_progress():

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
		GameData.character_stage[char_name] = stage

	
