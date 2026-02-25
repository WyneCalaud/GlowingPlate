extends CanvasLayer

@onready var dim = $Dim
@onready var panel = $TextureRect
@onready var text_label = $TextureRect/Label

signal intro_closed

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	# ONLY DIM receives clicks
	dim.mouse_filter = Control.MOUSE_FILTER_STOP

	# These must ignore input
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	dim.gui_input.connect(_on_clicked)


func setup_intro(text:String):
	text_label.text = text


func _on_clicked(event):
	if event is InputEventMouseButton and event.pressed:
		intro_closed.emit()
		queue_free()
