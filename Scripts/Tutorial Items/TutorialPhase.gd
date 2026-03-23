extends Resource
class_name TutorialPhase

# The name of the group for your own organization
@export var phase_name: String = "New Phase"

# This creates an array in the Inspector specifically for your TutorialSteps!
@export var steps: Array[TutorialStep] = []
