@icon("res://addons/myth/script/component/property/PropertyMapper.svg")
class_name PropertyMapper
extends Component


@export_storage
var map: Array[PropertySyncer]


func _ready() -> void:
	_ready_deferred.call_deferred()


func _ready_deferred() -> void:
	_create_map()

	for sync in map:
		if sync == null:
			continue

		sync.populate(self)


func _create_map() -> void:
	pass
