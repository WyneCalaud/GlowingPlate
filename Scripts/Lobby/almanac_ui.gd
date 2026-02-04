extends Control
signal closed

func _on_texture_button_pressed() -> void:
	closed.emit()
