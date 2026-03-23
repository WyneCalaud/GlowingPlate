extends Control

@onready var panel = $TicketPanel
@onready var name_label = $Content/CustomerName
@onready var age_label = $Content/CustomerAge

@onready var go_icon = $Content/GoRow/GoIcon1
@onready var grow_icon = $Content/GrowRow/GrowIcon1
@onready var veg_icon = $Content/GlowVegRow/GlowVegIcon1
@onready var fru_icon = $Content/GlowFruRow/GlowFruIcon1
@onready var water_icon = $Content/BeverageRow/WaterIcon
@onready var milk_icon = $Content/BeverageRow/MilkIcon

var hidden_position : Vector2
var shown_position : Vector2
var is_open := false

# ---> NEW: A flag to track if the tutorial is ready for the ticket to close
var tutorial_allows_outside_close := false

func _ready():
	# ---> NEW: We add this to a group so the InteractiveTutorial script can talk to it!
	add_to_group("OrderTicketGroup")
	
	$Content.hide()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_panel_clicked)

	await get_tree().process_frame

	shown_position = position
	hidden_position = shown_position - Vector2(size.x * 0.85, 0)

	position = hidden_position
	
	setup_tutorial_ticket()


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
	# Reset the permission flag every time it opens to be safe
	tutorial_allows_outside_close = false
	
	get_tree().call_group("InteractiveTutorial", "action_completed", "OrderTicket_Open")
	
	var rice_cup = get_node_or_null("../../KitchenArea/Go Section/WhiteRiceCup")
	if rice_cup:
		rice_cup.hide()
		
	$Content.show()
	create_tween().tween_property(self, "position", shown_position, 0.3)


func hide_ticket():
	if not is_open:
		return 
		
	is_open = false
	
	get_tree().call_group("InteractiveTutorial", "action_completed", "OrderTicket_Close")
	
	var rice_cup = get_node_or_null("../../KitchenArea/Go Section/WhiteRiceCup")
	if rice_cup:
		rice_cup.show()
		
	$Content.hide()
	create_tween().tween_property(self, "position", hidden_position, 0.3)


# ---> NEW: The InteractiveTutorial script will call this when dialogue finishes!
func allow_closing_from_tutorial():
	tutorial_allows_outside_close = true


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if is_open:
			# If we are in the tutorial...
			if get_tree().get_nodes_in_group("InteractiveTutorial").size() > 0:
				# ...only allow outside clicks IF the tutorial gave us permission
				if not tutorial_allows_outside_close:
					return 
			
			var mouse_pos = get_global_mouse_position()
			if not panel.get_global_rect().has_point(mouse_pos):
				hide_ticket()


func setup_tutorial_ticket():
	name_label.text = "Jenna"
	age_label.text = "10"
	
	go_icon.texture = preload("res://Assets/UI/RiceUI/PlatedRiceTooHigh.png") 
	grow_icon.texture = preload("res://Assets/UI/RiceUI/ChickenOnePiece.png")
	veg_icon.texture = preload("res://Assets/GlowSection/SitawPlated3.png")
	fru_icon.texture = preload("res://Assets/FruitSection/MangoPlated1.png")
	
	water_icon.visible = true
	milk_icon.visible = true
	water_icon.texture = preload("res://Assets/Ticket/ColdWater.png")
