extends Control

# --- References ---
@onready var darken_overlay = $OverlayCanvas/DarkenOverlay
@onready var almanac_ui = $OverlayCanvas/AlmanacUI
@onready var glowboard = $OverlayCanvas/GlowBoard
@onready var nutrishop_ui = $OverlayCanvas/NutriShop
@onready var glow_desk_ui = $OverlayCanvas/GlowDesk

@onready var day_scene = $DayScene
@onready var dialogue_box = $DayScene/DialogueBox
@onready var customer_manager = $DayScene/CustomerManager
@onready var dialogue_text: Label = $DayScene/OrderText

@onready var day_number: Label = $BottomButtons/StartDayButton/Label

@onready var skip_day_btn = $SkipDayButton
@onready var bottom_buttons = $BottomButtons
@onready var hideshowbutton = $BottomButtons/HBoxContainer/HideShowButton
@onready var almanac_btn = $BottomButtons/HBoxContainer/Almanac
@onready var bulletin_btn = $BottomButtons/HBoxContainer/GlowBoard
@onready var start_day_btn = $BottomButtons/StartDayButton
@onready var nutridesk_btn = $BottomButtons/HBoxContainer/GlowDesk
@onready var nutrishop_btn = $BottomButtons/HBoxContainer/GlowShop

@onready var final_plate_display = $FinalPlateDisplay
@onready var final_beverage_display = $FinalBeverageDisplay

@onready var principal_leave_btn = $DayScene/BtnPrincipalLeave
# --- State Variables ---
var current_open_popup: Control = null
var current_popup_tween: Tween
var button_type = null

var current_happiness: float = 100.0
var happiness_decay_rate: float = 2.0
var is_waiting_for_serve: bool = false

var is_food_intro_active := false

var is_typing: bool = false
var full_dialogue_text: String = ""
var typing_speed: float = 0.08   # seconds between words

@export_group("Dialogue Box Settings")

@export var box_texture_small: Texture2D
@export var box_texture_medium: Texture2D
@export var box_texture_large: Texture2D

@export var box_size_small: Vector2 = Vector2(764, 192)
@export var box_size_medium: Vector2 = Vector2(782, 246)
@export var box_size_large: Vector2 = Vector2(884, 496)

@export var box_position_small: Vector2 = Vector2(80, 151)
@export var box_position_medium: Vector2 = Vector2(80, 151)
@export var box_position_large: Vector2 = Vector2(75, 120)

var base_box_position: Vector2 = Vector2.ZERO

# ---------------------------------------------------------
# LIFECYCLE
# ---------------------------------------------------------

func _ready() -> void:
	add_to_group("LobbyAutoStart")
	dialogue_box.hide()
	if is_instance_valid(dialogue_box):
		base_box_position = dialogue_box.position
	$DayScene/BtnAccept.hide()
	$DayScene/BtnContinue.hide()
	principal_leave_btn.hide()

	if almanac_ui.has_signal("closed"):
		if not almanac_ui.closed.is_connected(_on_almanac_ui_closed):
			almanac_ui.closed.connect(_on_almanac_ui_closed)

	if glowboard.has_signal("closed"):
		if not glowboard.closed.is_connected(_on_glowboard_closed):
			glowboard.closed.connect(_on_glowboard_closed)
			
	if nutrishop_ui.has_signal("closed"):
		if not nutrishop_ui.closed.is_connected(_on_nutri_shop_closed):
			nutrishop_ui.closed.connect(_on_nutri_shop_closed)

	if glow_desk_ui.has_signal("closed"):
		if not glow_desk_ui.closed.is_connected(_on_glow_desk_closed):
			glow_desk_ui.closed.connect(_on_glow_desk_closed)

	if nutridesk_btn:
		if not nutridesk_btn.pressed.is_connected(_on_glow_desk_pressed):
			nutridesk_btn.pressed.connect(_on_glow_desk_pressed)
			
	# DEFENSIVE FIX: Connect the skip button dynamically
	if is_instance_valid(skip_day_btn):
		if not skip_day_btn.pressed.is_connected(_on_skip_day_pressed):
			skip_day_btn.pressed.connect(_on_skip_day_pressed)

	_check_for_returned_items()
	
	var GD = get_node("/root/GameData")

	# 🔥 Always reset phase when entering lobby
	if GD.current_phase == GD.GamePhase.NEWS and not GD.day_started:
		GD.current_phase = GD.GamePhase.LOBBY
		GD.save_game()

	day_number.text = "Day %02d" % GD.current_day

	# --- AUTO START LOGIC ---
	if GD.has_meta("tutorial_auto_start") and GD.get_meta("tutorial_auto_start"):
		GD.set_meta("tutorial_auto_start", false) # Consume the flag so it only happens once
		
		# Immediately hide lobby UI so the player never sees it
		almanac_btn.hide()
		bulletin_btn.hide()
		start_day_btn.hide()
		nutridesk_btn.hide()
		nutrishop_btn.hide()
		hideshowbutton.hide()
		bottom_buttons.hide()
		
		# Give the engine a frame to settle, then immediately simulate pressing the button
		call_deferred("_on_day_button_pressed")
		return # Exit early so we don't run the normal lobby setup
		
	# Normal lobby setup if we didn't auto-start
	_restore_day_ui_state()
	
	if not principal_leave_btn.pressed.is_connected(_on_principal_leave_pressed):
		principal_leave_btn.pressed.connect(_on_principal_leave_pressed)
	
	_restore_patience_ui()
	
	# 🔥 FIX: Resume day after skipping matching (Day 6+)
	if GD.current_phase == GD.GamePhase.LOBBY and GD.day_started:
		await get_tree().process_frame
		play_food_intro_if_needed()
		return

	if GD.current_phase == GD.GamePhase.NEWS and GD.day_started:
		# Small delay so scene fully loads
		await get_tree().process_frame
		play_food_intro_if_needed()

func _process(delta: float) -> void:
	if is_waiting_for_serve:
		current_happiness = max(0.0, current_happiness - (happiness_decay_rate * delta))

func auto_start_after_news():
	var GD = get_node("/root/GameData")

	# Prevent double starting
	if GD.day_started:
		return

	_on_day_button_pressed()


# ---------------------------------------------------------
# FOOD INTRO STUFF
# ---------------------------------------------------------

func typewriter_words(text: String) -> void:

	is_typing = true
	full_dialogue_text = text
	dialogue_text.text = ""

	var words: PackedStringArray = text.split(" ")
	var built_text: String = ""

	for i in words.size():
		built_text += words[i]

		if i < words.size() - 1:
			built_text += " "

		dialogue_text.text = built_text

		await get_tree().create_timer(typing_speed).timeout

	is_typing = false

func _play_dialogue(text_content: String, box_size_type: String = "medium"):

	var target_texture: Texture2D = null
	var target_position: Vector2 = base_box_position
	var target_size: Vector2 = dialogue_box.size

	match box_size_type.to_lower():

		"small":
			target_texture = box_texture_small
			target_size = box_size_small
			target_position = base_box_position + box_position_small

		"large":
			target_texture = box_texture_large
			target_size = box_size_large
			target_position = base_box_position + box_position_large

		_:
			target_texture = box_texture_medium
			target_size = box_size_medium
			target_position = base_box_position + box_position_medium

	if dialogue_box:

		if target_texture != null and "texture" in dialogue_box:
			dialogue_box.texture = target_texture

		dialogue_box.size = target_size
		dialogue_box.position = target_position
		dialogue_box.pivot_offset = dialogue_box.size / 2.0

		dialogue_box.scale = Vector2(0.95, 0.95)

		var tween = create_tween()
		tween.tween_property(dialogue_box, "scale", Vector2.ONE, 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await typewriter_words(text_content)

func _input(event):
	if event.is_action_pressed("ui_accept") and is_typing:
		dialogue_text.text = full_dialogue_text
		is_typing = false

func start_real_day():
	var GD = get_node("/root/GameData")

	# 🔼 Restore normal font size for customers
	dialogue_text.add_theme_font_size_override("font_size", 32)

	# Day officially begins
	GD.service_state = GameData.ServiceState.IDLE

	spawn_next_customer()

	almanac_btn.hide()
	bulletin_btn.hide()
	start_day_btn.hide()
	nutridesk_btn.hide()
	nutrishop_btn.hide()
	hideshowbutton.hide()
	bottom_buttons.hide()

const FOOD_INTRO_TEXT := {
	2: "We now have Pan de sal, in case a student wants something other than rice. Let’s try serving these cute kids some pan de sal, shall we?",
	
	3: "Turns out, there are kids who don’t like chicken, good thing we now have fish to serve them. This is a good way for them to eat variety of grow foods too!Let’s try serving these cute kids some fish now, shall we?",
	
	4: "It’s time to introduce these kids to another vegetable. Something that is high in vitamin A this time. I hope they  get used to eating vegetables soon! Let’s try serving these cute kids some squash, shall we?",
	
	5: "Fruits are so yummy, aren’t they? They’re yummy and also healthy!Good thing we have another  fruit to serve now, and I hope the kids get to enjoy it very much. Let’s try serving these cute kids some watermelon, shall we?",
	
	6: "Rice isn’t the only Go food that gives us energy!Today, we’re introducing corn. It’s yummy, and helps kids stay active and energized. Some students might want to try corn instead of rice or bread. Let’s try serving these cute kids some corn today, shall we?",
	
	7: "Not all Grow foods are meat or fish! Today, we’re introducing eggs. They help kids grow strong and are a great source of protein. A great alternative for students that don't want fish or chicken.Let’s try serving these cute kids some eggs, shall we?.",
	
	8: "Vegetables help keep our eyes, skin, and body healthy! Today, we’re introducing carrots. They’re crunchy, colorful, and full of vitamin A. Let’s try serving these cute kids some carrots today, shall we?",
	
	9: "Rice gives us energy, and there are different kinds to try! Today we’re introducin brown rice — a healthy choice that keeps our tummies healthy and gives lasting energy. Some kids might want to try brown rice instead of white rice. Let’s serve them some and give it a try!",
	
	10: "Grow foods don’t always come from meat, fish, or eggs. Today, we’re introducing tokwa — it’s made from soybeans and helps our body grow strong too! This is a great option for kids who want a plant-based Grow food.Let’s try serving these cute kids some tokwa today, shall we?",
	
	11: "Vegetables come in many shapes, colors, and tastes! Today, we’re introducing eggplant — it’s a purple vegetable that helps keep our body healthy. Some kids might be curious or unsure about its taste, and that’s okay.Let’s try serving these cute kids some eggplant today, shall we?",
	
	12: "Fruits help keep us healthy and give us vitamins! Today, we’re introducing banana — it’s sweet, soft, and gives quick energy. Many kids love bananas, so you might hear them ask for it today. Let’s try serving these cute kids some bananas, shall we?",
	
	13: "Today, we’re shining the spotlight on squash, Squash can be yellow, green, or even orange, and it tastes a little sweet and soft when it’s cooked. It’s full of vitamins that help our eyes see clearly, our skin glow, and our bodies grow big and strong."
}

const FOOD_INTRO_FONT_SIZE := {
	2: 32,
	3: 30,
	4: 30,
	5: 30,
	6: 26,
	7: 26,
	8: 28,
	9: 26,
	10: 26,
	11: 26,
	12: 26,
	13: 26
}


func play_food_intro_if_needed():
	var GD = get_node("/root/GameData")
	var day = GD.current_day

	if GD.shown_food_intros.get(day, false):
		start_real_day()
		return

	if not FOOD_INTRO_TEXT.has(day):
		start_real_day()
		return

	GD.shown_food_intros[day] = true
	GD.save_game()

	spawn_principal_intro(day, FOOD_INTRO_TEXT[day])

func spawn_principal_intro(day:int, text:String):
	var GD = get_node("/root/GameData")
	GD.service_state = GameData.ServiceState.IDLE

	is_food_intro_active = true

	var tex = preload("res://Assets/Customers/Principal_.png")

	customer_manager.spawn_customer(null, tex)

	await customer_manager.customer_arrived

	dialogue_box.show()

	# 🎯 Get custom font size for this day
	var font_size : int = FOOD_INTRO_FONT_SIZE.get(day, 28)

	dialogue_text.add_theme_font_size_override("font_size", font_size)

	await _play_dialogue(text, "large")

	principal_leave_btn.show()


func _on_principal_confirm():

	dialogue_box.hide()
	$DayScene/BtnAccept.hide()

	customer_manager.next_customer()

	await customer_manager.customer_left

	start_real_day()

func _on_principal_leave_pressed() -> void:
	principal_leave_btn.hide()
	dialogue_box.hide()
	dialogue_text.hide()

	customer_manager.next_customer()
	await customer_manager.customer_left
	
	# 🔥 SMALL RESET DELAY (CRITICAL FIX)
	await get_tree().create_timer(0.15).timeout

	is_food_intro_active = false
	start_real_day()


# ---------------------------------------------------------
# STATE RESTORE
# ---------------------------------------------------------

func _restore_day_ui_state() -> void:
	var gd := get_node("/root/GameData")

	if gd.day_started:
		var is_idle = (gd.service_state == GameData.ServiceState.IDLE)
		is_waiting_for_serve = !is_idle

		almanac_btn.hide()
		bulletin_btn.hide()
		start_day_btn.hide()
		nutridesk_btn.hide()
		nutrishop_btn.hide()
		hideshowbutton.hide()
		bottom_buttons.hide() # <-- ADDED THIS
	else:
		is_waiting_for_serve = false

		almanac_btn.show()
		bulletin_btn.show()
		start_day_btn.show()
		nutridesk_btn.show()
		nutrishop_btn.show()
		hideshowbutton.show()
		bottom_buttons.show() # <-- ADDED THIS

		get_tree().call_group("HUD", "_reset_happiness_ui")


func _check_for_returned_items() -> void:
	if OrderSystem.prepared_plate_contents.size() > 0:
		show_final_plate(OrderSystem.prepared_plate_contents)
	else:
		final_plate_display.hide()

	if OrderSystem.prepared_beverage_data.size() > 0:
		show_final_beverages(OrderSystem.prepared_beverage_data)
	else:
		final_beverage_display.hide()


# ---------------------------------------------------------
# DEBUG HELPERS
# ---------------------------------------------------------

func _debug_plate_slots() -> void:
	print("==== 🧪 PLATE DEBUG ====")

	# Explicitly typed dictionaries
	var expected: Dictionary = OrderSystem.current_customer_order.required_plate
	var plated: Dictionary = {}

	# Build what the player plated
	for entry: Dictionary in OrderSystem.prepared_plate_contents:
		var slot: String = entry.get("accepted_type", "") as String
		if slot != "":
			var item = entry.get("item")
			if item and item.has_method("get"):
				plated[slot] = item.internal_key

	# Explicitly typed slot list
	var slots: Array[String] = ["Go", "Grow", "GlowVeg", "GlowFru"]

	for slot: String in slots:
		var exp: String = expected.get(slot, "") as String
		var act: String = plated.get(slot, "") as String

		var status: String = "✅ OK"
		if act == "":
			status = "❌ MISSING"
		elif act != exp:
			status = "❌ WRONG"

		print(
			slot.lpad(8),
			"| Expected:", exp.lpad(14),
			"| Actual:", act.lpad(14),
			"|", status
		)

	print("========================")


# ---------------------------------------------------------
# TEXTURE RESOLUTION (FIXED)
# ---------------------------------------------------------

func _get_item_texture(entry: Dictionary) -> Texture2D:
	var res = entry.get("item")
	if not res:
		return null

	var base_tex = res.get("default_plated_texture")

	var portion: String = str(entry.get("portion_type", ""))
	if portion == "":
		portion = str(res.get_meta("Portion", ""))

	var count: int = int(entry.get("count", 1))

	# --- Veggie Cup Handling (FIXED FOR LOW/MED/HIGH/FULL) ---
	if portion == "VeggieLow":
		var veg_tex = res.get("veggie_plated_low")
		if veg_tex:
			return veg_tex

	elif portion == "VeggieMed":
		var veg_tex = res.get("veggie_plated_med")
		if veg_tex:
			return veg_tex

	elif portion == "VeggieHigh":
		var veg_tex = res.get("veggie_plated_high")
		if veg_tex:
			return veg_tex

	elif portion == "VeggieFull":
		var veg_tex = res.get("veggie_plated_full")
		if veg_tex:
			return veg_tex

	# --- Portion Handling ---
	if portion == "Half":
		match count:
			2: return res.get("plated_texture_half_2")
			3: return res.get("plated_texture_half_3")
			_: return res.get("plated_texture_half")

	elif portion == "Whole":
		match count:
			2: return res.get("plated_texture_whole_2")
			3: return res.get("plated_texture_whole_3")
			_: return res.get("plated_texture_whole")

	# --- Rice / Drink Meta ---
	var rice_amt = res.get_meta("RiceAmount", "")
	var drink_amt = res.get_meta("DrinkAmount", "")

	if rice_amt != "":
		match rice_amt:
			"Small": return res.get("plated_texture_small")
			"Medium": return res.get("plated_texture_medium")
			"TooHigh": return res.get("plated_texture_too_high")

	if drink_amt != "":
		match drink_amt:
			"Low": return res.get("plated_texture_small")
			"Medium": return res.get("plated_texture_medium")
			"TooHigh": return res.get("plated_texture_too_high")

	# --- Standard Stack Counts ---
	match count:
		2: return res.get("texture_count_2")
		3: return res.get("texture_count_3")
		4: return res.get("texture_count_4")
		5: return res.get("texture_count_5")
		_:
			var c1 = res.get("texture_count_1")
			if c1:
				return c1

	return base_tex


# ---------------------------------------------------------
# FINAL PLATE DISPLAY
# ---------------------------------------------------------

func show_final_plate(contents: Array) -> void:
	final_plate_display.show()
	$FinalPlateDisplay/PlateDisplay.texture = preload("res://Items/Plates/Plate Final.png")

	var sprite_map = {
		"Go": $FinalPlateDisplay/PlateSpriteGo,
		"Grow": $FinalPlateDisplay/PlateSpriteGrow,
		"GlowVeg": $FinalPlateDisplay/PlateSpriteVeg,
		"GlowFru": $FinalPlateDisplay/PlateSpriteFru
	}

	for s in sprite_map.values():
		s.hide()

	for entry in contents:
		var category = entry.get("accepted_type")
		var sprite = sprite_map.get(category)
		var tex = _get_item_texture(entry)

		if sprite and tex:
			sprite.texture = tex
			sprite.scale = Vector2(0.1, 0.1)
			sprite.show()


# ---------------------------------------------------------
# FINAL BEVERAGE DISPLAY
# ---------------------------------------------------------

func show_final_beverages(beverage_data: Dictionary) -> void:
	final_beverage_display.show()

	var sprites = [
		$FinalBeverageDisplay/BeverageSprite1,
		$FinalBeverageDisplay/BeverageSprite2
	]

	for s in sprites:
		s.hide()

	var index := 0
	for entry in beverage_data.values():
		if index >= sprites.size():
			break

		var tex = _get_item_texture(entry)
		if tex:
			sprites[index].texture = tex
			sprites[index].scale = Vector2(0.3, 0.3)
			sprites[index].show()
			index += 1


# ---------------------------------------------------------
# SERVE BUTTON
# ---------------------------------------------------------

func _format_food_name(internal_key: String) -> String:
	match internal_key:
		"PANDESAL": return "Pandesal"
		"RICE": return "Rice"
		"BROWN_RICE": return "Brown Rice"
		"CORN": return "Corn"
		"CHICKEN_LEG": return "Chicken"
		"FISH_FILLET": return "Fish"
		"TOFU": return "Tokwa"
		"EGG": return "Egg"
		"SITAW": return "Sitaw"
		"CARROTS": return "Carrots"
		"EGGPLANT": return "Eggplant"
		"PUMPKIN": return "Squash" # important
		"MANGO": return "Mango"
		"WATERMELON": return "Watermelon"
		"BANANA": return "Banana"
		"PAPAYA": return "Papaya"
		_:
			return internal_key.capitalize()

func _format_slot_name(slot:String) -> String:
	match slot:
		"Go": return "Go"
		"Grow": return "Grow"
		"GlowVeg": return "Glow Vegetable"
		"GlowFru": return "Glow Fruit"
		_:
			return slot

func _format_beverage_name(internal_key: String) -> String:
	match internal_key:
		"WATER": return "water"
		"MILK": return "milk"
		_:
			return internal_key.to_lower()

func _format_any_slot_name(slot:String) -> String:
	match slot:
		"Go": return "Go food"
		"Grow": return "Grow food"
		"GlowVeg": return "vegetable"
		"GlowFru": return "fruit"
		_:
			return "food"

func _get_feedback_box_size(mistakes: Array) -> String:
	if mistakes.size() <= 1:
		return "small"
	elif mistakes.size() == 2:
		return "medium"
	return "large"

func _on_btn_final_serve_pressed() -> void:
	$FinalPlateDisplay/BtnFinalServe.hide()

	if is_inside_tree():
		get_tree().call_group("HUD", "stop_patience")

	var GD = get_node("/root/GameData")
	is_waiting_for_serve = false

	_debug_plate_slots()

	var correct := (
		OrderSystem.is_plate_correct()
		and OrderSystem.is_beverage_correct()
	)

	# 🔥 IMPORTANT: Generate mistakes BEFORE finalize_service clears data
	var mistakes := []
	if not correct:
		mistakes = _get_detailed_mistakes()
		current_happiness = clamp(current_happiness - 30.0, 0.0, 100.0)

	var character_id := ""
	if GD.saved_customer_order:
		character_id = GD.saved_customer_order.customer_name
		
	# --- UPGRADE LOGIC: MEAL BONUS ---
	var money_earned = 0
	if correct:
		money_earned = 10
		if "unlocked_upgrades" in GD and GD.unlocked_upgrades.has("Meal Bonus"):
			money_earned += 15 # Gives 25 instead of 10!
			print("Meal Bonus Applied! Earned: ", money_earned)

	# Show dialogue box BEFORE typing
	dialogue_box.show()
	dialogue_text.text = ""

	if correct:
		await _play_dialogue(_get_happy_feedback(), "small")
		
		if character_id in ["Leo", "Maya", "Norma"]:
			_show_special_key_reward()
		
	else:
		await _play_dialogue(_get_angry_feedback(mistakes), _get_feedback_box_size(mistakes))

		if character_id != "":
			customer_manager.play_sad_reaction(character_id)

	# NOW finalize service
	GD.finalize_service({
		"earned_money": money_earned,
		"reputation_change": 1.0 if correct else -0.5,
		"happiness": get_hud_patience(),
		"character_id": character_id,
		"prog_gain": 34.0 if correct else 0.0,
		"is_correct": correct
	})

	GD.service_state = GameData.ServiceState.SERVED
	
	GD.returning_from_kitchen = false

	current_happiness = 100.0

	final_beverage_display.hide()
	final_plate_display.hide()

	dialogue_box.show()
	$DayScene/BtnAccept.hide()
	$DayScene/BtnContinue.hide()

	# If this was the LAST customer, stop here.
	if GD.remaining_customers.is_empty():
		return

	await get_tree().create_timer(3.5).timeout

	customer_manager.next_customer()

	# Wait for customer to fully leave
	await customer_manager.customer_left

	# 🔥 NOW it is safe to clear the previous customer
	GD.clear_customer()

	# Safety check
	if not is_inside_tree():
		return

	await get_tree().create_timer(0.15).timeout

	if not GD.remaining_customers.is_empty():
		spawn_next_customer()

func _get_detailed_mistakes() -> Array:

	var mistakes := []

	var required_plate: Dictionary = OrderSystem.current_customer_order.required_plate
	var required_portions: Dictionary = OrderSystem.current_customer_order.get("required_portions", {})
	var required_beverages: Dictionary = OrderSystem.current_customer_order.get("required_beverages", {})

	var plated_map := {}

	# Build plated map
	for entry in OrderSystem.prepared_plate_contents:
		var slot = entry.get("accepted_type")
		if slot:
			var item = entry.get("item")
			plated_map[slot] = {
				"key": item.internal_key,
				"portion": item.get_meta("Portion") if item.has_meta("Portion") else "",
				"rice": item.get_meta("RiceAmount") if item.has_meta("RiceAmount") else "",
				"quantity": entry.get("count", 1)
			}

	for category in required_plate.keys():

		var expected_key = required_plate[category]
		var expected_portion = required_portions.get(category, null)

		# --- Missing slot entirely ---
		if not plated_map.has(category):
			if expected_key == "ANY":
				mistakes.append("Missing my %s!" % _format_any_slot_name(category))
			else:
				mistakes.append("Missing my %s!" % _format_food_name(expected_key))
			continue

		var actual = plated_map[category]
		# --- Wrong category placement (non-ANY too) ---
		var food_res = OrderSystem.FOOD_DB.get(actual.key)
		if food_res and food_res.food_category != category:
			mistakes.append("Wrong %s food!" % _format_slot_name(category))
			continue

		# --- Wrong food ---
		if expected_key != "ANY" and actual.key != expected_key:
			mistakes.append("I asked for %s, not %s!" % [
				_format_food_name(expected_key),
				_format_food_name(actual.key)
			])
			continue

		# --- ANY but wrong category placement ---
		if expected_key == "ANY":
			if food_res and food_res.food_category != category:
				mistakes.append("That’s not the right %s!" % _format_any_slot_name(category))
				continue

		# --- Portion checks ---
		match expected_key:

			"CHICKEN_LEG", "FISH_FILLET", "EGG", "TOFU", "CORN", "SITAW", "CARROTS", "EGGPLANT", "PUMPKIN":
				if actual.portion != expected_portion:
					mistakes.append("Wrong %s portion!" % _format_slot_name(category))

			"RICE":
				if actual.rice != expected_portion:
					mistakes.append("Wrong rice amount!")

			"PANDESAL":
				if actual.quantity != expected_portion:
					mistakes.append("Need %s pandesal!" % str(expected_portion))

	# ---------------------------------------------------------
	# BEVERAGE CHECKS
	# ---------------------------------------------------------
	var prepared_beverages: Dictionary = OrderSystem.prepared_beverage_data

	for bev_slot in required_beverages.keys():
		var expected_bev = required_beverages[bev_slot]

		if not prepared_beverages.has(bev_slot):
			if expected_bev == "WATER":
				mistakes.append("Missing my water!")
			elif expected_bev == "MILK":
				mistakes.append("Missing my milk!")
			else:
				mistakes.append("Missing my %s!" % _format_beverage_name(expected_bev))
			continue

		var bev_entry = prepared_beverages[bev_slot]
		var bev_item = bev_entry.get("item")
		var actual_bev = ""

		if bev_item:
			actual_bev = bev_item.internal_key

		if actual_bev != expected_bev:
			if expected_bev == "WATER":
				mistakes.append("I asked for water, not %s!" % _format_beverage_name(actual_bev))
			elif expected_bev == "MILK":
				mistakes.append("I asked for milk, not %s!" % _format_beverage_name(actual_bev))
			else:
				mistakes.append("I asked for %s, not %s!" % [
					_format_beverage_name(expected_bev),
					_format_beverage_name(actual_bev)
				])

	return mistakes

func _get_angry_feedback(mistakes: Array) -> String:

	if mistakes.is_empty():
		return "Something’s wrong..."

	var combined := ""

	if mistakes.size() == 1:
		combined = mistakes[0]

	elif mistakes.size() == 2:
		combined = "%s and %s" % [mistakes[0], mistakes[1]]

	else:
		for i in range(mistakes.size()):
			if i == mistakes.size() - 1:
				combined += "and " + mistakes[i]
			else:
				combined += mistakes[i] + ", "

	var variants = [
		"Oh no! %s",
		"Not quite! %s",
		"Hmm... %s"
	]

	return variants.pick_random() % combined

func _get_happy_feedback() -> String:

	var variants = [
		"Thank you!",
		"Thanks! This looks great!",
		"Yay! This is perfect!"
	]

	return variants.pick_random()

# ---------------------------------------------------------
# DAY BUTTON
# ---------------------------------------------------------

func _on_day_button_pressed() -> void:
	var GD := get_node("/root/GameData")
	var day_orders: Array = []

	match GD.current_day:

		1:
			day_orders = [
				preload("res://Data/Customer/Day1one.tres"),
				preload("res://Data/Customer/Day1two.tres"),
				preload("res://Data/Customer/Day1three.tres")
			]

		2:
			day_orders = [
				preload("res://Data/Customer/Day2one.tres"),
				preload("res://Data/Customer/Day2two.tres"),
				preload("res://Data/Customer/Day2three.tres"),
				preload("res://Data/Customer/Day2four.tres")
			]

		3:
			day_orders = [
				preload("res://Data/Customer/Day3one.tres"),
				preload("res://Data/Customer/Day3two.tres"),
				preload("res://Data/Customer/Day3three.tres"),
				preload("res://Data/Customer/Day3four.tres"),
				preload("res://Data/Customer/Day3five.tres")
			]

		4:
			day_orders = [
				preload("res://Data/Customer/Day4one.tres"),
				preload("res://Data/Customer/Day4two.tres"),
				preload("res://Data/Customer/Day4three.tres"),
				preload("res://Data/Customer/Day4four.tres"),
				preload("res://Data/Customer/Day4five.tres")
			]

		5:
			day_orders = [
				preload("res://Data/Customer/Day5one.tres"),
				preload("res://Data/Customer/Day5two.tres"),
				preload("res://Data/Customer/Day5three.tres"),
				preload("res://Data/Customer/Day5four.tres"),
				preload("res://Data/Customer/Day5five.tres")
			]

		6:
			day_orders = [
				preload("res://Data/Customer/Day6one.tres"),
				preload("res://Data/Customer/Day6two.tres"),
				preload("res://Data/Customer/Day6three.tres"),
				preload("res://Data/Customer/Day6four.tres"),
				preload("res://Data/Customer/Day6five.tres"),
				preload("res://Data/Customer/Day6six.tres")
			]

		7:
			day_orders = [
				preload("res://Data/Customer/Day7one.tres"),
				preload("res://Data/Customer/Day7two.tres"),
				preload("res://Data/Customer/Day7three.tres"),
				preload("res://Data/Customer/Day7four.tres"),
				preload("res://Data/Customer/Day7five.tres"),
				preload("res://Data/Customer/Day7six.tres"),
				preload("res://Data/Customer/Day7seven.tres")
			]

		8:
			day_orders = [
				preload("res://Data/Customer/Day8one.tres"),
				preload("res://Data/Customer/Day8two.tres"),
				preload("res://Data/Customer/Day8three.tres"),
				preload("res://Data/Customer/Day8four.tres"),
				preload("res://Data/Customer/Day8five.tres"),
				preload("res://Data/Customer/Day8six.tres"),
				preload("res://Data/Customer/Day8seven.tres")
			]

		9:
			day_orders = [
				preload("res://Data/Customer/Day9one.tres"),
				preload("res://Data/Customer/Day9two.tres"),
				preload("res://Data/Customer/Day9three.tres"),
				preload("res://Data/Customer/Day9four.tres"),
				preload("res://Data/Customer/Day9five.tres"),
				preload("res://Data/Customer/Day9six.tres")
			]

		10:
			day_orders = [
				preload("res://Data/Customer/Day10one.tres"),
				preload("res://Data/Customer/Day10two.tres"),
				preload("res://Data/Customer/Day10three.tres"),
				preload("res://Data/Customer/Day10four.tres"),
				preload("res://Data/Customer/Day10five.tres"),
				preload("res://Data/Customer/Day10six.tres")
			]

		11:
			day_orders = [
				preload("res://Data/Customer/Day11one.tres"),
				preload("res://Data/Customer/Day11two.tres"),
				preload("res://Data/Customer/Day11three.tres"),
				preload("res://Data/Customer/Day11four.tres"),
				preload("res://Data/Customer/Day11five.tres"),
				preload("res://Data/Customer/Day11six.tres")
			]

		12:
			day_orders = [
				preload("res://Data/Customer/Day12one.tres"),
				preload("res://Data/Customer/Day12two.tres"),
				preload("res://Data/Customer/Day12three.tres"),
				preload("res://Data/Customer/Day12four.tres"),
				preload("res://Data/Customer/Day12five.tres"),
				preload("res://Data/Customer/Day12six.tres"),
				preload("res://Data/Customer/Day12seven.tres")
			]

		13:
			day_orders = [
				preload("res://Data/Customer/Day13one.tres"),
				preload("res://Data/Customer/Day13two.tres"),
				preload("res://Data/Customer/Day13three.tres"),
				preload("res://Data/Customer/Day13four.tres"),
				preload("res://Data/Customer/Day13five.tres"),
				preload("res://Data/Customer/Day13six.tres")
			]

		14:
			day_orders = [
				preload("res://Data/Customer/Day14one.tres"),
				preload("res://Data/Customer/Day14two.tres"),
				preload("res://Data/Customer/Day14three.tres"),
				preload("res://Data/Customer/Day14four.tres"),
				preload("res://Data/Customer/Day14five.tres"),
				preload("res://Data/Customer/Day14six.tres"),
				preload("res://Data/Customer/Day14seven.tres")
			]

		_:
			day_orders = [
				preload("res://Data/Customer/Day1one.tres")
			]

	if not GD.day_started:
		GD.start_day_with_orders(day_orders)

	# -------------------------
	# DAY 1 → No mini game
	# -------------------------
	if GD.current_day == 1:
		play_food_intro_if_needed()
		_restore_day_ui_state()
		return

	# -------------------------
	# If returning from NEWS
	# -------------------------
	if GD.current_phase == GD.GamePhase.NEWS:
		GD.current_phase = GD.GamePhase.LOBBY
		play_food_intro_if_needed()
		_restore_day_ui_state()
		return

	# -------------------------
	# Otherwise → Start MATCHING
	# -------------------------
	GD.current_phase = GD.GamePhase.MATCHING
	GD.save_game()
	SceneTransition.fade_to("res://Scenes/MiniGame/matching_game.tscn")

func _emit_customer_exit():
	var manager = get_tree().get_first_node_in_group("CustomerManager")
	if manager and manager.current_customer:
		manager.customer_leave()

# --- Scene Transitions ---

func _start_transition(type: String):
	button_type = type
	$Fade_transition.show()
	$Fade_transition/Fade_timer.start()
	$Fade_transition/AnimationPlayer.play("Fade_In")

func _on_fade_timer_timeout() -> void:
	if button_type == "menu":
		SceneTransition.fade_to("res://Scenes/Main Menu/Main_menu.tscn")

func _on_settings_button_pressed() -> void:

	var GD = get_node("/root/GameData")

	# 🔥 FIX: If player leaves mid-service, clear the active customer
	GD.clear_customer()
	GD.service_state = GameData.ServiceState.IDLE
	GD.returning_from_kitchen = false
	GD.day_started = false

	_start_transition("menu")


# ---------------------------------------------------------
# POPUP LOGIC
# ---------------------------------------------------------

func _on_glow_desk_pressed() -> void:
	if current_open_popup == glow_desk_ui:
		close_popup()
	elif current_open_popup == null:
		open_popup(glow_desk_ui)

func open_popup(popup_node: Control) -> void:
	if current_popup_tween and current_popup_tween.is_valid():
		current_popup_tween.kill()

	current_open_popup = popup_node 
	darken_overlay.show()
	current_open_popup.show()
	
	current_popup_tween = create_tween().set_parallel(true)
	current_popup_tween.tween_property(darken_overlay, "modulate:a", 0.5, 0.3)
	current_popup_tween.tween_property(current_open_popup, "modulate:a", 1.0, 0.3).from(0.0)
	
func close_popup() -> void:
	if current_open_popup == null:
		return

	if current_popup_tween and current_popup_tween.is_valid():
		current_popup_tween.kill()

	var popup_to_close = current_open_popup
	current_open_popup = null 
	
	current_popup_tween = create_tween().set_parallel(true)
	current_popup_tween.tween_property(darken_overlay, "modulate:a", 0.0, 0.3)
	current_popup_tween.tween_property(popup_to_close, "modulate:a", 0.0, 0.3)
	current_popup_tween.finished.connect(func(): 
		darken_overlay.hide()
		popup_to_close.hide()
		popup_to_close.modulate.a = 1.0
	)

func _on_almanac_ui_closed() -> void: close_popup()
func _on_glowboard_closed() -> void: close_popup()
func _on_nutri_shop_closed() -> void: close_popup()
func _on_glow_desk_closed() -> void: close_popup()


func _on_almanac_pressed() -> void:
	if current_open_popup == almanac_ui:
		close_popup()
	elif current_open_popup == null:
		open_popup(almanac_ui)


func _on_glow_board_pressed() -> void:
	if current_open_popup == glowboard:
		close_popup()
	elif current_open_popup == null:
		open_popup(glowboard)


func _on_glow_shop_pressed() -> void:
	if current_open_popup == nutrishop_ui:
		close_popup()
	elif current_open_popup == null:
		open_popup(nutrishop_ui)

func get_hud_patience() -> float:
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud:
		return hud.patience
	return 100.0

func _restore_patience_ui():

	var GD = get_node("/root/GameData")
	var hud = get_tree().get_first_node_in_group("HUD")

	if not hud:
		return

	# 🚫 If day isn't active, hide patience UI
	if not GD.day_started:
		hud.reset_patience()
		return

	# ✅ If a customer still exists, show paused patience
	if GD.saved_customer_order != null:
		hud.stop_patience()

func spawn_next_customer():

	var GD = get_node("/root/GameData")

	# ------------------------------------------------
	# 🔥 CRITICAL FIX
	# If we returned from kitchen, DO NOT spawn.
	# The customer is already on screen.
	# ------------------------------------------------
	if GD.returning_from_kitchen:
		return

	if GD.remaining_customers.is_empty():
		return

	# Wait until animation system is free
	if customer_manager.is_animating:
		await get_tree().process_frame
		spawn_next_customer()
		return

	GD.customer_patience = 100.0
	GD.patience_running = false
	get_tree().call_group("HUD", "reset_patience")

	# ⭐ Get the order WITHOUT removing it yet
	var order: CustomerOrder = GD.remaining_customers[0]

	var tex: Texture2D
	var stage : int = GD.get_character_stage(order.customer_name)

	match order.customer_name:

		"Cyril":
			tex = preload("res://Assets/Customers/Cyril.png")
		"Nestor":
			tex = preload("res://Assets/Customers/Nestor.png")
		"Milan":
			tex = preload("res://Assets/Customers/Milan.png")
		"Nina":
			tex = preload("res://Assets/Customers/Nina.png")
		"Pedro Pan":
			tex = preload("res://Assets/Customers/Pedro Pan.png")
		"Rimo":
			tex = preload("res://Assets/Customers/Rimo.png")
		"Tina":
			tex = preload("res://Assets/Customers/Tina.png")
		"Troy":
			tex = preload("res://Assets/Customers/Troy.png")
		"Yeeha":
			tex = preload("res://Assets/Customers/Yeeha.png")
		"Boba":
			tex = preload("res://Assets/Customers/Boba.png")
		"Bree":
			tex = preload("res://Assets/Customers/Bree.png")
		"Jenna":
			tex = preload("res://Assets/Customers/Jenna.png")
		"Miggy":
			tex = preload("res://Assets/Customers/Miggy.png")
		"Principal":
			tex = preload("res://Assets/Customers/Principal_.png")

		"Leo":
			match stage:
				1: tex = preload("res://Assets/Customers/Special Characters/Leo Current.png")
				2: tex = preload("res://Assets/Customers/Special Characters/Leo Better.png")
				3: tex = preload("res://Assets/Customers/Special Characters/Leo Glowing.png")

		"Maya":
			match stage:
				1: tex = preload("res://Assets/Customers/Special Characters/Maya Current.png")
				2: tex = preload("res://Assets/Customers/Special Characters/Maya Better.png")
				3: tex = preload("res://Assets/Customers/Special Characters/Maya Glowing.png")

		"Norma":
			match stage:
				1: tex = preload("res://Assets/Customers/Special Characters/Norma Current.png")
				2: tex = preload("res://Assets/Customers/Special Characters/Norma Better.png")
				3: tex = preload("res://Assets/Customers/Special Characters/Norma Glowing.png")

	# ⭐ NOW remove from queue AFTER everything is ready
	GD.remaining_customers.pop_front()

	GD.save_customer(order, tex)
	GD.service_state = GameData.ServiceState.CUSTOMER_PRESENT

	customer_manager.spawn_customer(order, tex)


func _on_btn_accept_pressed() -> void:
	pass # Replace with function body.

func _on_btn_continue_pressed() -> void:
	pass # Replace with function body.
	

func _show_special_key_reward():

	var GD = get_node("/root/GameData")

	# Force HUD to update immediately
	get_tree().call_group("HUD", "update_keys", GD.keys + 10)


# ---------------------------------------------------------
# SKIP DAY BUTTON / DEV DEBUG
# ---------------------------------------------------------

# DEFENSIVE FIX: Wipes current gameplay loop and bridges right to results
func _on_skip_day_pressed() -> void:
	print("[DEBUG] Skip Day Button Pressed! Transitioning to EndDayResults...")
	
	var GD = get_node_or_null("/root/GameData")
	if is_instance_valid(GD):
		# Clear customer queue so logic doesn't leak into the next loop
		if "remaining_customers" in GD:
			GD.remaining_customers.clear()
		if GD.has_method("clear_customer"):
			GD.clear_customer()
			
		# Safely reset state tracking variables
		if "service_state" in GD:
			GD.service_state = GameData.ServiceState.IDLE
		if "returning_from_kitchen" in GD:
			GD.returning_from_kitchen = false
		if "day_started" in GD:
			GD.day_started = false

	# Safely transition to Results (UPDATED WITH DEFENSIVE PROGRAMMING)
	var results_path = "res://Scenes/Results/EndDayResults.tscn"
	if has_node("/root/SceneTransition"):
		SceneTransition.fade_to(results_path)
	else:
		if ResourceLoader.exists(results_path):
			get_tree().change_scene_to_file(results_path)
		else:
			printerr("[LobbyCanteen] ERROR: Cannot skip day! File does not exist: ", results_path)
