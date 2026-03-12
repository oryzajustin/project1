class_name Entity
extends Node

signal damaged(amount: float, source: Node)
signal healed(amount: float)
signal died()
signal augment_added(augment: Node)
signal augment_removed(augment: Node)

@export var max_health: float = 100.0
@export var health: float = 100.0

var is_alive: bool:
	get: return health > 0.0

@export var _augments: Dictionary = {}


## Find the Entity component on a node (checks the node itself, then direct children).
static func of(node: Node) -> Entity:
	if node is Entity:
		return node as Entity
	for child in node.get_children():
		if child is Entity:
			return child as Entity
	return null


func _ready() -> void:
	add_to_group(&"entities")
	for child in get_children():
		if child is Augment:
			_register_augment(child)


func _register_augment(augment: Node) -> void:
	if augment.tag.is_empty():
		augment.tag = StringName(augment.name)
	if _augments.has(augment.tag):
		push_warning("Duplicate augment tag '%s' on Entity '%s'" % [augment.tag, name])
	_augments[augment.tag] = augment
	augment._attach(self)
	augment_added.emit(augment)


func add_augment(augment: Node) -> void:
	if augment.tag.is_empty():
		augment.tag = StringName(augment.name)
	if _augments.has(augment.tag):
		remove_augment(augment.tag)
	_augments[augment.tag] = augment
	add_child(augment)
	augment._attach(self)
	augment_added.emit(augment)


func remove_augment(tag: StringName) -> Node:
	var b: Node = _augments.get(tag)
	if b == null:
		return null
	_augments.erase(tag)
	b._detach()
	remove_child(b)
	augment_removed.emit(b)
	return b

	
func get_augment(tag: StringName) -> Node:
	return _augments.get(tag)


func has_augment(tag: StringName) -> bool:
	return _augments.has(tag)


func get_all_augments() -> Array:
	return _augments.values()


func take_damage(amount: float, source: Node = null) -> void:
	if not is_alive:
		return
	health = maxf(health - amount, 0.0)
	damaged.emit(amount, source)
	if not is_alive:
		died.emit()


func heal(amount: float) -> void:
	if not is_alive:
		return
	health = minf(health + amount, max_health)
	healed.emit(amount)
