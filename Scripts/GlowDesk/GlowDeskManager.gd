extends Control

signal closed

@onready var sound_control: Control = $SoundControl
@onready var screen_main: Control = $PracticeOrBrowse
@onready var screen_practice_select: Control = $QuickOrEndlessSelection
@onready var screen_browse_groups: Control = $BrowseGroup
@onready var screen_browse_list: Control = $BrowseGroupSelected
@onready var screen_browse_question: Control = $BrowseQuestionBox
@onready var screen_gameplay: Control = $QuickOrEndlessMode
@onready var screen_countdown: Control = $Countdown

@onready var btn_practice: BaseButton = $PracticeOrBrowse/HBoxContainer/PracticeCard/PracticeButton
@onready var btn_browse: BaseButton = $PracticeOrBrowse/HBoxContainer/BrowseCard/BrowseButton
@onready var btn_quick: BaseButton = $QuickOrEndlessSelection/HBoxContainer/QuickCard/QuickButton
@onready var btn_endless: BaseButton = $QuickOrEndlessSelection/HBoxContainer/EndlessCard/EndlessButton
@onready var btn_group_a: BaseButton = $BrowseGroup/HBoxContainer/GroupACard/GroupAButton
@onready var btn_group_b: BaseButton = $BrowseGroup/HBoxContainer/GroupBCard/GroupBButton
@onready var btn_group_c: BaseButton = $BrowseGroup/HBoxContainer/GroupCCard/GroupCButton

@onready var back_button: BaseButton = $UI/BackButtonImage/TopLeftButton/BackButton
@onready var btn_menu: BaseButton = $UI/TopBarRight2/MenuGroup/MenuButton
@onready var btn_settings: BaseButton = $UI/TopBarRight2/MenuGroup/MenuButton/SettingsButton
@onready var btn_home: BaseButton = $UI/TopBarRight2/MenuGroup/MenuButton/HomeButton

@onready var sign_gameplay: TextureRect = $QuickOrEndlessMode/QuickOrEndlessSign
@onready var lbl_game_q: Label = $QuickOrEndlessMode/AnswerBox/HBoxContainer/QuestionText
@onready var tex_game_q: TextureRect = $QuickOrEndlessMode/AnswerBox/HBoxContainer/QuestionImage
@onready var lbl_timer: Label = $QuickOrEndlessMode/Timer 
@onready var btn_ans_a: BaseButton = $QuickOrEndlessMode/AnswersContainer/A
@onready var btn_ans_b: BaseButton = $QuickOrEndlessMode/AnswersContainer/B
@onready var btn_ans_c: BaseButton = $QuickOrEndlessMode/AnswersContainer/C
@onready var lbl_ans_a: Label = $QuickOrEndlessMode/AnswersContainer/A/AText
@onready var lbl_ans_b: Label = $QuickOrEndlessMode/AnswersContainer/B/BText
@onready var lbl_ans_c: Label = $QuickOrEndlessMode/AnswersContainer/C/CText
@onready var tex_ans_a: TextureRect = $QuickOrEndlessMode/AnswersContainer/A/AImage
@onready var tex_ans_b: TextureRect = $QuickOrEndlessMode/AnswersContainer/B/BImage
@onready var tex_ans_c: TextureRect = $QuickOrEndlessMode/AnswersContainer/C/CImage

@onready var tex_count_icon: TextureRect = $Countdown/HBoxContainer/CountIcon 
@onready var sign_browse_list: TextureRect = $BrowseGroupSelected/GroupSign
@onready var grid_questions: GridContainer = $BrowseGroupSelected/ScrollContainer/GridContainer

@onready var sign_browse_question: TextureRect = $BrowseQuestionBox/GroupSign
@onready var lbl_question_text: Label = $BrowseQuestionBox/AnswerBox/HBoxContainer/QuestionText
@onready var tex_question_image: TextureRect = $BrowseQuestionBox/AnswerBox/HBoxContainer/QuestionImage
@onready var btn_right_answer: TextureButton = $BrowseQuestionBox/AnswersContainer/RightAnswerButton
@onready var lbl_right_answer: Label = $BrowseQuestionBox/AnswersContainer/RightAnswerButton/RightAnswerText
@onready var tex_right_answer: TextureRect = $BrowseQuestionBox/AnswersContainer/RightAnswerButton/RightAnswerImage
@onready var lbl_explanation: Label = $BrowseQuestionBox/AnswersContainer/ExplanationText

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

var question_data: Dictionary = {}
var navigation_stack: Array[Control] = []
var all_screens: Array[Control] = []
var active_tween: Tween
var menu_tween: Tween
var is_transitioning: bool = false 
var is_answering: bool = false 

var current_game_mode: String = ""
var current_score: int = 0
var game_time_left: float = 60.0 
var is_game_active: bool = false 
var correct_answer_text: String = "" 
var current_question_obj: Dictionary = {} 
var game_questions_pool: Array = []
var original_unlocked_pool: Array = [] # ⚠️ NEW: Used to refill Endless mode

func _ready():
	question_data = QuestionDatabase.data
	
	all_screens = [
		screen_main, screen_practice_select, screen_browse_groups, 
		screen_browse_list, screen_browse_question, screen_gameplay, 
		screen_countdown
	]
	
	_fix_mouse_filters()

	if btn_practice: btn_practice.pressed.connect(_on_practice_pressed)
	if btn_browse: btn_browse.pressed.connect(_on_browse_pressed)
	if btn_quick: btn_quick.pressed.connect(func(): _start_gameplay("Quick"))
	if btn_endless: btn_endless.pressed.connect(func(): _start_gameplay("Endless"))
	
	if btn_group_a: btn_group_a.pressed.connect(func(): _open_question_list("A"))
	if btn_group_b: btn_group_b.pressed.connect(func(): _open_question_list("B"))
	if btn_group_c: btn_group_c.pressed.connect(func(): _open_question_list("C"))
	
	if back_button: back_button.pressed.connect(_on_back_pressed)
	if btn_menu:
		btn_menu.pressed.connect(_toggle_menu)
		if btn_settings: btn_settings.visible = false
		if btn_home: btn_home.visible = false
	if btn_home: btn_home.pressed.connect(_on_home_pressed)

	if btn_ans_a: btn_ans_a.pressed.connect(func(): _check_answer(lbl_ans_a.text, btn_ans_a))
	if btn_ans_b: btn_ans_b.pressed.connect(func(): _check_answer(lbl_ans_b.text, btn_ans_b))
	if btn_ans_c: btn_ans_c.pressed.connect(func(): _check_answer(lbl_ans_c.text, btn_ans_c))
	
	navigation_stack.clear()
	call_deferred("_show_only", screen_main, true)

func _process(delta: float):
	if is_game_active and current_game_mode == "Quick":
		game_time_left -= delta
		if lbl_timer:
			var m = int(game_time_left / 60)
			var s = int(game_time_left) % 60
			lbl_timer.text = "%d:%02d" % [m, s]
		if game_time_left <= 0:
			game_time_left = 0
			if lbl_timer: lbl_timer.text = "0:00"
			_game_over()

func _fix_mouse_filters():
	var buttons = [btn_practice, btn_browse, btn_quick, btn_endless, btn_group_a, btn_group_b, btn_group_c, btn_menu]
	for btn in buttons:
		if btn and btn.get_parent() is Control:
			btn.get_parent().mouse_filter = Control.MOUSE_FILTER_IGNORE

func _toggle_menu():
	if not btn_settings or not btn_home: return
	var is_opening = not btn_settings.visible
	var buttons = [btn_settings, btn_home]
	if menu_tween: menu_tween.kill()
	menu_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_opening:
		for btn in buttons:
			btn.visible = true
			menu_tween.tween_property(btn, "modulate:a", 1.0, 0.25)
	else:
		for btn in buttons: menu_tween.tween_property(btn, "modulate:a", 0.0, 0.2)
		menu_tween.chain().tween_callback(func():
			for btn in buttons: btn.visible = false
		)

func _on_home_pressed(): closed.emit()
func _on_practice_pressed(): _change_screen(screen_practice_select)
func _on_browse_pressed(): _change_screen(screen_browse_groups)

func _change_screen(target_screen: Control):
	if is_transitioning: return
	var current = _get_current_screen()
	if current and current != target_screen: navigation_stack.push_back(current)
	_show_only(target_screen)

func _on_back_pressed():
	if is_transitioning: return
	
	# If backing out during a game, cancel the game
	if is_game_active:
		is_game_active = false
		
	if navigation_stack.is_empty():
		closed.emit()
	else:
		var previous_screen = navigation_stack.pop_back()
		_show_only(previous_screen)

func _show_only(target: Control, instant: bool = false):
	if instant:
		if active_tween: active_tween.kill()
		is_transitioning = false
		for screen in all_screens:
			if screen:
				screen.visible = (screen == target)
				screen.modulate.a = 1.0 if (screen == target) else 0.0
		return

	if active_tween: active_tween.kill()
	is_transitioning = true
	active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var current = _get_current_screen()
	if current and current != target:
		active_tween.tween_property(current, "modulate:a", 0.0, 0.25)
		active_tween.tween_callback(func(): current.visible = false).set_delay(0.25)
	if target:
		target.visible = true
		if target.modulate.a > 0.9: target.modulate.a = 0.0 
		active_tween.tween_property(target, "modulate:a", 1.0, 0.25)
	active_tween.chain().tween_callback(func(): is_transitioning = false)

func _get_current_screen() -> Control:
	for screen in all_screens:
		if screen and screen.visible and screen.modulate.a > 0.0:
			return screen
	return null

func _start_gameplay(mode: String):
	if is_transitioning: return
	
	current_game_mode = mode
	current_score = 0
	game_time_left = 60.0
	is_game_active = false 
	game_questions_pool.clear()
	original_unlocked_pool.clear()

	var all_qs = QuestionDatabase.get_all_questions()
	var unlocked_qs = []
	for q in all_qs:
		var id = q.get("id", "??")
		if QuizProgress.is_unlocked(id):
			unlocked_qs.append(q)

	if unlocked_qs.is_empty():
		var target_btn = btn_quick if mode == "Quick" else btn_endless
		if target_btn:
			_shake_locked_btn(target_btn, Color.WHITE)
		return

	original_unlocked_pool = unlocked_qs.duplicate()
	game_questions_pool.append_array(unlocked_qs)
	game_questions_pool.shuffle()

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
	
	# Only start if player didn't hit back during countdown
	if not is_inside_tree() or _get_current_screen() != screen_countdown:
		return
		
	if not navigation_stack.is_empty() and navigation_stack.back() == screen_countdown:
		navigation_stack.pop_back()
		
	_load_next_question()
	_show_only(screen_gameplay)
	is_game_active = true 

func _load_next_question():
	if game_questions_pool.is_empty():
		# ⚠️ FIX: Make Endless Mode truly infinite!
		if current_game_mode == "Endless" and not original_unlocked_pool.is_empty():
			game_questions_pool.append_array(original_unlocked_pool)
			game_questions_pool.shuffle()
		else:
			_game_over()
			return

	var q_data = game_questions_pool.pop_front()
	current_question_obj = q_data 
	correct_answer_text = q_data["ans"]
	
	if lbl_game_q: lbl_game_q.text = q_data["q"]
	if tex_game_q:
		tex_game_q.texture = q_data.get("q_img", null)
		tex_game_q.visible = (tex_game_q.texture != null)
		
	var options = []
	options.append({"text": q_data["ans"], "img": q_data.get("ans_img"), "is_correct": true})
	options.append({"text": q_data.get("wrong1", "Wrong"), "img": q_data.get("wrong1_img"), "is_correct": false})
	options.append({"text": q_data.get("wrong2", "Incorrect"), "img": q_data.get("wrong2_img"), "is_correct": false})
	options.shuffle()
	
	var ui_sets = [
		{"lbl": lbl_ans_a, "tex": tex_ans_a},
		{"lbl": lbl_ans_b, "tex": tex_ans_b},
		{"lbl": lbl_ans_c, "tex": tex_ans_c}
	]
	
	for i in range(3):
		var opt = options[i]
		var set = ui_sets[i]
		
		if set.lbl:
			set.lbl.text = opt.text
			var words = opt.text.strip_edges().split(" ", false)
			var target_size = 30
			if words.size() >= 4 or opt.text.length() > 13:
				target_size = 20
				
			if set.lbl.label_settings:
				var new_settings = set.lbl.label_settings.duplicate()
				new_settings.font_size = target_size
				set.lbl.label_settings = new_settings
			else:
				set.lbl.add_theme_font_size_override("font_size", target_size)
		
		if set.tex:
			set.tex.texture = opt.img
			set.tex.visible = (opt.img != null)

func _check_answer(selected_text: String, btn_node: BaseButton):
	if is_transitioning or is_answering or not is_game_active: return
	is_answering = true 
	
	var is_correct = (selected_text == correct_answer_text)
	var q_id = current_question_obj.get("id")
	
	if current_game_mode == "Quick" and q_id and QuizProgress.is_unlocked(q_id):
		QuizProgress.record_attempt(q_id, is_correct, GameData.current_day)
		GameData.save_game()

	btn_node.pivot_offset = btn_node.size / 2
	
	if is_correct:
		current_score += 10
		var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		btn_node.modulate = Color(0.2, 1.0, 0.2, 1.0)
		tween.tween_property(btn_node, "scale", Vector2(1.1, 1.1), 0.2)
		tween.tween_property(btn_node, "scale", Vector2.ONE, 0.2)
		
		await get_tree().create_timer(0.5).timeout
		
		# ⚠️ CRITICAL FIX: Prevent crash if player exits mid-timer
		if not is_inside_tree() or not is_game_active: return 
		
		btn_node.modulate = Color.WHITE
		is_answering = false
		_load_next_question()
	else:
		var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		btn_node.modulate = Color(1.0, 0.2, 0.2, 1.0) 
		
		tween.tween_property(btn_node, "rotation_degrees", 5.0, 0.05)
		tween.tween_property(btn_node, "rotation_degrees", -5.0, 0.1)
		tween.tween_property(btn_node, "rotation_degrees", 0.0, 0.05)
		
		await get_tree().create_timer(0.5).timeout
		
		# ⚠️ CRITICAL FIX: Prevent crash if player exits mid-timer
		if not is_inside_tree() or not is_game_active: return
		
		btn_node.modulate = Color.WHITE
		is_answering = false
		_load_next_question()

func _game_over():
	is_game_active = false
	_change_screen(screen_practice_select)

func _open_question_list(group_id: String):
	if is_transitioning: return
	
	var tex = null
	if group_id == "A": tex = sign_group_a
	elif group_id == "B": tex = sign_group_b
	elif group_id == "C": tex = sign_group_c
	if sign_browse_list and tex: sign_browse_list.texture = tex
	
	var questions = question_data.get(group_id, [])
	
	if grid_questions.get_child_count() == 0:
		return
		
	var template_btn = grid_questions.get_child(0)
	template_btn.visible = false
	
	for child in grid_questions.get_children():
		if child != template_btn and not child.is_queued_for_deletion():
			child.queue_free()
	
	for i in range(questions.size()):
		var data = questions[i]
		var new_btn = template_btn.duplicate()
		
		var is_unlocked = QuizProgress.is_unlocked(data.get("id", ""))
		
		new_btn.visible = true
		grid_questions.add_child(new_btn)
		
		var lbl = new_btn.get_node_or_null("QuestionBox/QuestionText")
		if lbl: 
			lbl.text = data["q"] if is_unlocked else "Locked"
			
		if is_unlocked:
			new_btn.modulate = Color.WHITE
		else:
			new_btn.modulate = Color(0.5, 0.5, 0.5, 1.0) 
			
		var clickable_node = new_btn
		if new_btn is BaseButton: pass
		elif new_btn.has_node("Button"): clickable_node = new_btn.get_node("Button")
		elif new_btn.has_node("QuestionBox"):
			var qbox = new_btn.get_node("QuestionBox")
			if qbox is BaseButton: clickable_node = qbox
				
		clickable_node.pressed.connect(func(): _on_question_clicked(group_id, i, is_unlocked, new_btn))

	_change_screen(screen_browse_list)

func _on_question_clicked(group_id: String, index: int, is_unlocked: bool = true, btn_node: Control = null):
	if is_transitioning: return
	
	if not is_unlocked:
		if btn_node: _shake_locked_btn(btn_node) 
		return
		
	var questions = question_data.get(group_id, [])
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
		
	if lbl_right_answer: 
		var ans_str: String = data["ans"]
		lbl_right_answer.text = ans_str
		
		var words = ans_str.strip_edges().split(" ", false)
		var target_size = 30
		if words.size() >= 4 or ans_str.length() > 13:
			target_size = 20
		
		if lbl_right_answer.label_settings:
			var new_settings = lbl_right_answer.label_settings.duplicate()
			new_settings.font_size = target_size
			lbl_right_answer.label_settings = new_settings
		else:
			lbl_right_answer.add_theme_font_size_override("font_size", target_size)
			
	if tex_right_answer:
		tex_right_answer.texture = data.get("ans_img")
		tex_right_answer.visible = (tex_right_answer.texture != null)
	if lbl_explanation: lbl_explanation.text = data["expl"]
	
	_change_screen(screen_browse_question)

func _shake_locked_btn(node: Control, return_color: Color = Color(0.5, 0.5, 0.5, 1.0)):
	var shake_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	node.pivot_offset = node.size / 2
	shake_tween.tween_property(node, "rotation_degrees", 5.0, 0.05)
	shake_tween.tween_property(node, "rotation_degrees", -5.0, 0.1)
	shake_tween.tween_property(node, "rotation_degrees", 0.0, 0.05)
	
	var color_tween = create_tween()
	color_tween.tween_property(node, "modulate", Color(0.8, 0.3, 0.3, 1.0), 0.1)
	color_tween.tween_property(node, "modulate", return_color, 0.2)

func _on_settings_button_pressed() -> void:
	if sound_control:
		sound_control.visible = true
		sound_control.move_to_front()
	else:
		printerr("GlowDeskManager: SoundControl node is missing!")

func _on_home_button_pressed() -> void:
	pass
