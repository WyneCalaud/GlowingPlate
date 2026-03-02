extends TextureButton

@onready var plate = $"../../Plate/FoodPlate"

# Debounce tracker so players can't spam it and break the array
var is_undoing: bool = false

func _ready():
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	
	var gd = get_node_or_null("/root/GameData")
	
	if gd and "unlocked_upgrades" in gd:
		if "ReturnFood" in gd.unlocked_upgrades or "Undo Button" in gd.unlocked_upgrades:
			show()
		else:
			hide()
	else:
		hide()

func _on_pressed():
	# PREVENT SPAM CLICKING
	if is_undoing: return
	is_undoing = true

	if is_instance_valid(plate) and plate.has_method("undo_last_placement"):
		
		# Safely check if there is actually something on the plate to undo
		var has_items_to_undo = false
		if plate.has_method("get_plate_contents"):
			has_items_to_undo = plate.get_plate_contents().size() > 0
		elif "placed_items" in plate:
			has_items_to_undo = plate.placed_items.size() > 0
			
		if has_items_to_undo:
			plate.undo_last_placement()
	
	# Small cooldown before they can click again
	await get_tree().create_timer(0.2).timeout
	is_undoing = false
