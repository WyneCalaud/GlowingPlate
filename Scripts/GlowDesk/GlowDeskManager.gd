extends Control

# --- SIGNALS ---
signal closed

# --- SCREENS ---
@onready var screen_main: Control = $PracticeOrBrowse
@onready var screen_practice_select: Control = $QuickOrEndlessSelection
@onready var screen_browse_groups: Control = $BrowseGroup
@onready var screen_browse_list: Control = $BrowseGroupSelected
@onready var screen_browse_question: Control = $BrowseQuestionBox
@onready var screen_gameplay: Control = $QuickOrEndlessMode
@onready var screen_countdown: Control = $Countdown

# --- BUTTONS (Main) ---
@onready var btn_practice: BaseButton = $PracticeOrBrowse/HBoxContainer/PracticeCard/PracticeButton
@onready var btn_browse: BaseButton = $PracticeOrBrowse/HBoxContainer/BrowseCard/BrowseButton

# --- BUTTONS (Practice) ---
@onready var btn_quick: BaseButton = $QuickOrEndlessSelection/HBoxContainer/QuickCard/QuickButton
@onready var btn_endless: BaseButton = $QuickOrEndlessSelection/HBoxContainer/EndlessCard/EndlessButton

# --- BUTTONS (Browse) ---
@onready var btn_group_a: BaseButton = $BrowseGroup/HBoxContainer/GroupACard/GroupAButton
@onready var btn_group_b: BaseButton = $BrowseGroup/HBoxContainer/GroupBCard/GroupBButton
@onready var btn_group_c: BaseButton = $BrowseGroup/HBoxContainer/GroupCCard/GroupCButton

# --- UI & HUD ---
@onready var game_hud: CanvasLayer = $GameHUD 
@onready var back_button: BaseButton = $UI/BackButtonImage/TopLeftButton/BackButton

# --- GAMEPLAY ELEMENTS ---
@onready var sign_gameplay: TextureRect = $QuickOrEndlessMode/QuickOrEndlessSign
@onready var lbl_game_q: Label = $QuickOrEndlessMode/AnswerBox/HBoxContainer/QuestionText
@onready var tex_game_q: TextureRect = $QuickOrEndlessMode/AnswerBox/HBoxContainer/QuestionImage
@onready var lbl_timer: Label = $QuickOrEndlessMode/Timer 

# Answer Buttons & Labels
@onready var btn_ans_a: BaseButton = $QuickOrEndlessMode/AnswersContainer/A
@onready var btn_ans_b: BaseButton = $QuickOrEndlessMode/AnswersContainer/B
@onready var btn_ans_c: BaseButton = $QuickOrEndlessMode/AnswersContainer/C
@onready var lbl_ans_a: Label = $QuickOrEndlessMode/AnswersContainer/A/AText
@onready var lbl_ans_b: Label = $QuickOrEndlessMode/AnswersContainer/B/BText
@onready var lbl_ans_c: Label = $QuickOrEndlessMode/AnswersContainer/C/CText
@onready var tex_ans_a: TextureRect = $QuickOrEndlessMode/AnswersContainer/A/AImage
@onready var tex_ans_b: TextureRect = $QuickOrEndlessMode/AnswersContainer/B/BImage
@onready var tex_ans_c: TextureRect = $QuickOrEndlessMode/AnswersContainer/C/CImage

# Countdown
@onready var tex_count_icon: TextureRect = $Countdown/HBoxContainer/CountIcon 

# Browse Elements
@onready var sign_browse_list: TextureRect = $BrowseGroupSelected/GroupSign
@onready var grid_questions: GridContainer = $BrowseGroupSelected/GridContainer
@onready var sign_browse_question: TextureRect = $BrowseQuestionBox/GroupSign
@onready var lbl_question_text: Label = $BrowseQuestionBox/AnswerBox/HBoxContainer/QuestionText
@onready var tex_question_image: TextureRect = $BrowseQuestionBox/AnswerBox/HBoxContainer/QuestionImage
@onready var btn_right_answer: TextureButton = $BrowseQuestionBox/AnswersContainer/RightAnswerButton
@onready var lbl_right_answer: Label = $BrowseQuestionBox/AnswersContainer/RightAnswerButton/RightAnswerText
@onready var tex_right_answer: TextureRect = $BrowseQuestionBox/AnswersContainer/RightAnswerButton/RightAnswerImage
@onready var lbl_explanation: Label = $BrowseQuestionBox/AnswersContainer/ExplanationText

# --- TEXTURES ---
@export_group("Signs")
@export var sign_quick: Texture2D
@export var sign_endless: Texture2D
@export var sign_group_a: Texture2D
@export var sign_group_b: Texture2D
@export var sign_group_c: Texture2D

@export_group("Countdown")
@export var tex_count_3: Texture2D
@export var tex_count_2: Texture2D
@export var tex_count_1: Texture2D

# --- STATE VARIABLES ---
var navigation_stack: Array[Control] = []
var all_screens: Array[Control] = []
var active_tween: Tween
var is_transitioning: bool = false 
var original_panel_pos: Vector2 

# Gameplay State
var current_game_mode: String = ""
var current_score: int = 0
var current_lives: int = 3
var game_time_left: float = 60.0 
var is_game_active: bool = false 
var correct_answer_text: String = "" 
var current_question_obj: Dictionary = {} 
var game_questions_pool: Array = []
var answer_buttons_list: Array = [] 

# --- DATA ---
var answered_questions_ref: Dictionary = {} 

func _ready():
	# Capture original position for shake animations
	if screen_gameplay:
		original_panel_pos = screen_gameplay.position
	
	# Populate screen list
	all_screens = [
		screen_main, screen_practice_select, screen_browse_groups, 
		screen_browse_list, screen_browse_question, screen_gameplay, 
		screen_countdown
	]
	
	# Set Pivot Offset to Center for Popping Animation
	for screen in all_screens:
		if screen:
			screen.call_deferred("set_pivot_offset", screen.size / 2)
	
	# Helper list for animations
	answer_buttons_list = [
		{"btn": btn_ans_a, "lbl": lbl_ans_a, "tex": tex_ans_a},
		{"btn": btn_ans_b, "lbl": lbl_ans_b, "tex": tex_ans_b},
		{"btn": btn_ans_c, "lbl": lbl_ans_c, "tex": tex_ans_c}
	]
	
	_fix_mouse_filters()
	_sync_user_progress()
	_setup_hud() # Configure the GameHUD

	# Connect Buttons
	if btn_practice: btn_practice.pressed.connect(_on_practice_pressed)
	if btn_browse: btn_browse.pressed.connect(_on_browse_pressed)
	
	if btn_quick: btn_quick.pressed.connect(func(): _on_mode_button_pressed("Quick", btn_quick))
	if btn_endless: btn_endless.pressed.connect(func(): _on_mode_button_pressed("Endless", btn_endless))
	
	if btn_group_a: btn_group_a.pressed.connect(func(): _open_question_list("A"))
	if btn_group_b: btn_group_b.pressed.connect(func(): _open_question_list("B"))
	if btn_group_c: btn_group_c.pressed.connect(func(): _open_question_list("C"))
	
	if back_button: back_button.pressed.connect(_on_back_pressed)
	
	if btn_ans_a: btn_ans_a.pressed.connect(_check_answer.bind(0))
	if btn_ans_b: btn_ans_b.pressed.connect(_check_answer.bind(1))
	if btn_ans_c: btn_ans_c.pressed.connect(_check_answer.bind(2))
	
	navigation_stack.clear()
	call_deferred("_show_only", screen_main, true)

func _exit_tree():
	if active_tween: active_tween.kill()

func _setup_hud():
	# Configures the GameHUD to show only Money and Menu groups
	if not game_hud:
		printerr("GlowDeskManager: GameHUD node not found! Make sure to instantiate it.")
		return
	
	# Force visibility ON (in case hidden in editor)
	game_hud.visible = true
	
	# 1. Access the main HUD Control container
	# Note: GameHUD is a CanvasLayer, its child is 'HUDControl'
	var hud_control = game_hud.get_node_or_null("HUDControl")
	if not hud_control:
		printerr("GlowDeskManager: HUDControl not found in GameHUD!")
		return
	
	# Force Control visibility ON
	hud_control.visible = true
		
	# 2. Hide TopBarLeft (Time/Happiness)
	var top_left = hud_control.get_node_or_null("TopBarLeft")
	if top_left:
		top_left.visible = false
	
	# 3. Configure TopBarRight (Money/Keys/Menu)
	var top_right = hud_control.get_node_or_null("TopBarRight")
	if top_right:
		top_right.visible = true
		
		# Hide Keys, Keep Money and Menu
		var key_group = game_hud.find_child("KeyGroup", true, false)
		if key_group: key_group.visible = false
		
		var money_group = game_hud.find_child("MoneyGroup", true, false)
		if money_group: money_group.visible = true
		
		var menu_group = game_hud.find_child("MenuGroup", true, false)
		if menu_group: menu_group.visible = true
	
	# 4. Hide other panels if they exist
	var sound_control = hud_control.get_node_or_null("SoundControl")
	if sound_control: sound_control.visible = false
	
	var bottom_right = hud_control.get_node_or_null("BottomRight")
	if bottom_right: bottom_right.visible = false

	# 5. OVERRIDE Home Button behavior
	# GameHUD connects it to scene change. We want to disconnect that and use our signal.
	var home_btn = game_hud.find_child("HomeButton", true, false)
	if home_btn:
		# Disconnect ALL existing connections (specifically GameHUD's own logic)
		var connections = home_btn.get_signal_connection_list("pressed")
		for conn in connections:
			home_btn.disconnect("pressed", conn.callable)
			
		# Connect to our local handler
		if not home_btn.pressed.is_connected(_on_home_pressed):
			home_btn.pressed.connect(_on_home_pressed)

func _sync_user_progress():
	if QuizSystem:
		answered_questions_ref = QuizSystem.quiz_progress
	else:
		printerr("GlowDeskManager: QuizSystem Global not found!")

func _process(delta: float):
	if is_game_active and current_game_mode == "Quick":
		game_time_left -= delta
		if lbl_timer:
			var m = int(game_time_left / 60)
			var s = int(game_time_left) % 60
			var new_text = "%d:%02d" % [m, s]
			if lbl_timer.text != new_text:
				lbl_timer.text = new_text
				
		if game_time_left <= 0:
			game_time_left = 0
			if lbl_timer: lbl_timer.text = "0:00"
			_game_over()

func _fix_mouse_filters():
	var buttons = [btn_practice, btn_browse, btn_quick, btn_endless, btn_group_a, btn_group_b, btn_group_c]
	for btn in buttons:
		if btn and btn.get_parent() is Control:
			btn.get_parent().mouse_filter = Control.MOUSE_FILTER_IGNORE

# --- UI LOGIC ---

func _on_home_pressed():
	# Called when GameHUD Home Button is clicked (after override)
	closed.emit()

func _on_practice_pressed(): _change_screen(screen_practice_select)
func _on_browse_pressed(): _change_screen(screen_browse_groups)

# --- NAVIGATION & TRANSITIONS ---

func _change_screen(target_screen: Control):
	if is_transitioning: return
	var current = _get_current_screen()
	if current and current != target_screen: navigation_stack.push_back(current)
	_show_only(target_screen)

func _on_back_pressed():
	if is_transitioning: return
	if navigation_stack.is_empty():
		closed.emit()
	else:
		var previous_screen = navigation_stack.pop_back()
		_show_only(previous_screen)

func _show_only(target: Control, instant: bool = false):
	# INSTANT MODE (Startup)
	if instant:
		if active_tween: active_tween.kill()
		is_transitioning = false
		for screen in all_screens:
			if screen:
				screen.visible = (screen == target)
				screen.modulate.a = 1.0 if (screen == target) else 0.0
				screen.scale = Vector2.ONE
		return

	# POP ANIMATION MODE
	if active_tween: active_tween.kill()
	is_transitioning = true
	
	# Use TRANS_BACK for that "Pop" overshoot effect
	active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var current = _get_current_screen()
	
	# 1. Animate OUT (Current)
	if current and current != target:
		if is_instance_valid(current):
			current.pivot_offset = current.size / 2
			active_tween.tween_property(current, "scale", Vector2(0.9, 0.9), 0.2)
			active_tween.tween_property(current, "modulate:a", 0.0, 0.15)
			active_tween.tween_callback(func(): current.visible = false).set_delay(0.2)

	# 2. Animate IN (Target)
	if target and is_instance_valid(target):
		target.visible = true
		target.pivot_offset = target.size / 2
		
		if target.modulate.a > 0.9: 
			target.modulate.a = 0.0
			target.scale = Vector2(0.8, 0.8)
		
		active_tween.tween_property(target, "scale", Vector2.ONE, 0.3)
		active_tween.tween_property(target, "modulate:a", 1.0, 0.2)

	active_tween.chain().tween_callback(func(): is_transitioning = false)

func _get_current_screen() -> Control:
	for screen in all_screens:
		if screen and screen.visible and screen.modulate.a > 0.0:
			return screen
	return null

# --- GAMEPLAY LOGIC ---

func _on_mode_button_pressed(mode: String, btn_ref: BaseButton):
	if is_transitioning: return
	
	_sync_user_progress()
	
	if answered_questions_ref.is_empty():
		print("LOCKED: No questions answered yet!")
		_animate_button_error(btn_ref)
		return
		
	_start_gameplay(mode)

func _start_gameplay(mode: String):
	current_game_mode = mode
	current_score = 0
	current_lives = 3
	game_time_left = 60.0
	is_game_active = false 
	game_questions_pool.clear()

	var all_qs = QuestionDatabase.get_all_questions()
	
	for q in all_qs:
		var q_id = q.get("id", "??")
		if answered_questions_ref.has(q_id):
			game_questions_pool.append(q)
	
	game_questions_pool.shuffle()
	
	if game_questions_pool.is_empty():
		return

	if mode == "Quick":
		if sign_gameplay and sign_quick: sign_gameplay.texture = sign_quick
		if lbl_timer: lbl_timer.visible = true; lbl_timer.text = "1:00"
	elif mode == "Endless":
		if sign_gameplay and sign_endless: sign_gameplay.texture = sign_endless
		if lbl_timer: lbl_timer.visible = false

	_change_screen(screen_countdown)
	if tex_count_icon:
		if tex_count_3: tex_count_icon.texture = tex_count_3; await get_tree().create_timer(1.0).timeout
		if tex_count_2: tex_count_icon.texture = tex_count_2; await get_tree().create_timer(1.0).timeout
		if tex_count_1: tex_count_icon.texture = tex_count_1; await get_tree().create_timer(1.0).timeout
	else:
		await get_tree().create_timer(3.0).timeout
	
	if not navigation_stack.is_empty() and navigation_stack.back() == screen_countdown:
		navigation_stack.pop_back()
		
	_load_next_question()
	_show_only(screen_gameplay)
	is_game_active = true 

func _load_next_question():
	if game_questions_pool.is_empty():
		_game_over()
		return

	var q_data = game_questions_pool.pop_front()
	if current_game_mode == "Endless":
		game_questions_pool.append(q_data)
		
	current_question_obj = q_data 
	correct_answer_text = q_data["ans"]
	
	if lbl_game_q: lbl_game_q.text = q_data["q"]
	if tex_game_q:
		tex_game_q.texture = q_data.get("q_img", null)
		tex_game_q.visible = (tex_game_q.texture != null)
		
	var options = []
	options.append({ "text": q_data["ans"], "img": q_data.get("ans_img"), "is_correct": true })
	options.append({ "text": q_data.get("wrong1", "Wrong"), "img": q_data.get("wrong1_img"), "is_correct": false })
	options.append({ "text": q_data.get("wrong2", "Incorrect"), "img": q_data.get("wrong2_img"), "is_correct": false })
	options.shuffle()
	
	for i in range(3):
		var opt = options[i]
		var ui = answer_buttons_list[i]
		
		ui.btn.visible = true
		ui.btn.disabled = false
		ui.btn.modulate = Color.WHITE
		ui.btn.scale = Vector2.ONE
		ui.btn.rotation_degrees = 0
		ui.btn.pivot_offset = ui.btn.size / 2
		
		if ui.lbl: ui.lbl.text = opt.text
		if ui.tex:
			ui.tex.texture = opt.img
			ui.tex.visible = (opt.img != null)

func _check_answer(btn_index: int):
	if is_transitioning: return
	is_transitioning = true 
	
	var ui = answer_buttons_list[btn_index]
	var selected_text = ui.lbl.text
	var is_correct = (selected_text == correct_answer_text)

	var feedback_tween = create_tween().set_parallel(true)
	
	for i in range(3):
		var item = answer_buttons_list[i]
		item.btn.disabled = true
		if item.lbl.text == correct_answer_text:
			item.btn.modulate = Color.GREEN
		elif i == btn_index and not is_correct:
			item.btn.modulate = Color.RED

	if is_correct:
		print("Correct!")
		current_score += 10
		_animate_correct_feedback(btn_index, feedback_tween)
	else:
		print("Wrong!")
		_animate_incorrect_feedback(btn_index, feedback_tween)
		if current_game_mode == "Endless":
			current_lives -= 1

	await get_tree().create_timer(1.5).timeout
	if not is_instance_valid(self): return
	
	is_transitioning = false 
	
	if current_game_mode == "Endless" and current_lives <= 0:
		_game_over()
	else:
		_load_next_question()

# --- ANIMATIONS ---

func _animate_button_error(btn: BaseButton):
	if not btn: return
	
	# FIX: Prevent spam clicking from locking the button in Red state
	if btn.has_meta("is_animating_error") and btn.get_meta("is_animating_error"):
		return
		
	btn.set_meta("is_animating_error", true)
	
	var tween = create_tween()
	# Explicitly return to White to prevent getting stuck
	var target_color = Color.WHITE 
	
	btn.pivot_offset = btn.size / 2
	
	tween.tween_property(btn, "modulate", Color.RED, 0.1)
	
	for i in range(4):
		tween.tween_property(btn, "rotation_degrees", 3.0, 0.05)
		tween.tween_property(btn, "rotation_degrees", -3.0, 0.05)
	
	tween.tween_property(btn, "rotation_degrees", 0.0, 0.05)
	tween.tween_property(btn, "modulate", target_color, 0.2)
	
	# Unlock when done
	tween.tween_callback(func(): btn.set_meta("is_animating_error", false))

func _animate_correct_feedback(idx: int, tween: Tween):
	var btn = answer_buttons_list[idx].btn
	if not is_instance_valid(btn): return
	tween.tween_property(btn, "scale", Vector2.ONE * 1.1, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(btn, "scale", Vector2.ONE, 0.2)

func _animate_incorrect_feedback(idx: int, tween: Tween):
	var btn = answer_buttons_list[idx].btn
	if not is_instance_valid(btn): return
	
	var shake_tween = create_tween()
	for i in range(6):
		var offset = original_panel_pos + Vector2(randf_range(-10, 10), randf_range(-5, 5))
		shake_tween.tween_property(screen_gameplay, "position", offset, 0.05)
	shake_tween.tween_property(screen_gameplay, "position", original_panel_pos, 0.05)
	
	var vib_tween = create_tween()
	for i in range(4):
		vib_tween.tween_property(btn, "rotation_degrees", 3.0, 0.05)
		vib_tween.tween_property(btn, "rotation_degrees", -3.0, 0.05)
	vib_tween.tween_property(btn, "rotation_degrees", 0.0, 0.05)

func _game_over():
	is_game_active = false
	print("Game Over. Score: ", current_score)
	_change_screen(screen_practice_select)

# --- BROWSE LOGIC (Strict Lock) ---

func _open_question_list(group_id: String):
	if is_transitioning: return
	_sync_user_progress()
	
	var tex = null
	if group_id == "A": tex = sign_group_a
	elif group_id == "B": tex = sign_group_b
	elif group_id == "C": tex = sign_group_c
	if sign_browse_list and tex: sign_browse_list.texture = tex
	
	var questions = QuestionDatabase.data.get(group_id, [])
	var buttons = grid_questions.get_children()
	
	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn is TextureButton or btn is BaseButton:
			if btn.pressed.is_connected(_on_question_clicked):
				btn.pressed.disconnect(_on_question_clicked)
			var lbl = btn.get_node_or_null("QuestionText")
			
			if i < questions.size():
				var q_data = questions[i]
				var q_id = q_data["id"]
				
				if answered_questions_ref.has(q_id):
					if lbl: lbl.text = q_data["q"]
					btn.disabled = false
					btn.modulate = Color.WHITE
					btn.pressed.connect(_on_question_clicked.bind(group_id, i))
				else:
					if lbl: lbl.text = "Locked"
					btn.disabled = true
					btn.modulate = Color(0.5, 0.5, 0.5, 0.8)
			else:
				if lbl: lbl.text = "---"
				btn.disabled = true
				btn.modulate = Color(0.3, 0.3, 0.3, 0.5)

	_change_screen(screen_browse_list)

func _on_question_clicked(group_id: String, index: int):
	if is_transitioning: return
	var questions = QuestionDatabase.data.get(group_id, [])
	if index >= questions.size(): return
	var data = questions[index]
	
	var tex = null
	if group_id == "A": tex = sign_group_a
	elif group_id == "B": tex = sign_group_b
	elif group_id == "C": tex = sign_group_c
	if sign_browse_question and tex: sign_browse_question.texture = tex
	
	if lbl_question_text: lbl_question_text.text = data["q"]
	if tex_question_image:
		tex_question_image.texture = data.get("q_img")
		tex_question_image.visible = (tex_question_image.texture != null)
	if lbl_right_answer: lbl_right_answer.text = data["ans"]
	if tex_right_answer:
		tex_right_answer.texture = data.get("ans_img")
		tex_right_answer.visible = (tex_right_answer.texture != null)
	if lbl_explanation: lbl_explanation.text = data["expl"]
	
	_change_screen(screen_browse_question)
