class_name JsonResourceNode extends ResourceNode

## If set, the file at this path will be loaded and set as the initial [member resource], if [member resource] is null.
@export_global_file("*.json", "*.dat") var resource_initial_path: String

func _ready() -> void:
	if resource == null:
		resource = JsonResource.load_from_file(resource_initial_path)

	super._ready()


func save() -> void:
	if resource == null: return

	resource.save()
