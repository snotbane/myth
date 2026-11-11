@icon("res://addons/myth/script/component/interact/Interactable.svg")
class_name Interactable
extends Component

signal interact_started
signal interact_finished

## Helps the player identify the object in the game.
@export
var text: String

## [Interactable]s with a higher priority will be appear as the active object if the player has detected multiple of them.
@export
var priority: int


func interact(source: Node):
	interact_started.emit()
	await _interact(source)

	interact_finished.emit()


func _interact(source: Node):
	pass
