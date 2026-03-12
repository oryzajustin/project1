class_name Augment
extends Node

## Identifies this augment on its owning Entity.
## Two augments with the same tag cannot coexist; adding a duplicate replaces the old one.
@export var tag: StringName = &""

@export var active: bool = true:
	set(value):
		active = value
		_refresh_processing()

## The Entity that owns this augment. Typed as Node to avoid parse-order dependency on Entity.
var entity: Node


func _ready() -> void:
	_refresh_processing()


## Called internally by Entity — do not call directly.
func _attach(p_entity: Node) -> void:
	entity = p_entity
	_refresh_processing()
	on_attach()


## Called internally by Entity — do not call directly.
func _detach() -> void:
	on_detach()
	entity = null
	_refresh_processing()


## Override to run setup logic when this augment is attached to an entity.
func on_attach() -> void:
	pass


## Override to run cleanup logic when this augment is removed from an entity.
func on_detach() -> void:
	pass


func _refresh_processing() -> void:
	var enabled := active and entity != null
	set_process(enabled)
	set_physics_process(enabled)
