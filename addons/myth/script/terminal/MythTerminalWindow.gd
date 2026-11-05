extends Window

func toggle_visibility() -> void:
	visible = not visible


func _ready() -> void:
	hide()


func _on_input_toggle_pressed() -> void:
	toggle_visibility()
