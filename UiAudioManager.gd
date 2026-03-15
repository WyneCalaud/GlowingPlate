extends Node

# The AudioStreamPlayer that will play the sound
var click_player: AudioStreamPlayer

# 🛑 CHANGE THIS to the actual path of your sound effect file!
const CLICK_SOUND_PATH = "res://Assets/SFX/Button Click.mp3"

func _ready() -> void:
	# 1. Create the AudioStreamPlayer dynamically
	click_player = AudioStreamPlayer.new()
	var click_stream = load(CLICK_SOUND_PATH)
	
	if click_stream:
		click_player.stream = click_stream
		# Optional: Set this to your UI or SFX bus if you use audio buses
		click_player.bus = "Master" 
		add_child(click_player)
	else:
		push_error("UiAudioManager: Could not load sound at " + CLICK_SOUND_PATH)

	# 2. Connect to the SceneTree to detect whenever ANY new node is added to the game
	get_tree().node_added.connect(_on_node_added)
	
	# 3. Recursively scan the existing nodes (just in case some loaded before this script)
	_scan_for_buttons(get_tree().root)

# Triggered automatically every time a node enters the game
func _on_node_added(node: Node) -> void:
	# BaseButton covers Button, TextureButton, CheckButton, etc.
	if node is BaseButton:
		_connect_button(node)

# Connects the sound to the button's pressed signal
func _connect_button(button: BaseButton) -> void:
	# ⭐ EXCEPTION CHECK: Ignore buttons that have their own custom sounds!
	if button.is_in_group("silent_button") or button.name == "BtnPrice":
		return

	# Ensure we don't accidentally connect it twice
	if not button.pressed.is_connected(_play_click_sound):
		button.pressed.connect(_play_click_sound)

# Scans an existing tree of nodes
func _scan_for_buttons(root_node: Node) -> void:
	if root_node is BaseButton:
		_connect_button(root_node)
		
	for child in root_node.get_children():
		_scan_for_buttons(child)

# The function that actually plays the sound
func _play_click_sound() -> void:
	if click_player and click_player.stream:
		# Randomize the pitch slightly to make consecutive clicks sound natural (Optional but recommended!)
		click_player.pitch_scale = randf_range(0.95, 1.05)
		click_player.play()
