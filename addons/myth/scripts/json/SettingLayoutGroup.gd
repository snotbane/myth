@tool class_name SettingLayoutGroup extends Resource

@export var same_height: bool = true:
	set(value):
		same_height = value
		update_users_minimum_size()

@export var reset_enabled: bool = false:
	set(value):
		reset_enabled = value
		for user in users:
			if user is not SettingContainer or user.reset_mode != 1: continue
			print("user : %s" % [user])
			user.refresh_reset_container_visibility()

var users: Array[Control]

var minimum_height: float:
	get:
		_flush_null_users()

		var result := 0.0
		for user in users:
			result = maxf(result, user.get_minimum_size().y)
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
	var __minimum_height__ := minimum_height
	for user in users:
		if user == ignore: continue
		user.custom_minimum_size.y = __minimum_height__


func _flush_null_users() -> void:
	while users.has(null):
		users.erase(null)

	for user in users.duplicate():
		if user is SettingContainer: continue
		users.erase(user)
