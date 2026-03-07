
@tool class_name ResourceCollection extends Resource

signal refreshed


@export var type_filter : String

var _path : String
@export_dir var path : String :
	get: return _path
	set(value):
		_path = value

		refresh()


@export_storage var resources : Array[Resource]


func refresh() -> void:
	resources.clear()

	if not _path.is_empty():
		for sub_path in Myth.get_paths_in_folder(path):
			if not ResourceLoader.exists(sub_path, type_filter): continue

			var res := load(sub_path)
			# if res == null: continue
			# if not (type_filter.is_empty() or Myth.is_object_of_type(res, type_filter)): continue

			resources.push_back(res)

	refreshed.emit()
	print(path)
	print(Myth.get_paths_in_folder(path))
