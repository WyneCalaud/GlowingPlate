extends Control

@onready var title_label: Label = $CenterContainer/Layout/Title
@onready var money_label: Label = $CenterContainer/Layout/MoneyRow/MoneyLabel
@onready var rep_label: Label = $CenterContainer/Layout/ReputationRow/RepLabel
@onready var next_button: TextureButton = $CenterContainer/Layout/EndDayButton

func _ready():
	# 1. Update Title
	# Note: We subtract 1 because GameData increments the day BEFORE entering this scene
	title_label.text = "Day %d Complete!" % (GameData.current_day - 1)
	
	# 2. Show Stats (with a simple animation effect)
	animate_number(money_label, GameData.daily_money_earned, "$")
	animate_float(rep_label, GameData.daily_reputation_gained, "+")
	
	next_button.pressed.connect(_on_next_day_pressed)

func _on_next_day_pressed():
	# Transition to Quiz Scene
	get_tree().change_scene_to_file("res://Scenes/Quiz/QuizScene.tscn")

# --- OPTIONAL: simple counting animation ---
func animate_number(label: Label, target_value: int, prefix: String):
	var tween = create_tween()
	tween.tween_method(func(val): label.text = prefix + str(val), 0, target_value, 1.0)

func animate_float(label: Label, target_value: float, prefix: String):
	var tween = create_tween()
	tween.tween_method(func(val): label.text = prefix + "%.1f" % val, 0.0, target_value, 1.0)
