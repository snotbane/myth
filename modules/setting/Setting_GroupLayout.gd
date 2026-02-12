
@tool class_name Setting_GroupLayout extends Resource

## If enabled, all Settings in this group are guaranteed to have the same minimum height, which is to be the largest of all in the group.
var _ensure_same_minimum_height : bool = true
@export var ensure_same_minimum_height : bool = true :
	get: return _ensure_same_minimum_height
	set(value):
		_ensure_same_minimum_height = value
		update_users_minimum_size()

var users : Array[Control]

var minimum_height : float :
	get:
		var result := 0.0
		for user in users:
			result = maxf(result, user.panel_container.get_minimum_size().y)
			result = maxf(result, user.custom_minimum_size.y)
		return result


func _init() -> void:
	resource_local_to_scene = true


func add_user(user: Control) -> void:
	_flush_null_users()

	if users.has(user): return

	users.push_back(user)
	user.minimum_size_changed.connect(update_users_minimum_size.bind(user))
	user.tree_exiting.connect(remove_user.bind(user))
	update_users_minimum_size()


func remove_user(user: Control) -> void:
	if not users.has(user): return

	users.erase(user)
	user.minimum_size_changed.disconnect(update_users_minimum_size)
	user.tree_exiting.disconnect(remove_user)
	update_users_minimum_size()


func update_users_minimum_size(ignore: Control = null) -> void:
	for user in users:
		if user == ignore: continue
		user.update_minimum_size()


func _flush_null_users() -> void:
	while users.has(null):
		users.erase(null)

	var to_remove = null
	for user in users:
		if user is Setting: continue
		if to_remove == null: to_remove = []
		to_remove.push_back(user)
	if to_remove == null: return

	for user in to_remove:
		users.erase(user)

