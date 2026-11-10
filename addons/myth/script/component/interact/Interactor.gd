## Used to detect [Interactable]s. The parent of this child will determine how it handles interactions.
class_name Interactor
extends Component

## If set, this [Node] will be passed to the [Interactable] instead of this component.
@export
var source_node: Node

## Any [Interactable] with a [member Interactable.priority] less than or equal to this value will be considered for angle-based priority. This means the highest priority option will be determined by how much the [member parent] is facing the [Interactable]. [Interactable]s with a priority higher than this value will always be prioritized. NOTE: This only has an effect if [member parent] is an [Area2D] or [Area3D]. Primarily for use in third-person games.
@export
var angle_priority: int = 0


var detected_interactables: Array[Interactable]
var focused_interactable: Interactable:
	set(value):
		if focused_interactable == value: return
		focused_interactable = value

		focus_changed.emit(focused_interactable)

signal focus_changed(new_focus: Interactable)


var process_method: Callable

func _ready() -> void:
	super._ready()

	if parent is RayCast2D or parent is RayCast3D:
		process_method = _process_ray_cast

	elif parent is ShapeCast2D or parent is ShapeCast3D:
		process_method = _process_shape_cast

	elif parent is Area2D:
		process_method = _process_area_2d
		parent.body_entered.connect(_area_other_entered)
		parent.area_entered.connect(_area_other_entered)
		parent.body_exited.connect(_area_other_exited)
		parent.area_exited.connect(_area_other_exited)

	elif parent is Area3D:
		process_method = _process_area_3d
		parent.body_entered.connect(_area_other_entered)
		parent.area_entered.connect(_area_other_entered)
		parent.body_exited.connect(_area_other_exited)
		parent.area_exited.connect(_area_other_exited)

	else:
		printerr("Interactor parent must be of a valid type.")
		disable()


func _process(delta: float) -> void:
	process_method.call()


func filter_interactables(a: Interactable) -> bool:
	return a and a.enabled and _filter_interactables(a)

## Override this method to filter detected nodes. Returns true if the node in question should be detected.
func _filter_interactables(a: Interactable) -> bool:
	return true


## Override this method to sort detected nodes.
func _sort_interactables_priority(a: Interactable, b: Interactable) -> bool:
	return a.priority < b.priority


func _process_ray_cast() -> void:
	var interactable : Interactable = Myth.find_child_of_type(parent.get_collider(), "Interactable")

	focused_interactable = interactable if filter_interactables(interactable) else null


func _process_shape_cast() -> void:
	detected_interactables.clear()

	for i in parent.get_collision_count():
		var interactable : Interactable = Myth.find_child_of_type(parent.get_collider(i), "Interactable")

		if filter_interactables(interactable):
			detected_interactables.push_back(interactable)

	detected_interactables.sort_custom(_sort_interactables_priority)

	focused_interactable = detected_interactables[0] if detected_interactables else null


func _process_area_2d() -> void:
	if detected_interactables.is_empty():
		focused_interactable = null
		return

	if detected_interactables.size() == 1 or detected_interactables[0].priority > angle_priority:
		focused_interactable = detected_interactables[0]
		return

	var closest_interactable: Interactable = null
	var closest_angle: float = INF
	for e in detected_interactables:
		var spatial : Node2D = e.get_parent()
		var angle : float = parent.global_transform.x.dot(parent.global_position.direction_to(spatial.global_position))

		if angle > closest_angle:
			continue

		closest_interactable = e
		closest_angle = angle

	focused_interactable = closest_interactable


func _process_area_3d() -> void:
	if detected_interactables.is_empty():
		focused_interactable = null
		return

	if detected_interactables.size() == 1 or detected_interactables[0].priority > angle_priority:
		focused_interactable = detected_interactables[0]
		return

	var closest_interactable: Interactable = null
	var closest_angle: float = INF
	for e in detected_interactables:
		var spatial : Node3D = e.get_parent()
		var angle : float = parent.global_basis.z.dot(parent.global_position.direction_to(spatial.global_position))

		if angle > closest_angle:
			continue

		closest_interactable = e
		closest_angle = angle

	focused_interactable = closest_interactable


func _area_other_entered(other: Node) -> void:
	var interactable: Interactable = Myth.find_child_of_type(other, "Interactable")

	if filter_interactables(interactable):
		detected_interactables.push_back(interactable)

	detected_interactables.sort_custom(_sort_interactables_priority)


func _area_other_exited(other: Node) -> void:
	var interactable: Interactable = Myth.find_child_of_type(other, "Interactable")

	detected_interactables.erase(interactable)


## Emits when an [Interactable] was interacted with.
signal interact_started

## Emits when we tried to interact, but no [Interactable] was found.
signal interact_failed

## Emits after [member interact_started] and the interactable action completed.
signal interact_finished


func try_interact(emit_signals: bool = true):
	await interact_with(focused_interactable, emit_signals)


func interact_with(other: Interactable, emit_signals: bool = false):
	if other == null:
		if emit_signals:
			interact_failed.emit()

		return false

	focused_interactable = other

	if emit_signals:
		interact_started.emit()

	await focused_interactable.interact(source_node if source_node else self)

	if emit_signals:
		interact_finished.emit()


func _on_input_interact_pressed() -> void:
	try_interact()
