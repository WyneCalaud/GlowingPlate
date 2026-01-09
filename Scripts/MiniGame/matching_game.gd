extends Control

@export var card_back: Texture2D
@export var card_faces: Array[Texture2D]  # add images in Inspector

const GRID_SIZE := 4
const TOTAL_CARDS := GRID_SIZE * GRID_SIZE

var revealed_cards: Array[TextureButton] = []
var card_values := {}
var score := 0
var turns_taken := 0
var lock_input := false

@onready var grid := $CenterContainer/Grid
@onready var score_label := $CanvasLayer/ScoreLabel
@onready var turns_label := $CanvasLayer/TurnsLabel


func _ready():
	setup_board()
	update_ui()


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
		card_values[card] = faces[i]

		card.pressed.connect(func():
			on_card_pressed(card)
		)



func on_card_pressed(card: TextureButton):
	if lock_input:
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
	await get_tree().create_timer(0.8).timeout

	var a := revealed_cards[0]
	var b := revealed_cards[1]

	if card_values[a] == card_values[b]:
		score += 1
		a.disabled = true
		b.disabled = true
	else:
		a.texture_normal = card_back
		b.texture_normal = card_back

	revealed_cards.clear()
	lock_input = false
	update_ui()


func update_ui():
	score_label.text = "Score: %d" % score
	turns_label.text = "Turns: %d" % turns_taken
