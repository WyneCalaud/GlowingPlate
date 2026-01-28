extends Control

signal closed

# --- SETTINGS ---
const PRICE_PART2 = 15
const PRICE_PART3 = 30

# --- DATA STRUCTURE ---
var character_data = {
	"Leo": {
		"Part1": "Leo's childhood in the floating islands...",
		"Part2": "The day Leo discovered the ancient glow-stone...",
		"Part3": "Leo's ultimate goal to restore the sun."
	},
	"Maya": {
		"Part1": "Maya was born in the deep forest...",
		"Part2": "Her training with the emerald archers...",
		"Part3": "The prophecy involving Maya's family."
	},
	"Norma": {
		"Part1": "Norma's engineering feats in the steam city...",
		"Part2": "How she built her mechanical companion...",
		"Part3": "Norma's search for the lost blueprints."
	}
}

# Tracking purchased parts (CharacterName -> Array of bought parts)
var purchased_parts = {
	"Leo": ["Part1"],
	"Maya": ["Part1"],
	"Norma": ["Part1"]
}

var current_character_name = ""

# --- NODES ---
@onready var layout1 = $Layout1
@onready var layout2 = $Layout2
@onready var layout3 = $Layout3
@onready var back_button = $UI/BackButtonImage/TopLeftButton/BackButton
@onready var key_amount_label = $UI/KeysUI/TopRightKeys/KeyImage/KeyAmount

# Audio Nodes
@onready var success_sfx = $SuccessSFX
@onready var fail_sfx = $FailSFX

# Layout 1
@onready var leo_pic = $Layout1/CharacterCards/LeoCard/LeoPicture
@onready var maya_pic = $Layout1/CharacterCards/MayaCard/MayaPicture
@onready var norma_pic = $Layout1/CharacterCards/NormaCard/NormaPicture

# Layout 2
@onready var character_picture_l2 = $Layout2/SelectedCharacter/CharacterPicture
@onready var part1_btn = $Layout2/Parts/Part1
@onready var part2_btn = $Layout2/Parts/Part2
@onready var part3_btn = $Layout2/Parts/Part3

# Key Price Labels (Layout 2)
@onready var part2_price_label = $Layout2/Parts/Part2/KeyPrice
@onready var part3_price_label = $Layout2/Parts/Part3/KeyPrice

# Layout 3
@onready var character_picture_l3 = $Layout3/SelectedCharacter/CharacterPicture
@onready var lore_paper = $Layout3/BackstoryCharacter/LorePaper
@onready var info_text_label = $Layout3/BackstoryCharacter/LorePaper/InfoText

# --- TEXTURES ---
var tex_p1_unlocked = preload("res://Assets/UI/GlowBoard/UnlockedPart1.png")

var tex_p2_available = preload("res://Assets/UI/GlowBoard/AvailableButtonPart2.png")
var tex_p2_bought = preload("res://Assets/UI/GlowBoard/UnlockedPart2.png")

var tex_p3_locked = preload("res://Assets/UI/GlowBoard/LockedPart3.png") 
var tex_p3_available = preload("res://Assets/UI/GlowBoard/AvailableButtonPart3.png")
var tex_p3_bought = preload("res://Assets/UI/GlowBoard/UnlockedPart3.png")

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
	
	leo_pic.pressed.connect(func(): _on_character_selected("Leo", leo_pic))
	maya_pic.pressed.connect(func(): _on_character_selected("Maya", maya_pic))
	norma_pic.pressed.connect(func(): _on_character_selected("Norma", norma_pic))
	
	part1_btn.pressed.connect(func(): _handle_part_interaction("Part1", part1_btn))
	part2_btn.pressed.connect(func(): _handle_part_interaction("Part2", part2_btn))
	part3_btn.pressed.connect(func(): _handle_part_interaction("Part3", part3_btn))
	
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

# --- PURCHASE LOGIC ---
func _handle_part_interaction(part_key: String, btn: TextureButton):
	if purchased_parts[current_character_name].has(part_key):
		_on_part_selected(btn, part_key)
		return

	if part_key == "Part3" and not purchased_parts[current_character_name].has("Part2"):
		_purchase_failed(btn) 
		return

	var price = PRICE_PART2 if part_key == "Part2" else PRICE_PART3
	
	if GameData.keys >= price:
		_purchase_success(part_key, btn, price)
	else:
		_purchase_failed(btn)

func _purchase_success(part_key: String, btn: TextureButton, price: int):
	GameData.keys -= price
	purchased_parts[current_character_name].append(part_key)
	update_key_display()
	
	# Play Success Sound
	if success_sfx: success_sfx.play()
	
	var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	btn.modulate = Color.GREEN
	tween.tween_property(btn, "modulate", Color.WHITE, 0.5)
	
	_refresh_part_textures()
	
	await get_tree().create_timer(0.6).timeout
	_on_part_selected(btn, part_key)

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
	character_picture_l2.texture_normal = source_button.texture_normal
	
	_refresh_part_textures()
	
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

func _refresh_part_textures():
	part1_btn.texture_normal = tex_p1_unlocked
	
	# Part 2 Handling
	if purchased_parts[current_character_name].has("Part2"):
		part2_btn.texture_normal = tex_p2_bought
		part2_price_label.visible = false
	else:
		part2_btn.texture_normal = tex_p2_available
		part2_price_label.visible = true
		
	# Part 3 Handling
	if purchased_parts[current_character_name].has("Part3"):
		part3_btn.texture_normal = tex_p3_bought
		part3_price_label.visible = false
	elif purchased_parts[current_character_name].has("Part2"):
		# Part 2 is bought, so Part 3 is now "Available" to buy
		part3_btn.texture_normal = tex_p3_available
		part3_price_label.visible = true
	else:
		# Part 2 is not yet bought, so Part 3 is "Locked"
		part3_btn.texture_normal = tex_p3_locked
		part3_price_label.visible = false

# --- TRANSITION: L2 -> L3 ---
func _on_part_selected(clicked_btn: TextureButton, part_key: String):
	character_picture_l3.texture_normal = character_picture_l2.texture_normal
	if character_data.has(current_character_name):
		info_text_label.text = character_data[current_character_name][part_key]
	
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
