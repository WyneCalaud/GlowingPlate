extends Control

@onready var panel = $TicketPanel
@onready var name_label = $Content/CustomerName
@onready var age_label = $Content/CustomerAge

@onready var go_icon = $Content/GoRow/GoIcon
@onready var grow_icon = $Content/GrowRow/GrowIcon
@onready var veg_icon = $Content/GlowVegRow/GlowVegIcon
@onready var fru_icon = $Content/GlowFruRow/GlowFruIcon
@onready var water_icon = $Content/BeverageRow/WaterIcon
@onready var milk_icon = $Content/BeverageRow/MilkIcon

var hidden_position : Vector2
var shown_position : Vector2
var is_open := false

func _ready():
	$Content.hide()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_panel_clicked)

	await get_tree().process_frame

	shown_position = position
	hidden_position = shown_position - Vector2(size.x * 0.85, 0)

	position = hidden_position


func _on_panel_clicked(event):
	if event is InputEventMouseButton and event.pressed:
		toggle_ticket()


func toggle_ticket():
	if is_open:
		hide_ticket()
	else:
		show_ticket()


func show_ticket():
	is_open = true
	$"../Go Section/RiceCup".hide()
	$Content.show()
	create_tween().tween_property(self, "position", shown_position, 0.3)


func hide_ticket():
	is_open = false
	$"../Go Section/RiceCup".show()
	$Content.hide()
	create_tween().tween_property(self, "position", hidden_position, 0.3)


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if is_open:
			var mouse_pos = get_global_mouse_position()
			if not panel.get_global_rect().has_point(mouse_pos):
				hide_ticket()


func set_order_display(customer_order: CustomerOrder):

	name_label.text = customer_order.customer_name
	age_label.text = "" + str(customer_order.age)

	var db = OrderSystem.FOOD_DB
	var plate = customer_order.needs

	go_icon.texture = db[plate["Go"]].get("default_plated_texture")
	grow_icon.texture = db[plate["Grow"]].get("plated_texture_whole")
	veg_icon.texture = db[plate["GlowVeg"]].get("veggie_plated_full")
	fru_icon.texture = db[plate["GlowFru"]].get("texture_count_1")

	#water_icon.visible = order["required_beverage"].has("")
	#milk_icon.visible = order["required_beverage"].has("")
