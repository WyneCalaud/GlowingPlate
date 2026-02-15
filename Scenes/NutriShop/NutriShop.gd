# NutriShop.gd

extends Control

# --- SIGNALS ---
signal closed

# --- EXPORTS ---
@export_group("Settings")
@export var shop_card_scene: PackedScene # MAKE SURE THIS IS ShopItemCard.tscn
@export var active_color: Color = Color(1.2, 1.2, 1.2)
@export var inactive_color: Color = Color.WHITE

@export_group("Data: Upgrades")
@export var upgrades_icons: Array[Texture2D]
@export var upgrades_prices: Array[int]
@export var upgrades_names: Array[String]

@export_group("Data: Kitchen")
@export var kitchen_icons: Array[Texture2D]
@export var kitchen_prices: Array[int]
@export var kitchen_names: Array[String]

# --- CANTEEN DECOR DATA (Icons for Shop, Skins for Scene) ---
# NOTE: The order of Skins MUST match the order of Icons/Names!

@export_group("Data: Canteen (WallFrame)")
@export var wallframe_names: Array[String]; @export var wallframe_prices: Array[int]; @export var wallframe_icons: Array[Texture2D]; @export var wallframe_skins: Array[Texture2D]

@export_group("Data: Canteen (Floors)")
@export var floor_names: Array[String]; @export var floor_prices: Array[int]; @export var floor_icons: Array[Texture2D]; @export var floor_skins: Array[Texture2D]

@export_group("Data: Canteen (High Tables)")
@export var hightable_names: Array[String]; @export var hightable_prices: Array[int]; @export var hightable_icons: Array[Texture2D]; @export var hightable_skins: Array[Texture2D]

@export_group("Data: Canteen (High Chairs)")
@export var highchair_names: Array[String]; @export var highchair_prices: Array[int]; @export var highchair_icons: Array[Texture2D]; @export var highchair_skins: Array[Texture2D]

@export_group("Data: Canteen (Main Tables)")
@export var maintable_names: Array[String]; @export var maintable_prices: Array[int]; @export var maintable_icons: Array[Texture2D]; @export var maintable_skins: Array[Texture2D]

@export_group("Data: Canteen (Countertops)")
@export var countertop_names: Array[String]; @export var countertop_prices: Array[int]; @export var countertop_icons: Array[Texture2D]; @export var countertop_skins: Array[Texture2D]

@export_group("Data: Canteen (Counter Decor)")
@export var counterdecor_names: Array[String]; @export var counterdecor_prices: Array[int]; @export var counterdecor_icons: Array[Texture2D]; @export var counterdecor_skins: Array[Texture2D]

@export_group("Data: Canteen (Entrance Decor)")
@export var entrancedecor_names: Array[String]; @export var entrancedecor_prices: Array[int]; @export var entrancedecor_icons: Array[Texture2D]; @export var entrancedecor_skins: Array[Texture2D]

@export_group("Data: Canteen (Lights)")
@export var lights_names: Array[String]; @export var lights_prices: Array[int]; @export var lights_icons: Array[Texture2D]; @export var lights_skins: Array[Texture2D]

@export_group("Data: Canteen (Cash Register)")
@export var cashregister_names: Array[String]; @export var cashregister_prices: Array[int]; @export var cashregister_icons: Array[Texture2D]; @export var cashregister_skins: Array[Texture2D]

# --- SCENE REFERENCES ---
@onready var close_btn: TextureButton = $CloseTextureButton
@onready var shop_window: Control = $NutriShopBackground

# Left Tabs System
@onready var btn_upgrades: BaseButton = $NutriShopBackground/LeftTabs/BtnUpgrades
@onready var btn_canteen: BaseButton = $NutriShopBackground/LeftTabs/BtnCanteen
@onready var btn_kitchen: BaseButton = $NutriShopBackground/LeftTabs/BtnKitchen

# Canteen Sub-Menu (ScrollContainer)
@onready var canteen_submenu_scroll: ScrollContainer = $NutriShopBackground/LeftTabs/CanteenSubMenuScroll
@onready var canteen_button_list: VBoxContainer = $NutriShopBackground/LeftTabs/CanteenSubMenuScroll/ButtonList

# Sub-Buttons
@onready var sub_btn_wallframe: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenuScroll/ButtonList/BtnWallFrame
@onready var sub_btn_floors: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenuScroll/ButtonList/BtnFloors
@onready var sub_btn_hightable: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenuScroll/ButtonList/BtnHighTable
@onready var sub_btn_highchairs: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenuScroll/ButtonList/BtnHighChairs
@onready var sub_btn_maintable: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenuScroll/ButtonList/BtnMainTable
@onready var sub_btn_countertop: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenuScroll/ButtonList/BtnCounterTop
@onready var sub_btn_counterdecor: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenuScroll/ButtonList/BtnCounterTopDec
@onready var sub_btn_entrancedecor: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenuScroll/ButtonList/BtnEntranceDec
@onready var sub_btn_lights: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenuScroll/ButtonList/BtnLights
@onready var sub_btn_cashregister: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenuScroll/ButtonList/BtnCashRegister

# Display Area
@onready var scroll_container: ScrollContainer = $NutriShopBackground/ItemDisplayScroll
@onready var item_container: HBoxContainer = $NutriShopBackground/ItemDisplayScroll/ItemContainer

# --- SHOP STATE ---
var unlocked_registry: Dictionary = {} 
var equipped_registry: Dictionary = {}
var category_map: Dictionary = {} 

# --- TRANSFORM DEFAULTS ---
# Main Tables
var default_mt_size: Vector2; var default_mt_pos: Vector2; var defaults_captured: bool = false
# Counter Decor
var default_cd_size: Vector2; var default_cd_pos: Vector2; var defaults_cd_captured: bool = false
# Entrance Decor (WallDec)
var default_ed_size: Vector2; var default_ed_pos: Vector2; var defaults_ed_captured: bool = false
# Lights
var default_l_size: Vector2; var default_l_pos: Vector2; var defaults_l_captured: bool = false
# Cash Register
var default_cr_size: Vector2; var default_cr_pos: Vector2; var defaults_cr_captured: bool = false

func _ready():
	if shop_window:
		shop_window.call_deferred("set_pivot_offset", shop_window.size / 2)
	
	# 1. Build the Data Map (Links Data -> Buttons -> Scene Nodes)
	_build_category_data()
	
	# 2. Initialize Defaults
	_initialize_defaults()
	
	# 3. Apply Skins to Scene immediately
	call_deferred("_apply_all_equipped_skins")

	# 4. Setup UI Layouts
	_setup_layouts()
	_setup_scrollbar_style(canteen_submenu_scroll)
	_setup_scrollbar_style(scroll_container)

	# 5. Connect Signals
	_connect_signals()
	
	call_deferred("_on_main_tab_pressed", "Upgrades")

func close_shop():
	closed.emit()

# --- CONFIGURATION: MAP CATEGORIES TO SCENE NODES ---
func _build_category_data():
	# Key = Category Name
	# node = The exact name of the node inside "Background" in LobbyCanteen.tscn
	category_map = {
		"WallFrame": 	{ "names": wallframe_names, "prices": wallframe_prices, "icons": wallframe_icons, "skins": wallframe_skins, "btn": sub_btn_wallframe, "node": "WallFrame" },
		"Floors": 		{ "names": floor_names, "prices": floor_prices, "icons": floor_icons, "skins": floor_skins, "btn": sub_btn_floors, "node": "Floor" },
		"HighTables": 	{ "names": hightable_names, "prices": hightable_prices, "icons": hightable_icons, "skins": hightable_skins, "btn": sub_btn_hightable, "node": "HighTable" },
		"HighChairs": 	{ "names": highchair_names, "prices": highchair_prices, "icons": highchair_icons, "skins": highchair_skins, "btn": sub_btn_highchairs, "node": "HighChairs" },
		"MainTables": 	{ "names": maintable_names, "prices": maintable_prices, "icons": maintable_icons, "skins": maintable_skins, "btn": sub_btn_maintable, "node": "MainTables" },
		"CounterTops": 	{ "names": countertop_names, "prices": countertop_prices, "icons": countertop_icons, "skins": countertop_skins, "btn": sub_btn_countertop, "node": "Countertop" },
		"CounterDecor": { "names": counterdecor_names, "prices": counterdecor_prices, "icons": counterdecor_icons, "skins": counterdecor_skins, "btn": sub_btn_counterdecor, "node": "CountertopDec" },
		"EntranceDecor":{ "names": entrancedecor_names, "prices": entrancedecor_prices, "icons": entrancedecor_icons, "skins": entrancedecor_skins, "btn": sub_btn_entrancedecor, "node": "WallDec" },
		"Lights": 		{ "names": lights_names, "prices": lights_prices, "icons": lights_icons, "skins": lights_skins, "btn": sub_btn_lights, "node": "Lights" },
		"CashRegister": { "names": cashregister_names, "prices": cashregister_prices, "icons": cashregister_icons, "skins": cashregister_skins, "btn": sub_btn_cashregister, "node": "CashRegister" }
	}

# --- SETUP HELPERS ---
func _setup_layouts():
	canteen_submenu_scroll.visible = false 
	canteen_submenu_scroll.custom_minimum_size.y = 0 
	canteen_submenu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canteen_submenu_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	if canteen_button_list:
		canteen_button_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		canteen_button_list.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if scroll_container:
		scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

func _connect_signals():
	close_btn.pressed.connect(close_shop)
	btn_upgrades.pressed.connect(func(): _on_main_tab_pressed("Upgrades"))
	btn_canteen.pressed.connect(func(): _on_main_tab_pressed("Canteen"))
	btn_kitchen.pressed.connect(func(): _on_main_tab_pressed("Kitchen"))
	
	for category_key in category_map:
		var data = category_map[category_key]
		if data.btn:
			data.btn.pressed.connect(func(): _on_sub_tab_pressed(category_key))

# --- DEFAULTS ---
func _initialize_defaults():
	for category in category_map:
		var data = category_map[category]
		var names = data.names
		var prices = data.prices
		
		var default_item = ""
		
		# 1. Search for a FREE item (Price == 0) to be the default
		for i in range(names.size()):
			var p = 0
			if i < prices.size():
				p = prices[i]
			
			if p == 0:
				default_item = names[i]
				break
		
		# 2. If no free item found, fallback to the very first item (Index 0)
		if default_item == "" and names.size() > 0:
			default_item = names[0]
			
		# 3. Unlock and Equip
		if default_item != "":
			if not unlocked_registry.has(default_item):
				unlocked_registry[default_item] = true
			if not equipped_registry.has(category):
				equipped_registry[category] = default_item

# --- TAB LOGIC ---
func _on_main_tab_pressed(category: String):
	btn_upgrades.modulate = inactive_color
	btn_canteen.modulate = inactive_color
	btn_kitchen.modulate = inactive_color
	
	if category == "Canteen":
		btn_canteen.modulate = active_color
		_animate_submenu(true)
		_on_sub_tab_pressed("WallFrame") # Default sub-tab
	else:
		_animate_submenu(false) 
		if category == "Upgrades":
			btn_upgrades.modulate = active_color
			_populate_items(upgrades_icons, upgrades_prices, upgrades_names, "Upgrades")
		elif category == "Kitchen":
			btn_kitchen.modulate = active_color
			_populate_items(kitchen_icons, kitchen_prices, kitchen_names, "Kitchen")

func _on_sub_tab_pressed(category_key: String):
	for key in category_map:
		if category_map[key].btn:
			category_map[key].btn.modulate = inactive_color
	
	if category_map.has(category_key):
		var data = category_map[category_key]
		if data.btn: data.btn.modulate = active_color
		# Use Icons for the Shop Card, Names for ID
		_populate_items(data.icons, data.prices, data.names, category_key)

func _animate_submenu(open: bool):
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var target_h = 230.0 if open else 0.0
	tween.tween_property(canteen_submenu_scroll, "custom_minimum_size:y", target_h, 0.3)
	if not open: tween.tween_callback(func(): canteen_submenu_scroll.visible = false)
	else: canteen_submenu_scroll.visible = true

# --- POPULATION & LOGIC ---
func _populate_items(icons: Array, prices: Array, names: Array, category: String):
	if not shop_card_scene: return
	
	for child in item_container.get_children():
		child.queue_free()
	
	for i in range(icons.size()):
		var card = shop_card_scene.instantiate()
		item_container.add_child(card)
		
		var icon_tex = icons[i]
		var price_val = prices[i] if i < prices.size() else 999
		var item_name = names[i] if i < names.size() else "Item"
		
		card.texture = icon_tex
		
		var state = "LOCKED"
		if unlocked_registry.has(item_name):
			if category == "Upgrades":
				# Upgrades: Always active once unlocked (Simultaneous)
				state = "EQUIPPED"
			else:
				# Decor: Only one active per category (Exclusive)
				state = "UNLOCKED"
				if equipped_registry.has(category) and equipped_registry[category] == item_name:
					state = "EQUIPPED"
		
		if card.has_method("setup"):
			card.setup(item_name, price_val, category, state)
			if not card.card_action.is_connected(_on_card_action):
				card.card_action.connect(_on_card_action)

	scroll_container.scroll_horizontal = 0
	scroll_container.modulate.a = 0.0
	create_tween().tween_property(scroll_container, "modulate:a", 1.0, 0.3)

func _on_card_action(card_node):
	var state = card_node.current_state
	var cost = card_node.price
	var item_name = card_node.item_name
	var category = card_node.category
	var gd = get_tree().get_first_node_in_group("GameData")

	if state == "LOCKED":
		# === BUY ===
		if gd and gd.money >= cost:
			gd.add_money(-cost)
			print("Purchased: ", item_name)
			unlocked_registry[item_name] = true
			
			if category == "Upgrades":
				# Upgrades equip immediately and stay equipped
				card_node.update_state("EQUIPPED")
			else:
				# Decor just unlocks
				card_node.update_state("UNLOCKED")
		else:
			# Not enough money shake
			var tween = create_tween()
			tween.tween_property(card_node, "modulate", Color.RED, 0.1)
			tween.tween_property(card_node, "modulate", Color.WHITE, 0.1)
			
	elif state == "UNLOCKED":
		# === EQUIP (Decor Only) ===
		print("Equipping: ", item_name, " in category: ", category)
		equipped_registry[category] = item_name
		
		# 1. Update the actual scene texture
		if category_map.has(category):
			var data = category_map[category]
			var idx = data.names.find(item_name)
			# Validate index and check if skin exists
			if idx != -1 and idx < data.skins.size():
				_update_decor_node(data.node, item_name, data.skins[idx])
		
		# 2. Update UI (Lock others in same category, equip this one)
		for child in item_container.get_children():
			if child.has_method("update_state"):
				var new_state = "LOCKED"
				if unlocked_registry.has(child.item_name):
					new_state = "UNLOCKED"
					if equipped_registry.get(category) == child.item_name:
						new_state = "EQUIPPED"
				child.update_state(new_state)

# --- SCENE UPDATE LOGIC ---
func _apply_all_equipped_skins():
	for cat in category_map:
		if equipped_registry.has(cat):
			var item_name = equipped_registry[cat]
			var data = category_map[cat]
			var idx = data.names.find(item_name)
			if idx != -1 and idx < data.skins.size():
				_update_decor_node(data.node, item_name, data.skins[idx])

func _update_decor_node(node_name: String, item_name: String, texture: Texture2D):
	# SAFETY CHECK: If texture is missing (null), do not update
	if texture == null:
		print("Safety Fallback: No skin texture found for ", node_name, ". Keeping existing skin.")
		return
	
	var root = get_tree().root
	# Search for the "Background" container first
	var background = root.find_child("Background", true, false)
	
	if background:
		# Search for the specific piece inside Background
		var target_node = background.get_node_or_null(node_name)
		if target_node:
			# 1. SPECIAL LOGIC FOR MAIN TABLES (Size/Position Override)
			if node_name == "MainTables":
				if not defaults_captured:
					if "size" in target_node: default_mt_size = target_node.size
					if "position" in target_node: default_mt_pos = target_node.position
					defaults_captured = true
				
				if item_name in ["OakWoodMT", "CloudWhiteMT", "CherryRedMT"]:
					if "size" in target_node: target_node.size = Vector2(975.0, 401.0)
					if "position" in target_node: target_node.position = Vector2(305.0, 187.0)
				else:
					if "size" in target_node: target_node.size = default_mt_size
					if "position" in target_node: target_node.position = default_mt_pos
			
			# 2. SPECIAL LOGIC FOR COUNTER DECOR
			if node_name == "CountertopDec":
				if not defaults_cd_captured:
					if "size" in target_node: default_cd_size = target_node.size
					if "position" in target_node: default_cd_pos = target_node.position
					defaults_cd_captured = true
				
				if item_name == "PlantVaseCD":
					if "size" in target_node: target_node.size = Vector2(359.0, 435.0)
					if "position" in target_node: target_node.position = Vector2(921.0, 266.0)
				elif item_name == "LuckyCatCD":
					if "size" in target_node: target_node.size = Vector2(158.0, 263.0)
					if "position" in target_node: target_node.position = Vector2(1122.0, 438.0)
				else:
					if "size" in target_node: target_node.size = default_cd_size
					if "position" in target_node: target_node.position = default_cd_pos

			# 3. SPECIAL LOGIC FOR ENTRANCE DECOR (WallDec)
			if node_name == "WallDec":
				if not defaults_ed_captured:
					if "size" in target_node: default_ed_size = target_node.size
					if "position" in target_node: default_ed_pos = target_node.position
					defaults_ed_captured = true

				if item_name == "MoneyTreeED":
					if "size" in target_node: target_node.size = Vector2(143.0, 204.0)
					if "position" in target_node: target_node.position = Vector2(795.0, 84.0)
				elif item_name == "RefrigeratorED":
					if "size" in target_node: target_node.size = Vector2(233.0, 206.0)
					if "position" in target_node: target_node.position = Vector2(819.0, 82.0)
				elif item_name == "BookshelfED":
					if "size" in target_node: target_node.size = Vector2(159.0, 237.0)
					if "position" in target_node: target_node.position = Vector2(798.0, 46.0)
				else:
					if "size" in target_node: target_node.size = default_ed_size
					if "position" in target_node: target_node.position = default_ed_pos

			# 4. SPECIAL LOGIC FOR LIGHTS
			if node_name == "Lights":
				if not defaults_l_captured:
					if "size" in target_node: default_l_size = target_node.size
					if "position" in target_node: default_l_pos = target_node.position
					defaults_l_captured = true

				if item_name == "FlowerLightsL":
					if "size" in target_node: target_node.size = Vector2(1079.0, 103.0)
					if "position" in target_node: target_node.position = Vector2(200.0, 0.0)
				elif item_name == "RattanLightsL":
					if "size" in target_node: target_node.size = Vector2(1080.0, 110.0)
					if "position" in target_node: target_node.position = Vector2(200.0, 0.0)
				elif item_name == "DumbbellLightsL":
					if "size" in target_node: target_node.size = Vector2(1080.0, 110.0)
					if "position" in target_node: target_node.position = Vector2(200.0, 0.0)
				else:
					if "size" in target_node: target_node.size = default_l_size
					if "position" in target_node: target_node.position = default_l_pos

			# 5. SPECIAL LOGIC FOR CASH REGISTER
			if node_name == "CashRegister":
				if not defaults_cr_captured:
					if "size" in target_node: default_cr_size = target_node.size
					if "position" in target_node: default_cr_pos = target_node.position
					defaults_cr_captured = true
				
				if item_name == "OrangeCashierCR":
					if "size" in target_node: target_node.size = Vector2(390.0, 329.0)
					if "position" in target_node: target_node.position = Vector2(0.0, 391.0)
				else:
					if "size" in target_node: target_node.size = default_cr_size
					if "position" in target_node: target_node.position = default_cr_pos

			# 6. Apply Texture
			if "texture" in target_node: target_node.texture = texture
			elif target_node.has_method("set_texture"): target_node.set_texture(texture)
		else:
			print("Warning: Node '", node_name, "' not found inside Background.")
	else:
		print("Warning: 'Background' node not found in current scene.")

# --- STYLE ---
func _setup_scrollbar_style(scroll: ScrollContainer):
	var h_bar = scroll.get_h_scroll_bar()
	var v_bar = scroll.get_v_scroll_bar()
	var apply_style = func(bar):
		if not bar: return
		bar.custom_minimum_size.y = 12
		bar.custom_minimum_size.x = 12
		var style_track = StyleBoxFlat.new(); style_track.bg_color = Color("4e342e"); style_track.set_corner_radius_all(6)
		var style_grabber = StyleBoxFlat.new(); style_grabber.bg_color = Color("8d6e63"); style_grabber.set_corner_radius_all(6); style_grabber.border_width_bottom = 2; style_grabber.border_color = Color("3e2723")
		bar.add_theme_stylebox_override("scroll", style_track)
		bar.add_theme_stylebox_override("grabber", style_grabber)
		bar.add_theme_stylebox_override("grabber_highlight", style_grabber)
		bar.add_theme_stylebox_override("grabber_pressed", style_grabber)
	if h_bar: apply_style.call(h_bar)
	if v_bar: apply_style.call(v_bar)
