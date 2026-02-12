
class_name TerminalAutoload extends Node

static var DEFAULT_SCENE : PackedScene :
	get: return load("uid://c1nlgw0r4lj06")


func _init() -> void:
	add_child.call_deferred(DEFAULT_SCENE.instantiate())
