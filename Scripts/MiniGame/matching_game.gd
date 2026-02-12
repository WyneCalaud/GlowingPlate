extends Control

@export var card_back: Texture2D
@export var card_faces: Array[Texture2D]
@export var exercise_info := {}
@export var exercise_description := {}

# ⭐ NEW DICTIONARY
@export var match_popup_images := {}

@export var preview_time := 5.0
@export var max_hearts := 5

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

# SHUFFLE
@onready var shuffle_overlay := $ShuffleOverlay
@onready var shuffle_grid := $ShuffleOverlay/CardGrid

# RESULT
@onready var result_overlay := $ExerciseResultOverlay
@onready var result_image := $ExerciseResultOverlay/PickedExercise
@onready var result_bg := $ExerciseResultOverlay/Background
@onready var result_label := $ExerciseResultOverlay/ExerciseNameLabel
@onready var result_desc := $ExerciseResultOverlay/ExerciseDescriptionLabel
@onready var name_bg := $ExerciseResultOverlay/NameBG
@onready var btn_continue := $ExerciseResultOverlay/VBoxContainer/ContinueButton
@onready var btn_menu := $ExerciseResultOverlay/VBoxContainer/MainMenuButton

# ⭐ MATCH POPUP
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

	btn_continue.pressed.connect(func(): print("➡ CONTINUE"))
	btn_menu.pressed.connect(func(): print("🏠 MAIN MENU"))

	setup_board()
	update_ui()

	await get_tree().process_frame
	preview_all_cards()

func _on_go_retry():
	get_tree().reload_current_scene()

func _on_go_menu():
	print("🏠 Main Menu pressed")
	# replace later with scene change

func _on_go_skip():
	print("⏭ Skip pressed")


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
	for card in all_cards:
		card.texture_normal = card_values[card]

	await get_tree().create_timer(preview_time).timeout

	for card in all_cards:
		card.texture_normal = card_back

	lock_input = false


func on_card_pressed(card: TextureButton):
	if lock_input or revealed_cards.has(card):
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


# =========================
# GAME OVER
# =========================

func game_over():
	lock_input = true
	game_over_overlay.visible = true


func update_ui():
	score_label.text = "%d" % score
	turns_label.text = "Turns: %d" % turns_taken
