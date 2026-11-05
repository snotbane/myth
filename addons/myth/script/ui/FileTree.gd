## Creates a tree containing a specific set of files or folders within the project.
@tool
class_name FileTree
extends Tree

enum {
	COLUMN_PATH,
}

signal file_selected(path: String)

## If enabled, this will only create a list of non-nested files. This value is always the same as [member hide_root], but refreshes the tree when set.
@export
var leaf_only: bool = false:
	get: return hide_root
	set(value):
		hide_root = value
		refresh()

@export
var hide_exts: bool = false:
	set(value):
		hide_exts = value
		refresh()

## List of files to explicitly include.
@export_file
var file_paths: PackedStringArray:
	set(value):
		file_paths = value
		refresh()

## List of dirs to get files from.
@export_dir
var dir_paths: PackedStringArray:
	set(value):
		dir_paths = value
		refresh()

## List of glob patterns to filter when searching in [member dir_paths].
@export
var dir_globs: PackedStringArray:
	set(value):
		dir_globs = value
		refresh()

var root : TreeItem

var paths: PackedStringArray = []
var selecting: bool = false

func _ready() -> void:
	item_selected.connect((func() -> void:
		if selecting:
			return

		selecting = true

		var selected_item := get_selected()
		if selected_item == null:
			return

		if selected_item.has_meta(&"path"):
			file_selected.emit(selected_item.get_meta(&"path"))

		if selected_item.get_child_count() > 0:
			selected_item.collapsed = not selected_item.collapsed

		selecting = false
	))

	refresh()

func refresh() -> void:
	paths.clear()

	for path in file_paths:
		if path not in paths:
			path = ResourceUID.ensure_path(path)
			if path.is_empty():
				continue

			paths.push_back(path)

	for dir in dir_paths:
		for path in Myth.get_paths_in_folder(dir, dir_globs):
			if path not in paths:
				path = ResourceUID.ensure_path(path)
				if path.is_empty():
					continue

				paths.push_back(path)

	paths.sort()


	clear()
	root = create_item()
	root.set_text(COLUMN_PATH, "/")


	for path in paths:
		if path.begins_with("res://"):
			path = path.substr("res://".length())

		var dir_item := create_or_find_dir_item(path)
		create_file_item(path, dir_item)


func create_or_find_dir_item(path: String) -> TreeItem:
	if leaf_only:
		return root

	var splits := path.split("/")
	var result : TreeItem = root
	for i in splits.size() - 1:
		var parent : TreeItem = null
		for child in result.get_children():
			if child.get_text(COLUMN_PATH) == splits[i]:
				parent = child
				break
		if parent == null:
			parent = create_item(result)
			parent.set_text(COLUMN_PATH, splits[i])

		result = parent

	return result


func create_file_item(path: String, dir_item: TreeItem) -> TreeItem:
	var result := create_item(dir_item)
	result.set_meta(&"path", path)

	var item_text := path.get_file()
	if hide_exts:
		item_text = item_text.get_basename()

	result.set_text(COLUMN_PATH, item_text)
	if not FileAccess.file_exists(path):
		result.set_custom_color(COLUMN_PATH, Color.INDIAN_RED)

	return result
