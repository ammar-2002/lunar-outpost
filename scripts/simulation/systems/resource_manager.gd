class_name ResourceManager
extends RefCounted
## The only API systems should use to change shared resource quantities.

signal resource_changed(resource_id: StringName, new_amount: float)

var _state: SimulationState


func setup(simulation_state: SimulationState) -> void:
    _state = simulation_state


func get_amount(resource_id: StringName) -> float:
    if _state == null:
        return 0.0
    return float(_state.resources.get(resource_id, 0.0))


func can_consume(resource_id: StringName, amount: float) -> bool:
    if amount < 0.0:
        return false
    return get_amount(resource_id) + 0.000001 >= amount


func consume(resource_id: StringName, amount: float) -> bool:
    if amount < 0.0 or not can_consume(resource_id, amount):
        return false

    var new_amount := maxf(0.0, get_amount(resource_id) - amount)
    _state.resources[resource_id] = new_amount
    resource_changed.emit(resource_id, new_amount)
    return true


func produce(
    resource_id: StringName,
    amount: float,
    capacity: float = -1.0
) -> void:
    if _state == null or amount <= 0.0:
        return

    var new_amount := get_amount(resource_id) + amount
    if capacity >= 0.0:
        new_amount = minf(new_amount, capacity)

    _state.resources[resource_id] = new_amount
    resource_changed.emit(resource_id, new_amount)


## All-or-nothing transaction: either every cost is paid or none are.
func consume_many(costs: Dictionary) -> bool:
    for resource_id in costs:
        if not can_consume(StringName(resource_id), float(costs[resource_id])):
            return false

    for resource_id in costs:
        consume(StringName(resource_id), float(costs[resource_id]))

    return true


func produce_many(outputs: Dictionary) -> void:
    for resource_id in outputs:
        produce(StringName(resource_id), float(outputs[resource_id]))


func set_amount(resource_id: StringName, amount: float) -> void:
    if _state == null:
        return
    var safe_amount := maxf(0.0, amount)
    _state.resources[resource_id] = safe_amount
    resource_changed.emit(resource_id, safe_amount)
