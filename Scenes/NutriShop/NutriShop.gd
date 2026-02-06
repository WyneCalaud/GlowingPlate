extends Control

# --- SIGNALS ---
signal closed

# --- EXPORTS (Drag & Drop Data) ---
@export_group("Settings")
@export var shop_card_scene: PackedScene # Assign ShopItemCard.tscn here
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

# --- CANTEEN DECOR DATA ---

@export_group("Data: Canteen (Windows)")
@export var window_icons: Array[Texture2D]
@export var window_prices: Array[int]
@export var window_names: Array[String]

@export_group("Data: Canteen (Floors)")
@export var floor_icons: Array[Texture2D]
@export var floor_prices: Array[int]
@export var floor_names: Array[String]

@export_group("Data: Canteen (High Tables)")
@export var hightable_icons: Array[Texture2D]
@export var hightable_prices: Array[int]
@export var hightable_names: Array[String]

@export_group("Data: Canteen (High Chairs)")
@export var highchair_icons: Array[Texture2D]
@export var highchair_prices: Array[int]
@export var highchair_names: Array[String]

@export_group("Data: Canteen (Main Tables)")
@export var maintable_icons: Array[Texture2D]
@export var maintable_prices: Array[int]
@export var maintable_names: Array[String]

@export_group("Data: Canteen (Countertops)")
@export var countertop_icons: Array[Texture2D]
@export var countertop_prices: Array[int]
@export var countertop_names: Array[String]

@export_group("Data: Canteen (Counter Decor)")
@export var counterdecor_icons: Array[Texture2D]
@export var counterdecor_prices: Array[int]
@export var counterdecor_names: Array[String]

@export_group("Data: Canteen (Entrance Decor)")
@export var entrancedecor_icons: Array[Texture2D]
@export var entrancedecor_prices: Array[int]
@export var entrancedecor_names: Array[String]

# --- SCENE REFERENCES ---
@onready var close_btn: TextureButton = $CloseTextureButton
@onready var shop_window: Control = $NutriShopBackground

# Left Tabs System
@onready var btn_upgrades: BaseButton = $NutriShopBackground/LeftTabs/BtnUpgrades
@onready var btn_canteen: BaseButton = $NutriShopBackground/LeftTabs/BtnCanteen
@onready var btn_kitchen: BaseButton = $NutriShopBackground/LeftTabs/BtnKitchen

# Canteen Sub-Menu
@onready var canteen_submenu: VBoxContainer = $NutriShopBackground/LeftTabs/CanteenSubMenu

@onready var sub_btn_windows: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenu/BtnWindows
@onready var sub_btn_floors: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenu/BtnFloors
@onready var sub_btn_hightable: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenu/BtnHighTable
@onready var sub_btn_highchairs: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenu/BtnHighChairs
@onready var sub_btn_maintable: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenu/BtnMainTable
@onready var sub_btn_countertop: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenu/BtnCounterTop
@onready var sub_btn_counterdecor: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenu/BtnCounterTopDec
@onready var sub_btn_entrancedecor: BaseButton = $NutriShopBackground/LeftTabs/CanteenSubMenu/BtnEntranceDec

# Display Area
@onready var scroll_container: ScrollContainer = $NutriShopBackground/ItemDisplayScroll
@onready var item_container: HBoxContainer = $NutriShopBackground/ItemDisplayScroll/ItemContainer

func _ready():
	# 1. Setup Pivot
	if shop_window:
		shop_window.call_deferred("set_pivot_offset", shop_window.size / 2)

	# 2. Setup Submenu for Sliding
	canteen_submenu.visible = false 
	canteen_submenu.custom_minimum_size.y = 0
	canteen_submenu.clip_contents = true # Crucial for sliding animation

	# 3. Connect Main Tabs
	btn_upgrades.pressed.connect(func(): _on_main_tab_pressed("Upgrades"))
	btn_canteen.pressed.connect(func(): _on_main_tab_pressed("Canteen"))
	btn_kitchen.pressed.connect(func(): _on_main_tab_pressed("Kitchen"))
	
	close_btn.pressed.connect(close_shop)

	# 4. Connect Sub-Menu Buttons
	sub_btn_windows.pressed.connect(func(): _populate_items(window_icons, window_prices, window_names))
	sub_btn_floors.pressed.connect(func(): _populate_items(floor_icons, floor_prices, floor_names))
	sub_btn_hightable.pressed.connect(func(): _populate_items(hightable_icons, hightable_prices, hightable_names))
	sub_btn_highchairs.pressed.connect(func(): _populate_items(highchair_icons, highchair_prices, highchair_names))
	sub_btn_maintable.pressed.connect(func(): _populate_items(maintable_icons, maintable_prices, maintable_names))
	sub_btn_countertop.pressed.connect(func(): _populate_items(countertop_icons, countertop_prices, countertop_names))
	sub_btn_counterdecor.pressed.connect(func(): _populate_items(counterdecor_icons, counterdecor_prices, counterdecor_names))
	sub_btn_entrancedecor.pressed.connect(func(): _populate_items(entrancedecor_icons, entrancedecor_prices, entrancedecor_names))

	# 5. Styling & Init
	_setup_scrollbar_style(scroll_container)
	_on_main_tab_pressed("Upgrades")

func close_shop():
	closed.emit()

# --- TAB LOGIC ---

func _on_main_tab_pressed(category: String):
	# Reset Colors
	btn_upgrades.modulate = inactive_color
	btn_canteen.modulate = inactive_color
	btn_kitchen.modulate = inactive_color
	
	# Logic
	if category == "Canteen":
		btn_canteen.modulate = active_color
		_animate_submenu(true)
		# Load default sub-category
		_populate_items(window_icons, window_prices, window_names)
	else:
		_animate_submenu(false) # Slide up/Close submenu
		
		if category == "Upgrades":
			btn_upgrades.modulate = active_color
			_populate_items(upgrades_icons, upgrades_prices, upgrades_names)
		elif category == "Kitchen":
			btn_kitchen.modulate = active_color
			_populate_items(kitchen_icons, kitchen_prices, kitchen_names)

func _animate_submenu(open: bool):
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if open:
		canteen_submenu.visible = true
		# Calculate height based on children count (Approx 40px per button + spacing)
		# Or just set a fixed height enough to show all buttons. 
		# 8 buttons * approx 40px = 320 + padding = 350-400
		var target_height = 400.0 
		tween.tween_property(canteen_submenu, "custom_minimum_size:y", target_height, 0.3)
	else:
		tween.tween_property(canteen_submenu, "custom_minimum_size:y", 0.0, 0.3)
		tween.tween_callback(func(): canteen_submenu.visible = false)

# --- POPULATION LOGIC ---

func _populate_items(icons: Array, prices: Array, names: Array):
	# 1. Clear old items
	for child in item_container.get_children():
		child.queue_free()
	
	if not shop_card_scene: return

	# 2. Create new items
	for i in range(icons.size()):
		var card = shop_card_scene.instantiate()
		item_container.add_child(card)
		
		# -- GET NODES (Based on your ShopItemCard.tscn structure) --
		# Root is "Card" (TextureRect)
		# Children: "BtnPrice" (TextureButton), "PriceLabel" (Label)
		
		var icon_texture = icons[i]
		var price_val = prices[i] if i < prices.size() else 999
		var item_name = names[i] if i < names.size() else "Item"
		
		# Assign Texture to the Card itself (since Card is a TextureRect)
		card.texture = icon_texture
		
		# Setup Price Button & Label
		var btn_price = card.get_node_or_null("BtnPrice")
		var lbl_price = card.get_node_or_null("PriceLabel")
		
		if lbl_price:
			lbl_price.text = str(price_val)
			
		if btn_price:
			# Connect signal with data binding
			if not btn_price.pressed.is_connected(_on_buy_pressed):
				btn_price.pressed.connect(_on_buy_pressed.bind(price_val, item_name, btn_price))
	
	# Fade in animation for the list
	scroll_container.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(scroll_container, "modulate:a", 1.0, 0.3)

func _on_buy_pressed(cost: int, item_name: String, btn: BaseButton):
	var gd = get_tree().get_first_node_in_group("GameData")
	if gd:
		if gd.money >= cost:
			gd.add_money(-cost)
			print("Purchased: ", item_name)
			
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5)
		else:
			# Shake animation for "No Money"
			var tween = create_tween()
			tween.tween_property(btn, "modulate", Color.RED, 0.1)
			tween.tween_property(btn, "modulate", Color.WHITE, 0.1)
	else:
		print("GameData not found")

# --- STYLE ---
func _setup_scrollbar_style(scroll: ScrollContainer):
	var h_bar = scroll.get_h_scroll_bar()
	if not h_bar: return
	
	h_bar.custom_minimum_size.y = 12
	var color_track = Color("4e342e") 
	var color_grabber = Color("8d6e63")
	var color_grabber_hover = Color("a1887f")
	
	var style_track = StyleBoxFlat.new()
	style_track.bg_color = color_track
	style_track.set_corner_radius_all(6)
	
	var style_grabber = StyleBoxFlat.new()
	style_grabber.bg_color = color_grabber
	style_grabber.set_corner_radius_all(6)
	style_grabber.border_width_bottom = 2
	style_grabber.border_color = Color("3e2723") 
	
	var style_grabber_hover = style_grabber.duplicate()
	style_grabber_hover.bg_color = color_grabber_hover

	h_bar.add_theme_stylebox_override("scroll", style_track)
	h_bar.add_theme_stylebox_override("grabber", style_grabber)
	h_bar.add_theme_stylebox_override("grabber_highlight", style_grabber_hover)
	h_bar.add_theme_stylebox_override("grabber_pressed", style_grabber)
