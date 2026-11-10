## An [Area3D] that keeps track of which nodes_inside are inside of it. By default, [member monitoring] is true and [member monitorable] is false. Additionally, bodies and areas are homogenized into a single group.
class_name SensorArea3D
extends Area3D

signal other_entered(other: Node3D)
signal other_exited(other: Node3D)

var nodes_inside: Array[Node3D]
var _all_nodes_inside: Array[Node3D]
var _exceptions: Array[Node3D]

var is_empty: bool:
	get: return nodes_inside.is_empty()


func _init() -> void:
	area_entered.connect(_on_other_entered)
	area_exited.connect(_on_other_exited)
	body_entered.connect(_on_other_entered)
	body_exited.connect(_on_other_exited)


func _on_other_entered(other: Node3D) -> void:
	if _all_nodes_inside.has(other):
		return

	_all_nodes_inside.push_back(other)

	if _exceptions.has(other):
		return

	nodes_inside.push_back(other)
	_other_entered(other)
	other_entered.emit(other)
func _other_entered(other: Node3D) -> void: pass


func _on_other_exited(other: Node3D) -> void:
	_all_nodes_inside.erase(other)

	if _exceptions.has(other) or not nodes_inside.has(other):
		return

	nodes_inside.erase(other)
	_other_exited(other)
	other_exited.emit(other)
func _other_exited(other: Node3D) -> void: pass


func add_exception(other: Node3D) -> void:
	if _exceptions.has(other):
		return

	if not _all_nodes_inside.has(other):
		nodes_inside.erase(other)
		_other_exited(other)
		other_exited.emit(other)

	_exceptions.push_back(other)


func remove_exception(other: Node3D) -> void:
	if not _exceptions.has(other):
		return

	_exceptions.erase(other)

	if _all_nodes_inside.has(other):
		nodes_inside.push_back(other)
		_other_entered(other)
		other_entered.emit(other)
