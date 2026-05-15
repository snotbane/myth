## This is a helper [Node] that moves its parent to the local transform identity over a time, and then deletes itself.
class_name QuickAttachment extends Timer

static func remove_all_quick_attachments(node: Node) -> void:
	for child in node.get_children():
		if child is QuickAttachment:
			child.queue_free()


## Detaches the node in its world place.
static func detach(node: Node) -> void:
	var gt = node.global_transform
	var root = node.get_tree().root
	node.get_parent().remove_child(node)
	root.add_child(node)
	node.global_transform = gt


## Reattaches the [child] to the [parent] in world space, but that's it. No animation. If a [QuickAttachment] already exists, it will be overwritten.
static func attach_in_place(child: Node, parent: Node) -> QuickAttachment:
	assert((child is Node2D and parent is Node2D) or (child is Node3D and parent is Node3D), "Parent '%s' and child '%s' must both be a Node2D or Node3D, and they must be the same." % [parent, child])

	var gt
	var apply_global := child.is_inside_tree()
	if apply_global:
		gt = child.global_transform
		child.get_parent().remove_child(child)

	parent.add_child(child)

	if apply_global:
		child.global_transform = gt

	remove_all_quick_attachments(child)

	var result := QuickAttachment.new(child.transform)
	child.add_child(result)
	return result


static func attach_instantly(child: Node, parent: Node) -> void:
	var result := QuickAttachment.attach_in_place(child, parent)
	result.queue_free()


static func attach_with_duration(child: Node, parent: Node, duration_seconds: float = 1.0) -> QuickAttachment:
	var result := QuickAttachment.attach_in_place(child, parent)

	result.wait_time = duration_seconds
	result.start()

	return result

## Attaches the [child] to the [parent] in world space, using the provided [curve] (starting at 0.0).
static func attach_with_curve(child: Node, parent: Node, curve: Curve) -> QuickAttachment:
	var result := QuickAttachment.attach_with_duration(child, parent, curve.max_domain)

	result.curve = curve
	result.alpha_method = result.get_alpha_curve

	return result


var curve : Curve
var alpha_method : Callable = get_alpha_linear
var process_method : Callable
var original_transform
var affect_scale : bool = false


func _init(__original_transform__) -> void:
	original_transform = __original_transform__
	process_method = process_3d if original_transform is Transform3D else process_2d

	one_shot = true
	autostart = false
	timeout.connect(queue_free)


func _exit_tree() -> void:
	stop()
	if get_parent() is Node2D:
		get_parent().transform = Transform2D.IDENTITY
	elif get_parent() is Node3D:
		get_parent().transform = Transform3D.IDENTITY


func _process(delta: float) -> void:
	if is_stopped(): return

	var alpha : float = alpha_method.call()
	process_method.call(alpha)


func get_alpha_linear() -> float:
	return 1.0 - (time_left / wait_time)

func get_alpha_curve() -> float:
	return curve.sample(get_alpha_linear())


func process_2d(alpha: float) -> void:
	get_parent().position = lerp(original_transform.origin, Vector2.ZERO, alpha)
	get_parent().rotation = lerp(original_transform.get_rotation(), 0.0, alpha)

func process_3d(alpha: float) -> void:
	get_parent().position = lerp(original_transform.origin, Vector3.ZERO, alpha)
	get_parent().rotation = lerp(original_transform.basis.get_euler(), Vector3.ZERO, alpha)
