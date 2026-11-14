## Defines a connections of properties that are guaranteed to always be equal. If one value changes, all others change to update the new value.
@icon("res://addons/myth/script/component/property/PropertySyncer.svg")
class_name PropertySyncer
extends Resource

static func get_signal_data(sig: Signal) -> Variant:
	for s: Dictionary in sig.get_object().get_signal_list():
		if s.name == sig.get_name():
			return s
	return null

var host: Node
var _synced_value: Variant = null


func populate(__host__: Node) -> void:
	host = __host__


@export_storage
var connections: Dictionary[NodePath, NodePath]


func localize_path(from: Node, path: NodePath) -> NodePath:
	if from == host or path.is_absolute():
		return path

	return NodePath(String(host.get_path_to(from)) + "/" + String(path))


func get_path_as_signal(path: NodePath) -> Signal:
	var result = get_path_value(path)
	if result is Signal:
		return result

	return Signal()


func get_path_value(path: NodePath) -> Variant:
	return Myth.get_node_path_value(host, path)

func set_path_value(path: NodePath, value: Variant) -> void:
	Myth.set_node_path_value(host, path, value)


func set_synced_value(value: Variant) -> void:
	is_updating = true

	_synced_value = value
	for signal_path in connections:
		set_path_value(connections[signal_path], _synced_value)

	is_updating = false



## Sets the synced value to the value at [param path] and propogates it to all feeder connections.
func push_path(path: NodePath) -> void:
	set_synced_value(get_path_value(path))


func pull_path(path: NodePath) -> void:
	is_updating = true

	set_path_value(path, _synced_value)

	is_updating = false


func _add_and_connect_signal_to_property(signal_path: NodePath, property_path: NodePath) -> void:
	var sig : Signal = get_path_as_signal(signal_path)
	if sig.is_null():
		printerr("Signal at path '%s' does not exist." % signal_path)
		breakpoint
		return

	var arg_count: int = get_signal_data(sig).args.size()
	match arg_count:
		0: sig.connect(_property_updated_0.bind(property_path))
		1: sig.connect(_property_updated_1)
		_:
			printerr("%s has too many arguments (%s). Must have 0 or 1." % [
				sig.get_name(),
				arg_count,
			])
			return

	connections[signal_path] = property_path


func add_connection_push(signal_path: NodePath, property_path: NodePath, from: Node = host) -> PropertySyncer:
	if host == null:
		printerr("Host is null.")
		return

	signal_path = localize_path(from, signal_path)
	property_path = localize_path(from, property_path)

	_add_and_connect_signal_to_property(signal_path, property_path)
	push_path(property_path)

	return self


## Adds a connection and updates the value at [param path] to match the collective.
func add_connection_pull(signal_path: NodePath, property_path: NodePath, from: Node = host) -> PropertySyncer:
	if is_empty():
		add_connection_push(signal_path, property_path, from)
		return

	if host == null:
		printerr("Host is null.")
		return

	signal_path = localize_path(from, signal_path)
	property_path = localize_path(from, property_path)

	_add_and_connect_signal_to_property(signal_path, property_path)
	pull_path(property_path)

	return self


func remove_connection(signal_path: NodePath, from: Node = host) -> void:
	signal_path = localize_path(from, signal_path)
	var sig: Signal = get_path_value(signal_path)

	if sig.is_connected(_property_updated_0):
		sig.disconnect(_property_updated_0)

	elif sig.is_connected(_property_updated_1):
		sig.disconnect(_property_updated_1)

	connections.erase(signal_path)


func clear_connections() -> void:
	for signal_path in connections:
		remove_connection(signal_path)

	connections.clear()


# @export_storage
# var connections: Dictionary[NodePath, NodePath] = {}:
# 	set(value):
# 		if Engine.is_editor_hint():
# 			connections = value
# 		else:
# 			clear()

# 			for signal_path in value:
# 				_add_signal_property_pair(get_path_value(signal_path), value[signal_path])

# @export_storage
# var receivers: Array[NodePath]


# func _add_signal_property_pair(sig: Signal, path: NodePath) -> bool:
# 	var arg_count: int = get_signal_data(sig).args.size()
# 	match arg_count:
# 		0: sig.connect(_property_updated_0.bind(path))
# 		1: sig.connect(_property_updated_1.bind(path))
# 		_:
# 			printerr("%s has too many arguments (%s). Must have 0 or 1." % [
# 				sig.get_name(),
# 				arg_count,
# 			])
# 			return false

# 	connections[get_path_to_signal(sig)] = path
# 	return true


# ## Returns the current
# func get_synced_value() -> Variant:
# 	return get_path_value(connections[connections.keys()[0]]) if connections else null


# func get_path_value(path: NodePath) -> Variant:
# 	return Myth.get_node_path_value(host, path)


# func get_path_to_signal(sig: Signal) -> NodePath:
# 	return NodePath(
# 		String(host.get_path_to(sig.get_object()))
# 		+ ":" + sig.get_name()
# 	)


func is_empty() -> bool:
	return connections.is_empty()

var is_updating: bool

func _property_updated_0(property_path: NodePath) -> void:
	if is_updating: return

	push_path(property_path)


func _property_updated_1(value: Variant) -> void:
	if is_updating: return

	set_synced_value(value)


func _init(__host__: Node = null) -> void:
	if __host__:
		populate(__host__)

	connections = {}


func _to_string() -> String:
	var result := "PropertySync : %s = %s" % [
		host,
		_synced_value
	]
	for path in connections:
		result += "\n\t%s -> %s" % [
			connections[path],
			path,
		]

	return result


# ## Adds the signal-property pair, and syncs the value with the existing value.
# func add_connection_pull(sig: Signal, path: NodePath) -> PropertySyncer:
# 	if _add_signal_property_pair(sig, path):
# 		if not is_empty():
# 			Myth.set_node_path_value(sig.get_object(), path, get_synced_value())

# 	return self


# ## Adds the signal-property pair, and sets every other value to match the incoming value.
# func add_connection_push(sig: Signal, path: NodePath) -> PropertySyncer:
# 	if _add_signal_property_pair(sig, path):
# 		is_updating = true

# 		var value := Myth.get_node_path_value(host, path)

# 		for k in connections:
# 			Myth.set_node_path_value(host, connections[k], value)

# 		for r in receivers:
# 			Myth.set_node_path_value(host, r, value)

# 		is_updating = false

# 	return self


# ## Adds a single receiver path and sets its value to the synced value.
# func add_receiver_pull(path: NodePath) -> PropertySyncer:
# 	if not receivers.has(path):
# 		receivers.push_back(path)

# 	if not is_empty():
# 		Myth.set_node_path_value(host, path, get_synced_value())

# 	return self


# ## Adds a single receiver path, and updates everything else to update to its value.
# func add_receiver_push(path: NodePath) -> PropertySyncer:
# 	if not receivers.has(path):
# 		receivers.push_back(path)

# 	is_updating = true

# 	var value := Myth.get_node_path_value(host, path)

# 	for k in connections:
# 		Myth.set_node_path_value(host, connections[k], value)

# 	for r in receivers:
# 		if path == r:
# 			continue
# 		Myth.set_node_path_value(host, r, value)

# 	is_updating = false

# 	return self


# func remove_signal(sig: Signal) -> void:
# 	connections.erase(get_path_to_signal(sig))


# func add_property_receiver(path: NodePath) -> void:
# 	receivers.push_back(path)
# 	Myth.set_node_path_value(host, path, get_synced_value())

# func remove_property_receiver(path: NodePath) -> void:
# 	receivers.erase(path)


# ## Use this to manually push a new value to every receiver.
# func push_value(value: Variant) -> void:
# 	if is_updating: return
# 	is_updating = true

# 	for k in connections:
# 		Myth.set_node_path_value(host, connections[k], value)

# 	for r in receivers:
# 		Myth.set_node_path_value(host, r, value)

# 	is_updating = false
