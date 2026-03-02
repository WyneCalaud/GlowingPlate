extends CanvasLayer

# --- UI REFERENCES ---
@onready var hud_control: Control = $HUDControl
@onready var menu_button: TextureButton = $HUDControl/TopBarRight/MenuGroup/MenuButton
@onready var settings_button: TextureButton = $HUDControl/TopBarRight/MenuGroup/MenuButton/SettingsButton
@onready var home_button: TextureButton = $HUDControl/TopBarRight/MenuGroup/MenuButton/HomeButton
@onready var almanac_button: TextureButton = $HUDControl/TopBarRight/MenuGroup/MenuButton/AlmanacButton
@onready var almanac_ui: Control = $AlmanacUI

# Labels
@onready var time_label: Label = $HUDControl/TopBarLeft/HBoxContainer/TimeGroup/DayCycle/Time
@onready var day_label: Label = $HUDControl/TopBarLeft/HBoxContainer/TimeGroup/DayCycle/Day
@onready var progress_label: Label = $HUDControl/TopBarLeft/HBoxContainer/HappinessGroup/Happinessbg/PatiencePercent
@onready var cash_label: Label = $HUDControl/TopBarRight2/HBoxContainer/Money/Label
@onready var keys_label: Label = $HUDControl/TopBarRight2/HBoxContainer/Key/Label
@onready var profile_name: Label = $HUDControl/TopBarLeft/HBoxContainer/ProfileGroup/Profile/Name
@onready var day_name: Label = $HUDControl/TopBarLeft/HBoxContainer/ProfileGroup/Profile/Day

# Faces
@onready var happy_face: TextureRect = $HUDControl/TopBarLeft/HBoxContainer/HappinessGroup/Happinessbg/Happy
@onready var neutral_face: TextureRect = $HUDControl/TopBarLeft/HBoxContainer/HappinessGroup/Happinessbg/Neutral
@onready var sad_face: TextureRect = $HUDControl/TopBarLeft/HBoxContainer/HappinessGroup/Happinessbg/Sad
@onready var angry_face: TextureRect = $HUDControl/TopBarLeft/HBoxContainer/HappinessGroup/Happinessbg/Angry

# Sound Control References
@onready var sound_control: Control = $HUDControl/SoundControl
@onready var sound_panel_close_button: TextureButton = $HUDControl/SoundControl/CloseButton
@onready var sfx_mute_button: TextureButton = $HUDControl/SoundControl/SettingsPanel/VolumeSettings/SFXGroup/SFXMuteButton
@onready var music_mute_button: TextureButton = $HUDControl/SoundControl/SettingsPanel/VolumeSettings/MusicGroup/MusicMuteButton
@onready var music_slider: HSlider = $HUDControl/SoundControl/SettingsPanel/VolumeSettings/MusicGroup/MusicSlider
@onready var sfx_slider: HSlider = $HUDControl/SoundControl/SettingsPanel/VolumeSettings/SFXGroup/SFXSlider

# Bottom Right Elements
@onready var bottom_right_container: Control = $HUDControl/BottomRight
@onready var finish_button: TextureButton = $HUDControl/BottomRight/FinishButton

#AgeGroup
@onready var sixtonine: TextureRect = $"HUDControl/TopBarLeft/HBoxContainer/AgeGroup/6-9"
@onready var tentotwelve: TextureRect = $"HUDControl/TopBarLeft/HBoxContainer/AgeGroup/10-12"

#Confirm
@onready var home_dim: TextureRect = $HomeDim
@onready var home_popup: TextureRect = $HomePopup
@onready var home_confirm: TextureButton = $HomePopup/HomeConfirm
@onready var home_cancel: TextureButton = $HomePopup/HomeCancel


const WEEK_DAYS := ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

# --- ANIMATION SETTINGS ---
var is_menu_open: bool = false
var menu_tween: Tween
const ANIM_DURATION: float = 0.3
const BUTTON_SPACING: float = 70.0 # Distance between buttons vertically

# --- SCENE PATHS ---
const MAIN_MENU_PATH = "res://Scenes/Main Menu/Main_menu.tscn"
const LOBBY_CANTEEN_PATH = "res://Scenes/Lobby Canteen/lobbycanteen.tscn"

# -----------------------------
# PATIENCE SYSTEM
# -----------------------------
var patience := 100.0
var patience_active := false

# ~70 seconds to empty
var patience_decay_rate := 0.8


# --- INITIALIZATION ---
func _ready():
	_reset_happiness_ui()
	add_to_group("HUD")
	self.layer = 1
	hud_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# IMPORTANT: Dropdown Configuration
	# 1. top_level = false (They must stay attached to the MenuButton)
	# 2. z_index = -1 (They must render BEHIND the MenuButton)
	# 3. position = Vector2.ZERO (Start exactly underneath the MenuButton)
	
	if menu_button:
		menu_button.z_index = 0 # Parent on top
	
	if settings_button:
		settings_button.top_level = false
		settings_button.z_index = -1
		settings_button.position = Vector2.ZERO
		settings_button.visible = false
		settings_button.modulate.a = 0.0
		settings_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	if home_button:
		home_button.top_level = false
		home_button.z_index = -1
		home_button.position = Vector2.ZERO
		home_button.visible = false
		home_button.modulate.a = 0.0
		home_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if almanac_button:
		almanac_button.top_level = false
		almanac_button.z_index = -1
		almanac_button.position = Vector2.ZERO
		almanac_button.visible = false
		almanac_button.modulate.a = 0.0
		almanac_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_setup_initial_visibility()
	_connect_signals()
	update_all_labels()
	update_age_group_display() # ⭐ NEW
	var GD = get_node("/root/GameData")
	update_progress_display(GD.customer_patience)
	if GD.patience_running:
		start_patience()

func _setup_initial_visibility():
	# 1. FORCE RESET DEFAULT VISIBILITY
	var top_left = hud_control.get_node_or_null("TopBarLeft")
	if top_left: top_left.visible = true
	
	var top_right = hud_control.get_node_or_null("TopBarRight")
	if top_right: top_right.visible = true
	
	var key_group = hud_control.find_child("KeyGroup", true, false)
	if key_group: key_group.visible = true

	var money_group = hud_control.find_child("MoneyGroup", true, false)
	if money_group: money_group.visible = true

	# 2. Sound Control
	sound_control.visible = false
	sound_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 3. Lobby Button
	show_finish_button(false)

func _connect_signals():
	var safe_connect = func(node, signal_name, callable):
		if node and not node.is_connected(signal_name, callable):
			node.connect(signal_name, callable)
			
	safe_connect.call(almanac_button, "pressed", _on_almanac_pressed)
	if almanac_ui and not almanac_ui.is_connected("closed", _on_almanac_closed):
		almanac_ui.closed.connect(_on_almanac_closed)

	safe_connect.call(menu_button, "pressed", _on_menu_button_pressed)
	safe_connect.call(settings_button, "pressed", _on_settings_pressed)
	safe_connect.call(home_confirm, "pressed", _on_home_confirm_pressed)
	safe_connect.call(home_cancel, "pressed", _on_home_cancel_pressed)
	
	if finish_button: safe_connect.call(finish_button, "pressed", _on_finish_button_pressed)
	
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
		update_profile_display(GD)

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
		# SHOW (Dropdown)
		settings_button.visible = true
		home_button.visible = true
		almanac_button.visible = true
		settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
		home_button.mouse_filter = Control.MOUSE_FILTER_STOP
		almanac_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Animate Y position downwards (LOCAL coordinates relative to MenuButton)
		menu_tween.tween_property(settings_button, "position:y", BUTTON_SPACING, ANIM_DURATION)
		menu_tween.tween_property(settings_button, "modulate:a", 1.0, ANIM_DURATION)
		
		menu_tween.tween_property(home_button, "position:y", BUTTON_SPACING * 2, ANIM_DURATION).set_delay(0.05)
		menu_tween.tween_property(home_button, "modulate:a", 1.0, ANIM_DURATION).set_delay(0.05)
		
		menu_tween.tween_property(almanac_button, "position:y", BUTTON_SPACING * 3, ANIM_DURATION).set_delay(0.1)
		menu_tween.tween_property(almanac_button, "modulate:a", 1.0, ANIM_DURATION).set_delay(0.1)
	else:
		# HIDE (Slide Up)
		settings_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		home_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		almanac_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Animate Y position back to 0 (Behind MenuButton)
		menu_tween.tween_property(settings_button, "position:y", 0.0, ANIM_DURATION)
		menu_tween.tween_property(settings_button, "modulate:a", 0.0, ANIM_DURATION)
		
		menu_tween.tween_property(home_button, "position:y", 0.0, ANIM_DURATION)
		menu_tween.tween_property(home_button, "modulate:a", 0.0, ANIM_DURATION)
		
		menu_tween.tween_property(almanac_button, "position:y", 0.0, ANIM_DURATION)
		menu_tween.tween_property(almanac_button, "modulate:a", 0.0, ANIM_DURATION)
		
		menu_tween.chain().tween_callback(func(): 
			settings_button.visible = false
			home_button.visible = false
			almanac_button.visible = false
		)

func _on_settings_pressed():
	sound_control.visible = true
	sound_control.mouse_filter = Control.MOUSE_FILTER_STOP
	_on_menu_button_pressed() # Close menu

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
	# Close dropdown menu
	if is_menu_open:
		_on_menu_button_pressed()

	# Show confirmation popup
	home_dim.visible = true
	home_popup.visible = true

	home_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	home_popup.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_finish_button_pressed():
	progress_label.show()

	var GD = get_node_or_null("/root/GameData")

	if GD:
		# ✅ pause instead of reset
		GD.patience_running = false

	get_tree().call_group("HUD", "stop_patience")

	if GD and GD.has_method("transition_to_canteen_serve"):
		GD.call_deferred("transition_to_canteen_serve")
	else:
		get_tree().call_deferred(
			"change_scene_to_file",
			LOBBY_CANTEEN_PATH
		)

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
		
		if bottom_right_container:
			# FIX: Ensure parent container visibility is also updated!
			bottom_right_container.visible = show 
			bottom_right_container.mouse_filter = filter

func _on_almanac_closed() -> void:
	almanac_ui.visible = false
	almanac_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_almanac_pressed() -> void:
	almanac_ui.visible = true
	almanac_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	_on_menu_button_pressed() # close dropdown

func get_weekday_from_day(day_number: int) -> String:
	var index = (day_number - 1) % WEEK_DAYS.size()
	return WEEK_DAYS[index]

func update_profile_display(GD):
	if profile_name:
		profile_name.text = GD.player_name if GD.player_name != "" else "Player"
	
	if day_name:
		day_name.text = get_weekday_from_day(GD.current_day)

# =====================================================
# PATIENCE / HAPPINESS SYSTEM
# =====================================================

func start_patience():
	var GD = get_node("/root/GameData")

	GD.customer_patience = 100.0
	GD.patience_running = true

	patience_active = true

	var group = hud_control.get_node("TopBarLeft/HBoxContainer/HappinessGroup")
	group.visible = true

	patience = GD.customer_patience
	update_progress_display(patience)
	_update_face()


func stop_patience():
	var GD = get_node("/root/GameData")

	GD.patience_running = false
	patience_active = false

	# ⭐ IMPORTANT: Sync local patience
	patience = GD.customer_patience

	# Keep bar visible (paused state)
	var group = hud_control.get_node("TopBarLeft/HBoxContainer/HappinessGroup")
	group.visible = true

	update_progress_display(patience)
	_update_face()

func reset_patience():
	var GD = get_node("/root/GameData")

	GD.patience_running = false
	GD.customer_patience = 100.0

	patience = 100.0
	patience_active = false

	_reset_happiness_ui()


func _reset_happiness_ui():
	var group = hud_control.get_node("TopBarLeft/HBoxContainer/HappinessGroup")
	group.visible = false
	
	happy_face.hide()
	neutral_face.hide()
	sad_face.hide()
	angry_face.hide()


func _process(delta):

	var GD = get_node("/root/GameData")

	if not GD.patience_running:
		return

	# Decay patience globally
	var decay = patience_decay_rate / GD.customer_patience_multiplier
	GD.customer_patience -= decay * delta
	GD.customer_patience = clamp(GD.customer_patience, 0.0, 100.0)

	# Sync local HUD value
	patience = GD.customer_patience

	# ⭐ REAL-TIME LABEL UPDATE
	if progress_label:
		progress_label.text = str(int(patience)) + "%"

	_update_face()


func _update_face():

	happy_face.hide()
	neutral_face.hide()
	sad_face.hide()
	angry_face.hide()

	if patience >= 75:
		happy_face.show()
	elif patience >= 50:
		neutral_face.show()
	elif patience >= 25:
		sad_face.show()
	else:
		angry_face.show()


func _on_home_cancel_pressed():
	home_dim.visible = false
	home_popup.visible = false

func _on_home_confirm_pressed():

	var GD = get_node("/root/GameData")

	# Reset everything properly
	GD.reset_day_state()

	# Hide popup
	home_dim.visible = false
	home_popup.visible = false

	# Make sure game isn't paused
	get_tree().paused = false

	# Go to main menu
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
