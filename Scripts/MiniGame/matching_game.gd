extends Control

@export var card_back: Texture2D
@export var card_faces: Array[Texture2D]
@export var exercise_info := {}
@export var exercise_description := {}

@export var match_popup_images := {}

@export var preview_time := 6.0
@export var max_hearts := 5
@export var tutorial_preview_time := 12.0

const TOTAL_CARDS := 16
const WIN_SCORE := 8

var revealed_cards: Array[TextureButton] = []
var card_values := {}
var score := 0
var turns_taken := 0
var lock_input := false
var all_cards: Array[TextureButton] = []

var current_hearts := 0
var hearts_original_pos: Vector2
var chosen_exercise: Texture2D

var is_previewing := false

# =========================
# TUTORIAL
# =========================

var is_tutorial := true
var tutorial_state := "intro1"

var tutorial_first_card : TextureButton = null
var tutorial_seen_correct := false
var tutorial_seen_wrong := false
var tutorial_ready_for_final := false

# ⭐ NEW FIX
var tutorial_seen_pointer2 := false

@onready var tutorial_overlay := $TutorialOverlay
@onready var tutorial_step_image := $TutorialOverlay/TutorialStepImage
@onready var tutorial_popup_image := $TutorialOverlay/TutorialPopupImage
@onready var tutorial_popup_image2 := $TutorialOverlay/TutorialPopupImage2
@onready var tutorial_bg := $TutorialOverlay/bg

# =========================
# NORMAL NODES (UNCHANGED)
# =========================

@onready var grid := $Grid
@onready var score_label := $CanvasLayer/ScoreLabel
@onready var turns_label := $CanvasLayer/TurnsLabel
@onready var hearts_container := $HeartsContainer
@onready var heart_bg := $Heartbg

@onready var game_over_overlay := $GameOverOverlay
@onready var go_retry := $GameOverOverlay/VBoxContainer/TryAgainButton
@onready var go_menu := $GameOverOverlay/VBoxContainer/MainMenuButton
@onready var go_skip := $GameOverOverlay/VBoxContainer/SkipButton

@onready var win_overlay := $WinOverlay
@onready var shuffle_overlay := $ShuffleOverlay
@onready var shuffle_grid := $ShuffleOverlay/CardGrid

@onready var result_overlay := $ExerciseResultOverlay
@onready var result_image := $ExerciseResultOverlay/PickedExercise
@onready var result_bg := $ExerciseResultOverlay/Background
@onready var result_label := $ExerciseResultOverlay/ExerciseNameLabel
@onready var result_desc := $ExerciseResultOverlay/ExerciseDescriptionLabel
@onready var name_bg := $ExerciseResultOverlay/NameBG
@onready var btn_continue := $ExerciseResultOverlay/VBoxContainer/ContinueButton
@onready var btn_menu := $ExerciseResultOverlay/VBoxContainer/MainMenuButton

@onready var match_popup := $MatchPopupOverlay
@onready var match_popup_image := $MatchPopupOverlay/MatchPopupImage

func _ready():

	go_retry.pressed.connect(_on_go_retry)
	go_menu.pressed.connect(_on_go_menu)
	go_skip.pressed.connect(_on_go_skip)

	current_hearts = max_hearts
	update_hearts_ui()

	hearts_original_pos = hearts_container.position
	game_over_overlay.visible = false
	win_overlay.visible = false
	shuffle_overlay.visible = false
	result_overlay.visible = false
	match_popup.visible = false

	setup_board()
	update_ui()

	await get_tree().process_frame
	preview_all_cards()

	var GD = get_node("/root/GameData")

	if not GD.matching_tutorial_completed:
		is_tutorial = true
		start_tutorial()
	else:
		is_tutorial = false
		tutorial_overlay.visible = false

	tutorial_step_image.gui_input.connect(_on_tutorial_clicked)
	tutorial_popup_image.gui_input.connect(_on_tutorial_popup_clicked)
	tutorial_popup_image2.gui_input.connect(_on_tutorial_popup2_clicked)

# =========================
# TUTORIAL FLOW
# =========================

func start_tutorial():
	lock_input = true
	tutorial_overlay.visible = true
	$CanvasLayer.visible = false
	grid.visible = false
	tutorial_bg.visible = true
	tutorial_step_image.visible = true
	tutorial_step_image.texture = preload("res://Assets/MiniGame/Tutorial/Cat Intro 1.png")
	tutorial_state = "intro1"

func _on_tutorial_clicked(event):
	if not (event is InputEventMouseButton and event.pressed):
		return

	if tutorial_state == "intro1":
		tutorial_step_image.texture = preload("res://Assets/MiniGame/Tutorial/Cat Intro 2.png")
		tutorial_state = "intro2"
		return

	if tutorial_state == "intro2":
		tutorial_step_image.visible = false
		tutorial_bg.visible = false
		$CanvasLayer.visible = true
		grid.visible = true
		set_background_dim(0.2)
		tutorial_popup_image.texture = preload("res://Assets/MiniGame/Tutorial/Pointer1.png")
		tutorial_popup_image.visible = true
		tutorial_state = "pointer1"

func _on_tutorial_popup_clicked(event):
	if not (event is InputEventMouseButton and event.pressed):
		return

	if tutorial_state == "pointer1":
		tutorial_popup_image.visible = false
		set_background_dim(1.0)
		tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_input = false
		tutorial_state = "wait_first"
		return

	if tutorial_state == "pointer2":
		tutorial_popup_image.visible = false
		lock_input = false
		tutorial_state = "wait_second"
		return

	if tutorial_state == "intro9":
		tutorial_popup_image.visible = false
		if tutorial_seen_correct and tutorial_seen_wrong:
			tutorial_ready_for_final = true
		lock_input = false
		tutorial_state = "wait_first"
		return

	if tutorial_state == "final_extra":
		tutorial_popup_image.visible = false
		end_tutorial()

func _on_tutorial_popup2_clicked(event):
	if not (event is InputEventMouseButton and event.pressed):
		return

	if tutorial_state == "good1":
		tutorial_popup_image2.visible = false
		tutorial_popup_image.texture = preload("res://Assets/MiniGame/Tutorial/Cat Intro 9.png")
		tutorial_popup_image.visible = true
		tutorial_state = "intro9"
		return

	if tutorial_state == "oops1":
		tutorial_popup_image2.position = Vector2(746,232)
		tutorial_popup_image2.texture = preload("res://Assets/MiniGame/Tutorial/Cat Intro 8.png")
		tutorial_state = "oops2"
		return

	if tutorial_state == "oops2":
		tutorial_popup_image2.visible = false
		tutorial_popup_image.texture = preload("res://Assets/MiniGame/Tutorial/Cat Intro 9.png")
		tutorial_popup_image.visible = true
		tutorial_state = "intro9"

func handle_tutorial_progress(card):

	if tutorial_state == "wait_first":

		tutorial_first_card = card
		card.texture_normal = card_values[card]

		revealed_cards.clear()
		revealed_cards.append(card)

		# ⭐ Pointer2 ONLY ONCE
		if not tutorial_seen_pointer2:
			tutorial_seen_pointer2 = true
			lock_input = true
			tutorial_popup_image.texture = preload("res://Assets/MiniGame/Tutorial/Pointer2.png")
			tutorial_popup_image.visible = true
			tutorial_state = "pointer2"
		else:
			lock_input = false
			tutorial_state = "wait_second"

		return


	if tutorial_state == "wait_second":

		card.texture_normal = card_values[card]
		revealed_cards.append(card)

		turns_taken += 1

		if card_values[card] == card_values[tutorial_first_card]:

			score += 1
			tutorial_first_card.disabled = true
			card.disabled = true
			update_ui()

			show_match_popup(card_values[card])

			if not tutorial_seen_correct:
				tutorial_seen_correct = true
				tutorial_popup_image2.position = Vector2(714,460)
				tutorial_popup_image2.texture = preload("res://Assets/MiniGame/Tutorial/Cat Intro 4.png")
				tutorial_popup_image2.visible = true
				tutorial_state = "good1"
				lock_input = true

			elif tutorial_ready_for_final:
				tutorial_popup_image.texture = preload("res://Assets/MiniGame/Tutorial/Cat Intro 11.png")
				tutorial_popup_image.visible = true
				tutorial_state = "final_extra"
				lock_input = true

			else:
				lock_input = false
				tutorial_state = "wait_first"

		else:

			lose_heart()

			await get_tree().create_timer(0.4).timeout
			tutorial_first_card.texture_normal = card_back
			card.texture_normal = card_back

			if not tutorial_seen_wrong:
				tutorial_seen_wrong = true
				tutorial_popup_image2.position = Vector2(746,232)
				tutorial_popup_image2.texture = preload("res://Assets/MiniGame/Tutorial/Cat Intro 7.png")
				tutorial_popup_image2.visible = true
				tutorial_state = "oops1"
				lock_input = true
			else:
				# ⭐ FIX BRICKING
				lock_input = false
				tutorial_state = "wait_first"

		revealed_cards.clear()

func end_tutorial():

	var GD = get_node("/root/GameData")
	GD.matching_tutorial_completed = true   # 👈 ADD THIS

	tutorial_overlay.visible = false
	set_background_dim(1.0)

	is_tutorial = false
	lock_input = false


func _on_go_retry():
	get_tree().reload_current_scene()

func _on_go_menu():
	get_tree().change_scene_to_file("res://Scenes/Main Menu/Main_menu.tscn")

func _on_go_skip():
	var GD = get_node("/root/GameData")

	if GD.current_day >= 2 and GD.current_day <= 5:
		get_tree().change_scene_to_file("res://Scenes/News/news_scene.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")

# =========================
# GAMEPLAY
# =========================

func setup_board():
	var faces := []
	for tex in card_faces:
		faces.append(tex)
		faces.append(tex)
	faces.shuffle()

	for i in range(TOTAL_CARDS):
		var card := TextureButton.new()
		card.texture_normal = card_back
		card.custom_minimum_size = Vector2(160, 160)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		card.ignore_texture_size = true

		grid.add_child(card)
		all_cards.append(card)
		card_values[card] = faces[i]

		card.pressed.connect(func():
			on_card_pressed(card)
		)


func preview_all_cards():

	lock_input = true
	is_previewing = true

	for card in all_cards:
		card.texture_normal = card_values[card]

	var time_to_wait := preview_time
	if is_tutorial:
		time_to_wait = tutorial_preview_time

	await get_tree().create_timer(time_to_wait).timeout

	for card in all_cards:
		card.texture_normal = card_back

	is_previewing = false
	lock_input = false



func on_card_pressed(card: TextureButton):

	# ⭐ HARD BLOCK during preview (no exceptions)
	if is_previewing:
		return

	if lock_input:
		return

	if is_tutorial:
		handle_tutorial_progress(card)
		return

	if revealed_cards.has(card):
		return

	card.texture_normal = card_values[card]
	revealed_cards.append(card)

	if revealed_cards.size() == 2:
		turns_taken += 1
		check_match()



func check_match():
	lock_input = true
	await get_tree().create_timer(0.6).timeout

	var a := revealed_cards[0]
	var b := revealed_cards[1]

	if card_values[a] == card_values[b]:
		score += 1
		a.disabled = true
		b.disabled = true

		show_match_popup(card_values[a]) # ⭐ NEW

		if score >= WIN_SCORE:
			await get_tree().create_timer(1.0).timeout
			win_game()
	else:
		a.texture_normal = card_back
		b.texture_normal = card_back
		lose_heart()

	revealed_cards.clear()
	lock_input = false
	update_ui()


# =========================
# MATCH POPUP
# =========================

func show_match_popup(tex:Texture2D):

	if not match_popup_images.has(tex):
		return

	lock_input = true

	# fade background
	set_background_dim(0.1)

	match_popup.visible = true
	match_popup.modulate.a = 0
	match_popup_image.texture = match_popup_images[tex]

	var tween := create_tween()
	tween.tween_property(match_popup,"modulate:a",1.0,0.25)

	await get_tree().create_timer(2).timeout

	var tween2 := create_tween()
	tween2.tween_property(match_popup,"modulate:a",0.0,0.25)

	await tween2.finished
	match_popup.visible = false

	# restore background
	set_background_dim(1.0)

	lock_input = false



func set_background_dim(alpha: float):
	var tween := create_tween().set_parallel(true)

	tween.tween_property(grid,"modulate:a",alpha,0.25)
	tween.tween_property($CanvasLayer,"modulate:a",alpha,0.25)
	tween.tween_property(hearts_container,"modulate:a",alpha,0.25)
	tween.tween_property(heart_bg,"modulate:a",alpha,0.25)
	tween.tween_property($CanvasLayer/ScoreLabel,"modulate:a",alpha,0.25)
	tween.tween_property($CanvasLayer/TextureRect,"modulate:a",alpha,0.25)
	tween.tween_property($CanvasLayer/Score,"modulate:a",alpha,0.25)
	tween.tween_property($"CanvasLayer/Turns Left","modulate:a",alpha,0.25)
	
	
# =========================
# HEARTS
# =========================

func lose_heart():
	current_hearts -= 1
	update_hearts_ui()
	shake_hearts_container()

	if current_hearts <= 0:
		game_over()
		$CanvasLayer.hide()


func update_hearts_ui():
	for i in range(hearts_container.get_child_count()):
		hearts_container.get_child(i).visible = i < current_hearts


func shake_hearts_container():
	var tween := create_tween()
	hearts_container.position = hearts_original_pos

	tween.tween_property(hearts_container,"position",hearts_original_pos+Vector2(-18,0),0.05)
	tween.tween_property(hearts_container,"position",hearts_original_pos+Vector2(18,0),0.05)
	tween.tween_property(hearts_container,"position",hearts_original_pos,0.06)


# =========================
# WIN → SHUFFLE
# =========================

func win_game():
	lock_input = true
	$CanvasLayer.hide()
	win_overlay.visible = true

	# ✅ GIVE REWARD ONLY IF PLAYER BEAT GAME
	if score >= WIN_SCORE:
		var GD = get_node("/root/GameData")

		GD.add_money(100)
		GD.save_game()

		print("Matching Game Reward: +100 Money")


func _input(event):
	if win_overlay.visible and event is InputEventMouseButton and event.pressed:
		win_overlay.visible = false
		start_shuffle_phase()


# =========================
# SHUFFLE
# =========================

func start_shuffle_phase():
	shuffle_overlay.visible = true
	shuffle_overlay.modulate.a = 1.0

	chosen_exercise = card_faces.pick_random()

	var cards := shuffle_grid.get_children()
	var original_positions := {}

	shuffle_grid.position = Vector2(461,234)
	shuffle_grid.scale = Vector2.ONE
	shuffle_grid.rotation = 0

	for card in cards:
		card.texture = card_back
		card.scale = Vector2.ONE
		card.rotation = 0
		original_positions[card] = card.position


	var scatter := create_tween()
	scatter.set_parallel(true)

	for card in cards:
		var offset := Vector2(randf_range(-40,40),randf_range(-20,20))
		scatter.tween_property(card,"position",original_positions[card]+offset,1)
		scatter.tween_property(card,"scale",Vector2(1.1,1.1),0.4)

	await scatter.finished


	var return_tween := create_tween()
	return_tween.set_parallel(true)

	for card in cards:
		return_tween.tween_property(card,"position",original_positions[card],0.6)
		return_tween.tween_property(card,"scale",Vector2.ONE,0.4)

	await return_tween.finished

	await get_tree().create_timer(0.25).timeout
	show_exercise_result()


# =========================
# RESULT PHASE
# =========================

func show_exercise_result():

	shuffle_grid.modulate.a = 0.2

	result_overlay.visible = true

	result_image.texture = chosen_exercise
	result_label.text = exercise_info.get(chosen_exercise,"Unknown Exercise")
	result_desc.text = exercise_description.get(chosen_exercise,"")

	name_bg.modulate.a = 0
	result_label.modulate.a = 0
	result_desc.modulate.a = 0

	result_image.position = get_viewport_rect().size/2 - result_image.size/2

	await get_tree().create_timer(1.0).timeout

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(result_image,"position",Vector2(168,99),1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(result_bg,"modulate:a",1.0,0.5)
	tween.tween_property(name_bg,"modulate:a",1.0,0.5)
	tween.tween_property(result_label,"modulate:a",1.0,0.5)
	tween.tween_property(result_desc,"modulate:a",1.0,0.7)

func _on_continue_button_pressed() -> void:

	var GD = get_node("/root/GameData")
	GD.save_game()

	# If day 2–5 → go to News
	if GD.current_day >= 2 and GD.current_day <= 5:
		get_tree().change_scene_to_file("res://Scenes/News/news_scene.tscn")
	else:
		# Day 6+ skip news
		get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")

func _on_main_menu_button_pressed() -> void:
	get_node("/root/GameData").save_game()
	get_tree().change_scene_to_file("res://Scenes/Main Menu/Main_menu.tscn")

# =========================
# GAME OVER
# =========================

func game_over():
	lock_input = true
	game_over_overlay.visible = true


func update_ui():
	score_label.text = "%d" % score
	turns_label.text = "Turns: %d" % turns_taken
