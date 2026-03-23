extends Resource
class_name TutorialStep

# This creates a dropdown menu in the Inspector!
enum StepType { IMAGE, INTERACTIVE }

@export var step_type: StepType = StepType.IMAGE

@export_group("Image Settings")
# This creates a slot where you can drag and drop your .png files!
@export var image: Texture2D 

@export_group("Interactive Settings")
# Type the action string here (e.g., "go_food_plated"). Leave blank if it's an Image step.
@export var action_name: String = ""

# Type the exact Node name of the interactable you want to UNLOCK during this step.
# Leave blank if it's an Image step or if no specific node needs to be clicked.
@export var node_to_unlock: String = ""

@export_group("Station Change")
# Type "kitchen", "beverage", or "lobby". Leave blank if the station shouldn't change.
@export var station_change: String = ""
