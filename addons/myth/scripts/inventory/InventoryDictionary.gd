## Simple, unordered dictionary of [ItemDefinition]s and their quantities. The quantity value must be an [int] or [float]. Note, this type of [Inventory] works with [ItemDefinition]s only. If you need to store individual [Item]s, use [InventoryArray].
@tool class_name InventoryDictionary extends Inventory

var _items : Dictionary[ItemDefinition, Variant]
@export var items : Dictionary[ItemDefinition, Variant] :
	get: return _items
	set(value):
		_items.clear()
		add_items(value)


## If enabled, this [Inventory] will limit the quantity of [ItemDefinition]s based on their [ItemDefinition.capacity].
@export var restrict_capacity : bool = true

## If enabled, this [Inventory] will not automatically flush keys with zero values.
@export var keep_empties : bool = false

## If enabled, this [Inventory] will allow a negative quantity to be listed.
@export var allow_negatives : bool = false

var _modified_enabled : bool = true
func _modified_emit() -> void:
	if not _modified_enabled: return
	modified.emit()


## Returns the quantity of the item as an [int] or [float].
func get_quantity(def: ItemDefinition) -> Variant:
	return _items.get(def, def.quantity_default)


## Returns true if there is any non-zero quantity inside the [Inventory].
func has_any(def: ItemDefinition) -> bool:
	return get_quantity(def) != def.quantity_default


## Sets the float amount of an [ItemDefinition]. Returns the leftover amount that can't be stored inside.
func set_item_quantity(def: ItemDefinition, quantity: Variant) -> Variant:
	if quantity == null: quantity = def.quantity_default

	var prev := get_quantity(def)
	assert(typeof(quantity) == typeof(prev), "Quantity must match the ItemDefinition's quantity type.")

	if quantity < 0.0 and not allow_negatives: return quantity

	_items[def] = clamp(quantity, -def.capacity, def.capacity) if (restrict_capacity and not def.capacity_is_unlimited) else quantity

	if is_zero_approx(quantity) and not keep_empties and not Engine.is_editor_hint():
		_items.erase(def)

	if not is_equal_approx(prev, quantity): _modified_emit()
	return quantity - _items[def]


## Removes all of the given [param def] from this [Inventory].
func clear_item(def: ItemDefinition) -> Variant:
	return set_item_quantity(def, null)


## Adds the quantity of an [ItemDefinition] from this [Inventory]. Returns the leftover quantity that couldn't fit inside.
func add_item(def: ItemDefinition, quantity: Variant) -> Variant:
	return set_item_quantity(def, get_quantity(def) + quantity)

func add_items(dict: Dictionary[ItemDefinition, Variant]) -> Dictionary[ItemDefinition, Variant]:
	var result : Dictionary[ItemDefinition, Variant] = {}
	for def: ItemDefinition in dict:
		var leftover := add_item(def, dict[def])
		if leftover != def.quantity_default: result[def] = leftover
	return result

## Moves a specified quantity of an item from this [Inventory] to another. Leftover items will not be moved.
func transfer_item_to(other: InventoryDictionary, def: ItemDefinition, quantity: Variant) -> void:
	var leftover := other.add_item(def, quantity)
	self.add_item(def, leftover - quantity)

## Moves all of one type of item from this [Inventory] to another.
func transfer_item_all_to(other: InventoryDictionary, def: ItemDefinition) -> void:
	self.transfer_item_to(other, def, self.get_quantity(def))

## Moves all items from one [Inventory] to another. Leftover items will be returned to the original [Inventory].
func transfer_all_to(other: InventoryDictionary) -> void:
	for item: ItemDefinition in _items:
		self.transfer_item_all_to(other, item)


## Deletes all items from the [Inventory]. Returns true if the [Inventory] had anything inside.
func clear_all() -> bool:
	if _items.is_empty(): return false

	_items.clear()
	modified.emit()

	return true

## If there are any [ItemDefinition]s with near-zero quantities, those entries will be removed. Returns true if anything was modified. This will not do anything if [member keep_empties] is false.
func flush_empties() -> bool:
	var any_modified := false
	for k in _items.keys():
		if not has_any(k):
			_items.erase(k)
			any_modified = true
	if any_modified:
		modified.emit()
	return any_modified


