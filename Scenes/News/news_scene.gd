extends Control

var current_slide := 0
var intro_done := false

@onready var plate = $Plate
@onready var slide_image = $SlideImage
@onready var dialogue_text = $DialogueBox/DialogueText
@onready var btn_next = $DialogueBox/BtnNext
@onready var gns = $GlowNewsStation
@onready var news_intro_sfx = $NewsIntroSFX

var typing_speed := 0.03
var is_typing := false
var full_text := ""
var typing_tween: Tween

# =========================
# NEWS DATA (MULTI-DAY SYSTEM)
# =========================

var slides = []

var all_news = {

	2: [
		{
			"image": preload("res://Assets/News/oneone.png"),
			"text": "Hello, students! Welcome to Glow News Station"
		},
		{
			"image": preload("res://Assets/News/onetwo.png"),
			"text": "Big news! today we're learning about Pinggang Pinoy"
		},
		{
			"image": preload("res://Assets/News/onethree.png"),
			"text": "Teachers report higher energy levels."
		},
		{
			"image": preload("res://Assets/News/onefour.png"),
			"text": "It’s a simple guide that helps us build a healthy meal."
		},
		{
			"image": preload("res://Assets/News/onefive.png"),
			"text": "It includes Go, Grow, Glow foods, and of course, water!"
		},
		{
			"image": preload("res://Assets/News/onesix.png"),
			"text": "It shows us what kind of foods belong on our plate…"
		},
		{
			"image": preload("res://Assets/News/oneseven.png"),
			"text": "…and how much we should eat!"
		},
		{
			"image": preload("res://Assets/News/oneeight.png"),
			"text": "When our plate is balanced, our body stays healthy and happy!"
		},
		{
			"image": preload("res://Assets/News/onenine.png"),
			"text": "Plus, drinking water is one of the simplest 
			thing you can do to be healthier"
		},
		{
			"image": preload("res://Assets/News/oneten.png"),
			"text": "It also helps with digestion and"
		},
		{
			"image": preload("res://Assets/News/oneeleven.png"),
			"text": "getting rid of waste from your body"
		},
		{
			"image": preload("res://Assets/News/onetwelve.png"),
			"text": "That’s all for today. Have a glowing day!"
		}
	],

	3: [
		{
			"image": preload("res://Assets/News/twoone.png"),
			"text": "Welcome back to Glow News Station!"
		},
		{
			"image": preload("res://Assets/News/twotwo.png"),
			"text": "Last time, we introduced Pinggang Pinoy!"
		},
		{
			"image": preload("res://Assets/News/twothree.png"),
			"text": "Today, we’re talking about Go foods"
		},
		{
			"image": preload("res://Assets/News/twofour.png"),
			"text": "Go foods like rice, noodles, 
			bread, or corn"
		},
		{
			"image": preload("res://Assets/News/twofive.png"),
			"text": "are rich in CARBOHYDRATES"
		},
		{
			"image": preload("res://Assets/News/twosix.png"),
			"text": "In short, CARBS."
		},
		{
			"image": preload("res://Assets/News/twoseventothirteen.png"),
			"text": "Carbs is our main source of energy to 
			run, play, and even study!"
		},
		{
			"image": preload("res://Assets/News/twoseventothirteen.png"),
			"text": "Some carbs give quick energy,
			like sugar"
		},
		{
			"image": preload("res://Assets/News/twoseventothirteen.png"),
			"text": "Others give steady energy, 
			like starch"
		},
		{
			"image": preload("res://Assets/News/twoseventothirteen.png"),
			"text": "And some have fiber that help 
			keep you full for longer."
		},
		{
			"image": preload("res://Assets/News/twoseventothirteen.png"),
			"text": "Whole grains and root crops are 
			great energy foods."
		},
		{
			"image": preload("res://Assets/News/twoseventothirteen.png"),
			"text": "Examples are oats, brown rice, 
			sweet potato, and cassava."
		},
		{
			"image": preload("res://Assets/News/twoseventothirteen.png"),
			"text": "Make sure to check your almanac 
			for more info!"
		},
		{
			"image": preload("res://Assets/News/twofourteen.png"),
			"text": "That’s all for today. Have a glowing day!"
		},
	],

	4: [
		{
			"image": preload("res://Assets/News/threeone.png"),
			"text": "Hello, students! Welcome to Glow News Station"
		},
		{
			"image": preload("res://Assets/News/threetwo.png"),
			"text": "Last time we talked about Go Foods"
		},
		{
			"image": preload("res://Assets/News/threethree.png"),
			"text": "Today, we’re talking about Grow foods!"
		},
		{
			"image": preload("res://Assets/News/threefour.png"),
			"text": "Grow foods like chicken, fish,
			egg, and milk...."
		},
		{
			"image": preload("res://Assets/News/threefive.png"),
			"text": "are rich in PROTEIN"
		},
		{
			"image": preload("res://Assets/News/threesix.png"),
			"text": "Protein help repair and build strong
			muscles for your body."
		},
		{
			"image": preload("res://Assets/News/threeseventonine.png"),
			"text": "Grow foods don’t always have to be meat
			or come from animals."
		},
		{
			"image": preload("res://Assets/News/threeseventonine.png"),
			"text": "Plant foods like legumes are Grow foods too!"
		},
		{
			"image": preload("res://Assets/News/threeseventonine.png"),
			"text": "Examples can be munggo, red beans,
			chickpeas, and even peanuts"
		},
		{
			"image": preload("res://Assets/News/threeten.png"),
			"text": "Make sure to check your almanac 
			for more info!"
		},
		{
			"image": preload("res://Assets/News/threeone.png"),
			"text": "That’s all for today. Have a glowing day!"
		}
	],

	5: [
		{
			"image": preload("res://Assets/News/threeone.png"),
			"text": "Hello, students! Welcome to Glow News Station"
		},
		{
			"image": preload("res://Assets/News/threethree.png"),
			"text": "Last time, we talked about Grow foods"
		},
		{
			"image": preload("res://Assets/News/fourthree.png"),
			"text": "Today we’re talking about Glow foods, 
			which are fruits and vegetables"
		},
		{
			"image": preload("res://Assets/News/fourfour.png"),
			"text": "Vegetables like carrots, malunggay, 
			tomato, eggplant, and... "
		},
		{
			"image": preload("res://Assets/News/fourfive.png"),
			"text": "Fruits like apple, banana, 
			grapes, watermelon and orange are rich in..."
		},
		{
			"image": preload("res://Assets/News/foursix.png"),
			"text": "VITAMINS, MINERALS, 
			and FIBER"
		},
		{
			"image": preload("res://Assets/News/fourseventoten.png"),
			"text": "Vitamins and minerals strengthen immune
			system to fight diseases"
		},
		{
			"image": preload("res://Assets/News/fourseventoten.png"),
			"text": "It makes sure that your body is 
			working well and healthy"
		},
		{
			"image": preload("res://Assets/News/threeseventonine.png"),
			"text": "They also make your skin, hair, body shine!"
		},
		{
			"image": preload("res://Assets/News/threeseventonine.png"),
			"text": "Make sure to check your almanac 
			for more info!"
		},
		{
			"image": preload("res://Assets/News/threeone.png"),
			"text": "That’s all for today. Have a glowing day!"
		}
	],

}

# =========================

func _ready():
	# 🚫 If Day 1 → skip news completely
	if GameData.current_day < 2:
		SceneTransition.fade_to("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
		return

	# 🔥 LOAD NEWS BASED ON CURRENT DAY
	slides = all_news.get(GameData.current_day, all_news[2])

	$DialogueBox.hide()
	slide_image.hide()

	# 🔊 Play intro sound
	news_intro_sfx.play()

	await get_tree().create_timer(0.35).timeout

	start_intro_animation()

# =========================

func start_intro_animation():

	plate.show()
	gns.show()

	# =========================
	# PLATE (from LEFT)
	# =========================

	var plate_final = plate.position
	var plate_overshoot = plate_final + Vector2(60, 0)
	var plate_settle = plate_final - Vector2(20, 0)

	plate.position.x -= 2000

	var plate_tween = create_tween()

	plate_tween.tween_property(
		plate,
		"position",
		plate_overshoot,
		1.0
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	plate_tween.tween_property(plate, "position", plate_settle, 0.20)
	plate_tween.tween_property(plate, "position", plate_final, 0.12)

	# =========================
	# GNS (from RIGHT)
	# =========================

	var gns_final = gns.position
	var gns_overshoot = gns_final - Vector2(60, 0)
	var gns_settle = gns_final + Vector2(20, 0)

	gns.position.x += 2000

	var gns_tween = create_tween()

	gns_tween.tween_property(
		gns,
		"position",
		gns_overshoot,
		1.0
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	gns_tween.tween_property(gns, "position", gns_settle, 0.20)
	gns_tween.tween_property(gns, "position", gns_final, 0.12)

	# =========================
	# AFTER INTRO
	# =========================

	gns_tween.finished.connect(func():

		await get_tree().create_timer(1.0).timeout

		var fade_tween = create_tween()

		fade_tween.tween_property(plate, "modulate:a", 0.0, 0.5)
		fade_tween.tween_property(gns, "modulate:a", 0.0, 0.5)
		fade_tween.tween_property($Background, "modulate:a", 0.0, 0.5)

		fade_tween.finished.connect(func():

			plate.hide()
			gns.hide()

			slide_image.modulate.a = 0.0
			$DialogueBox.modulate.a = 0.0

			slide_image.show()
			$DialogueBox.show()

			var news_fade = create_tween()
			news_fade.tween_property(slide_image, "modulate:a", 1.0, 0.5)
			news_fade.tween_property($DialogueBox, "modulate:a", 1.0, 0.5)

			news_fade.finished.connect(func():
				show_slide()
				$SkipButton.show()
			)
		)
	)

# =========================

func show_slide():

	if current_slide >= slides.size():
		_end_news()
		return

	var data = slides[current_slide]

	slide_image.texture = data["image"]

	full_text = data["text"]
	dialogue_text.text = full_text
	dialogue_text.visible_characters = 0

	start_typewriter()

# =========================

func _on_btn_next_pressed():

	if is_typing:
		if typing_tween:
			typing_tween.kill()
		dialogue_text.visible_characters = full_text.length()
		is_typing = false
		return

	current_slide += 1
	show_slide()

# =========================

func _end_news():

	slide_image.hide()
	$DialogueBox.hide()

	plate.modulate.a = 1.0
	gns.modulate.a = 1.0
	$Background.modulate.a = 1.0
	
	$SkipButton.hide()

	plate.show()
	gns.show()

	news_intro_sfx.play()

	await get_tree().create_timer(1.0).timeout

	var bounce_tween = create_tween().set_parallel(true)
	bounce_tween.tween_property(plate, "scale", Vector2(1.1, 1.1), 0.15)
	bounce_tween.tween_property(gns, "scale", Vector2(1.1, 1.1), 0.15)
	bounce_tween.tween_property(plate, "scale", Vector2.ONE, 0.25).set_delay(0.15)
	bounce_tween.tween_property(gns, "scale", Vector2.ONE, 0.25).set_delay(0.15)

	await bounce_tween.finished

	var fade = create_tween()
	fade.tween_property($Background, "modulate:a", 0.0, 0.6)
	fade.tween_property(plate, "modulate:a", 0.0, 0.6)
	fade.tween_property(gns, "modulate:a", 0.0, 0.6)

	await fade.finished

	var GD = get_node("/root/GameData")

	GD.day_started = true   # 🔥 THIS IS THE FIX
	GD.current_phase = GD.GamePhase.NEWS
	GD.save_game()

	SceneTransition.fade_to("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
	


# =========================

func start_typewriter():

	if typing_tween:
		typing_tween.kill()

	is_typing = true

	typing_tween = create_tween()

	typing_tween.tween_property(
		dialogue_text,
		"visible_characters",
		full_text.length(),
		full_text.length() * typing_speed
	)

	typing_tween.finished.connect(func():
		is_typing = false
	)


func _on_skip_button_pressed() -> void:
	slide_image.hide()
	$DialogueBox.hide()

	plate.modulate.a = 1.0
	gns.modulate.a = 1.0
	$Background.modulate.a = 1.0

	$SkipButton.hide()

	plate.show()
	gns.show()

	news_intro_sfx.play()

	await get_tree().create_timer(1.0).timeout

	var bounce_tween = create_tween().set_parallel(true)
	bounce_tween.tween_property(plate, "scale", Vector2(1.1, 1.1), 0.15)
	bounce_tween.tween_property(gns, "scale", Vector2(1.1, 1.1), 0.15)
	bounce_tween.tween_property(plate, "scale", Vector2.ONE, 0.25).set_delay(0.15)
	bounce_tween.tween_property(gns, "scale", Vector2.ONE, 0.25).set_delay(0.15)

	await bounce_tween.finished

	var fade = create_tween()
	fade.tween_property($Background, "modulate:a", 0.0, 0.6)
	fade.tween_property(plate, "modulate:a", 0.0, 0.6)
	fade.tween_property(gns, "modulate:a", 0.0, 0.6)

	await fade.finished

	var GD = get_node("/root/GameData")

	GD.day_started = true   # 🔥 THIS IS THE FIX
	GD.current_phase = GD.GamePhase.NEWS
	GD.save_game()

	SceneTransition.fade_to("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
