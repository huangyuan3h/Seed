class_name PowerGrid
extends RefCounted
## Small abstract power network: generators set supply, consumers report demand,
## and every consumer runs at the same satisfaction ratio.

signal changed

var supply: float = 0.0
var demand: float = 0.0
var satisfaction: float = 1.0

var _consumers: Array[Node] = []
var _generators: Array[Node] = []
var _manual_supply: float = 0.0


func add_consumer(consumer: Node) -> void:
	if consumer == null or _consumers.has(consumer):
		return
	_consumers.append(consumer)
	refresh()


func remove_consumer(consumer: Node) -> void:
	_consumers.erase(consumer)
	refresh()


func has_consumer(consumer: Node) -> bool:
	return _consumers.has(consumer)


func add_generator(generator: Node) -> void:
	if generator == null or _generators.has(generator):
		return
	_generators.append(generator)
	refresh()


func remove_generator(generator: Node) -> void:
	_generators.erase(generator)
	refresh()


func set_supply(value: float) -> void:
	_manual_supply = maxf(0.0, value)
	refresh()


func refresh() -> void:
	var generated := 0.0
	for generator in _generators:
		if generator == null or not is_instance_valid(generator):
			continue
		if generator.has_method("get_power_supply"):
			generated += maxf(0.0, float(generator.call("get_power_supply")))
	supply = maxf(_manual_supply, generated)
	demand = 0.0
	for consumer in _consumers:
		if consumer == null or not is_instance_valid(consumer):
			continue
		if consumer.has_method("get_power_demand"):
			demand += maxf(0.0, float(consumer.call("get_power_demand")))
	satisfaction = 1.0 if demand <= 0.001 else clampf(supply / demand, 0.0, 1.0)
	changed.emit()


func get_supply_or_zero() -> float:
	return supply


func get_satisfaction() -> float:
	return satisfaction


func get_demand() -> float:
	return demand
