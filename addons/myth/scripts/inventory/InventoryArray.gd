## Simple, unordered [Array] of [Item]s. Preserves the [Item]s and all their data.
@tool class_name InventoryArray extends Inventory

var _items : Array[Item]
@export var items : Array[Item] :
	get: return _items
	set(value):
		_items.clear()
		add_items(value)


## Override this method to give functionality to limiting what can be added.
func _can_add_item(item: Item) -> bool:
	return true


## Tries to add the item to this [Inventory]. Returns true if succeeded.
func add_item(item: Item) -> bool:
	var result := _add_item(item)
	if result: modified.emit()
	return result
func _add_item(item: Item) -> bool:
	if not _can_add_item(item) and not Engine.is_editor_hint(): return false
	_items.push_back(item)
	return true


## Tries to add multiple items to this [Inventory]. Returns a new list of items that could not be added.
func add_items(arr: Array[Item]) -> Array[Item]:
	var any_modified := false
	var result : Array[Item] = []
	for item in arr:
		if _add_item(item):
			any_modified = true
		else:
			result.push_back(item)
	if any_modified: modified.emit()
	return result

## Removes the [param item] from this [Inventory]. Returns true if succeeded, false if the item did not exist.
func remove_item(item: Item) -> bool:
	var result := _remove_item(item)
	if result: modified.emit()
	return result
func _remove_item(item: Item) -> bool:
	if not _items.has(item): return false

	_items.erase(item)
	return true

## Tries to remove multiple items from this [Inventory]. Returns a new list of items that could not be removed, because they did not exist in here.
func remove_items(arr: Array[Item]) -> Array[Item]:
	var any_modified := false
	var result : Array[Item] = []
	for item in arr:
		if _remove_item(item):
			any_modified = true
		else:
			result.push_back(item)
	if any_modified: modified.emit()
	return result


## Moves the [param item] from this [Inventory] to another. Returns true if succeeded.
func transfer_item_to(other: InventoryArray, item: Item) -> bool:
	var result := _transfer_item_to(other, item)
	if result: modified.emit()
	return result
func _transfer_item_to(other: InventoryArray, item: Item) -> bool:
	if not self._items.has(item): return false
	if not other._add_item(item): return false
	self._remove_item(item)
	return true

## Moves the items in [param arr] from this [Inventory] to another. Items that cannot be moved will remain here.
func transfer_items_to(other: InventoryArray, arr: Array[Item]) -> void:
	var any_modified := false
	for item in arr:
		self._transfer_item_to(other, item)
		any_modified = true
	if any_modified: modified.emit()

## Moves all items from this [Inventory] to another. Items that cannot be moved will remain here.
func transfer_all_items_to(other: InventoryArray) -> void:
	transfer_items_to(other, _items)
