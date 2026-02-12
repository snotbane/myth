
@tool class_name SettingInput extends Setting

const ADD_ICON := preload("uid://kvngtelx5dm1")

## This is used for the sole purpose of displaying static bindings not managed by [InputMap], e.g. [InputEventMouseMotion]. These are obviously not saved in the user preferences.
@export var read_only_bindings : Array[InputEvent]


var _preexisting_children : int
var _disabled_bindings : int = 0
## This is the number of bindings from [ProjectSettings] that cannot be modified by the user. These are not saved. If [member add_button_allow] is enabled, the user will be allowed to add and save additional bindings; this only restricts modifying bindings in [ProjectSettings].
@export var disabled_bindings : int = 0 :
	get: return _disabled_bindings + _preexisting_children
	set(value):
		_disabled_bindings = maxi(value, 0)
		for button : SettingInput_Button in binding_buttons:
			button._refresh_disabled()


## If enabled, the user may add and remove any number of additional input bindings may be added to this input. The developer may always set as many or as few bindings as desired.
@export var allow_multiple_bindings : bool = true :
	get: return add_button.visible
	set(value):
		add_button.visible = value
		update_minimum_size()


var _allow_modifiers : bool = false
## If enabled, [InputEventKey] bindings will be set on release instead of on press. While pressed, modifier keys may be added to alter the outcome.
@export var allow_modifiers : bool = false :
	get: return _allow_modifiers
	set(value):
		_allow_modifiers = value
		for button : SettingInput_Button in binding_buttons:
			button._refresh_modifiers()


@export var handle_minimum_width : float = 100.0 :
	get: return hflow_buttons.custom_minimum_size.x
	set(value): hflow_buttons.custom_minimum_size.x = value


var _binding_minimum_width : float = 40.0
@export var binding_minimum_width : float = 40.0 :
	get: return _binding_minimum_width
	set(value):
		_binding_minimum_width = value
		for button : Control in binding_buttons:
			button.custom_minimum_size.x = _binding_minimum_width


@export_group("Conflicts", "conflict_")

## The root [Node] which contains descendants that may conflict with this one. Set null to conflict with none, except those listed in [member conflict_exceptions].
@export var conflict_root : Node

## List of [SettingInput]s which will be ignored. If [member conflict_root] is null, these are the ONLY bindings that will be checked.
@export var conflict_exceptions : Array[SettingInput]


@export_group("Physical Input", "physical_")

## Advanced setting. If enabled, all bound [InputEventKey]s will be set to their [member physical_keycode] counterpart. Games generally should enable this, UI applications generally should not.
@export var physical_toggled : bool = true :
	get: return physical_check.button_pressed
	set(value):
		physical_check.button_pressed = value
		_set_physical_toggled(value)
func _set_physical_toggled(physical: bool) -> void:
	for button : SettingInput_Button in binding_buttons:
		button._refresh_physical()

## Advanced setting. If enabled, the user will be able to set whether or not input events are physical or not. Games generally should not enable this; utilities may have some reason to.
@export var physical_allow_modification : bool = false :
	get: return physical_check.visible
	set(value):
		physical_check.visible = value
		update_minimum_size()


var binding_buttons : Array :
	get: return hflow_buttons.get_children()


var bindings_from_project_settings : Array :
	get:
		if not ProjectSettings.has_setting("input/" + name): return []
		var result : Array = []
		for event : InputEvent in ProjectSettings.get_setting("input/" + name)[&"events"]:
			result.push_back(event)
		return result


var bindings_from_input_map : Array :
	get:
		if not InputMap.has_action(name): return []
		return InputMap.action_get_events(name)


var hflow_buttons : HFlowContainer
var add_button : Button
var physical_check : CheckButton


func _get_value() -> Variant:
	var result := bindings_from_project_settings if OS.has_feature(&"editor_hint") else bindings_from_input_map
	return result


func _set_value(new_value: Variant) -> void:
	if InputMap.has_action(name):
		InputMap.action_erase_events(name)

	for event : InputEvent in new_value:
		if event == null: continue

		InputMap.action_add_event(name, event)

	_value_changed()


func _init() -> void:
	super._init()

	hflow_buttons = HFlowContainer.new()
	hflow_buttons.custom_minimum_size.x = 100.0
	hflow_buttons.alignment = FlowContainer.ALIGNMENT_BEGIN
	hflow_buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox_panel.add_child(hflow_buttons)

	var vbox := VBoxContainer.new()
	hbox_panel.add_child(vbox)

	add_button = Button.new()
	add_button.visible = true
	add_button.icon = ADD_ICON
	add_button.flat = true
	add_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_button.pressed.connect(create_binding_button)
	vbox.add_child(add_button)

	physical_check = CheckButton.new()
	physical_check.visible = false
	physical_check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	physical_check.button_pressed = true
	physical_check.toggled.connect(_set_physical_toggled)
	vbox.add_child(physical_check)


func _ready() -> void:
	for event in read_only_bindings:
		create_binding_button(event, SettingInput_Button.READ_ONLY)

	super._ready()

	_value_changed()
	update_minimum_size.call_deferred()


func _value_changed() -> void:
	super._value_changed()

	_preexisting_children = binding_buttons.size()

	for child : SettingInput_Button in binding_buttons:
		child.queue_free()

	for event : InputEvent in value:
		create_binding_button(event, SettingInput_Button.REFRESH)

	set.call_deferred(&"_preexisting_children", 0)


func create_binding_button(event: InputEvent = null, create_type: int = SettingInput_Button.BEGIN_REMAP) -> SettingInput_Button:
	var result := SettingInput_Button.new(self, event, create_type)
	hflow_buttons.add_child(result, false, INTERNAL_MODE_FRONT if result.read_only else INTERNAL_MODE_DISABLED)
	update_minimum_size()
	return result


func push_bindings() -> void:
	var bindings : Array[InputEvent] = []
	for child : SettingInput_Button in binding_buttons:
		if child.is_queued_for_deletion() or child.event == null: continue
		bindings.push_back(child.event)
	value = bindings


func get_conflict_candidates() -> Array[SettingInput] :
	return conflict_exceptions.duplicate() if conflict_root == null else _get_conflict_candidates(conflict_root)
func _get_conflict_candidates(from: Node) -> Array[SettingInput] :
	var result : Array[SettingInput]
	for child in from.get_children():
		if child is SettingInput:
			if child in conflict_exceptions or self in child.conflict_exceptions: continue
			result.push_back(child)
		else:
			result.append_array(_get_conflict_candidates(child))
	return result
