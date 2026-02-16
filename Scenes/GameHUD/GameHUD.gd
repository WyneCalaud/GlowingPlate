extends CanvasLayer

# --- UI REFERENCES ---
@onready var hud_control: Control = $HUDControl
@onready var menu_button: TextureButton = $HUDControl/TopBarRight/HBoxContainer/MenuGroup/MenuButton
@onready var settings_button: TextureButton = $HUDControl/TopBarRight/HBoxContainer/MenuGroup/MenuButton/SettingsButton
@onready var home_button: TextureButton = $HUDControl/TopBarRight/HBoxContainer/MenuGroup/MenuButton/HomeButton

# Labels
@onready var time_label: Label = $HUDControl/TopBarLeft/HBoxContainer/TimeGroup/DayCycle/Time
@onready var day_label: Label = $HUDControl/TopBarLeft/HBoxContainer/TimeGroup/DayCycle/Day
@onready var progress_label: Label = $HUDControl/TopBarLeft/HBoxContainer/HappinessGroup/Face/Label
@onready var cash_label: Label = $HUDControl/TopBarRight/HBoxContainer/MoneyGroup/Money/Label
@onready var keys_label: Label = $HUDControl/TopBarRight/HBoxContainer/KeyGroup/Key/Label

# Sound Control References
@onready var sound_control: Control = $HUDControl/SoundControl
@onready var sound_panel_close_button: TextureButton = $HUDControl/SoundControl/CloseButton
@onready var sfx_mute_button: TextureButton = $HUDControl/SoundControl/SettingsPanel/VolumeSettings/SFXGroup/SFXMuteButton
@onready var music_mute_button: TextureButton = $HUDControl/SoundControl/SettingsPanel/VolumeSettings/MusicGroup/MusicMuteButton
@onready var music_slider: HSlider = $HUDControl/SoundControl/SettingsPanel/VolumeSettings/MusicGroup/MusicSlider
@onready var sfx_slider: HSlider = $HUDControl/SoundControl/SettingsPanel/VolumeSettings/SFXGroup/SFXSlider

# Bottom Right Elements
@onready var bottom_right_container: Control = $HUDControl/BottomRight
@onready var finish_button: TextureButton = $HUDControl/BottomRight/LobbyButton

#AgeGroup
@onready var sixtonine: TextureRect = $"HUDControl/TopBarLeft/HBoxContainer/AgeGroup/6-9"
@onready var tentotwelve: TextureRect = $"HUDControl/TopBarLeft/HBoxContainer/AgeGroup/10-12"

# --- ANIMATION SETTINGS ---
var is_menu_open: bool = false
var menu_tween: Tween
const SLIDE_DISTANCE: float = 60.0
const ANIM_DURATION: float = 0.3

# --- SCENE PATHS ---
const MAIN_MENU_PATH = "res://Scenes/Main Menu/Main_menu.tscn"

# --- INITIALIZATION ---
func _ready():
	add_to_group("HUD")
	self.layer = 1
	hud_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_setup_initial_visibility()
	_connect_signals()
	update_all_labels()
	update_age_group_display() # ⭐ NEW

func _setup_initial_visibility():
	# Menu Buttons
	settings_button.modulate.a = 0
	home_button.modulate.a = 0
	settings_button.position.x += SLIDE_DISTANCE
	home_button.position.x += SLIDE_DISTANCE
	settings_button.visible = false
	home_button.visible = false
	settings_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Sound Control
	sound_control.visible = false
	sound_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Lobby Button
	show_finish_button(false)

func _connect_signals():
	var safe_connect = func(node, signal_name, callable):
		if node and not node.is_connected(signal_name, callable):
			node.connect(signal_name, callable)

	safe_connect.call(menu_button, "pressed", _on_menu_button_pressed)
	safe_connect.call(settings_button, "pressed", _on_settings_pressed)
	safe_connect.call(home_button, "pressed", _on_home_pressed)
	
	if sound_panel_close_button: safe_connect.call(sound_panel_close_button, "pressed", _on_close_button_pressed)
	if music_mute_button:
		music_mute_button.toggle_mode = true
		safe_connect.call(music_mute_button, "toggled", _on_music_mute_toggled)
	if sfx_mute_button:
		sfx_mute_button.toggle_mode = true
		safe_connect.call(sfx_mute_button, "toggled", _on_sfx_mute_toggled)
	if music_slider: safe_connect.call(music_slider, "value_changed", _on_music_volume_changed)
	if sfx_slider: safe_connect.call(sfx_slider, "value_changed", _on_sfx_volume_changed)

# --- REFRESH LOGIC ---
func update_all_labels():
	if has_node("/root/GameData"):
		var GD = get_node("/root/GameData")
		update_cash(GD.money)
		update_day(GD.current_day)
		update_keys(GD.keys)
		refresh_time_display()

func refresh_time_display():
	if has_node("/root/GameData"):
		var GD = get_node("/root/GameData")
		if time_label: time_label.text = GD.get_current_time_string()

# --- MENU & SOUND LOGIC ---
func _on_menu_button_pressed():
	is_menu_open = !is_menu_open
	if menu_tween: menu_tween.kill()
	menu_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	if is_menu_open:
		settings_button.visible = true
		home_button.visible = true
		settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
		home_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		menu_tween.tween_property(settings_button, "position:x", settings_button.position.x - SLIDE_DISTANCE, ANIM_DURATION)
		menu_tween.tween_property(settings_button, "modulate:a", 1.0, ANIM_DURATION)
		menu_tween.tween_property(home_button, "position:x", home_button.position.x - SLIDE_DISTANCE, ANIM_DURATION).set_delay(0.05)
		menu_tween.tween_property(home_button, "modulate:a", 1.0, ANIM_DURATION).set_delay(0.05)
	else:
		settings_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		home_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		menu_tween.tween_property(settings_button, "position:x", settings_button.position.x + SLIDE_DISTANCE, ANIM_DURATION)
		menu_tween.tween_property(settings_button, "modulate:a", 0.0, ANIM_DURATION)
		menu_tween.tween_property(home_button, "position:x", home_button.position.x + SLIDE_DISTANCE, ANIM_DURATION)
		menu_tween.tween_property(home_button, "modulate:a", 0.0, ANIM_DURATION)
		menu_tween.set_parallel(false)
		menu_tween.tween_callback(func(): 
			settings_button.visible = false
			home_button.visible = false
		)

func _on_settings_pressed():
	sound_control.visible = true
	sound_control.mouse_filter = Control.MOUSE_FILTER_STOP
	_on_menu_button_pressed()

func _on_close_button_pressed() -> void:
	sound_control.visible = false
	sound_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_music_mute_toggled(is_muted: bool):
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1: AudioServer.set_bus_mute(bus_idx, is_muted)

func _on_sfx_mute_toggled(is_muted: bool):
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1: AudioServer.set_bus_mute(bus_idx, is_muted)

func _on_music_volume_changed(value: float):
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1: AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_sfx_volume_changed(value: float):
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1: AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_home_pressed():
	get_tree().paused = false 
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

# --- HUD UPDATES ---
func update_cash(amount: int): if cash_label: cash_label.text = str(amount)
func update_day(day: int): if day_label: day_label.text = "Day: " + str(day)
func update_keys(amount: int): if keys_label: keys_label.text = str(amount)
func update_progress_display(value: float): if progress_label: progress_label.text = str(int(value)) + "%"

func update_age_group_display():
	if not has_node("/root/GameData"):
		return

	var GD = get_node("/root/GameData")
	var age: String = GD.current_customer_age_group

	# hide both first
	sixtonine.visible = false
	tentotwelve.visible = false

	match age:
		"6-9":
			sixtonine.visible = true
		"10-12":
			tentotwelve.visible = true


func show_finish_button(show: bool):
	if finish_button:
		finish_button.visible = show
		var filter = Control.MOUSE_FILTER_STOP if show else Control.MOUSE_FILTER_IGNORE
		finish_button.mouse_filter = filter
		bottom_right_container.mouse_filter = filter
