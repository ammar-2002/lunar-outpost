extends RefCounted
class_name OutpostResourceManager

signal resource_changed(resource_id: String, new_amount: float, delta: float)
signal shortage(resource_id: String, requested: float, available: float)

var state: OutpostSimulationState

func setup(sim_state: OutpostSimulationState) -> void:
    state = sim_state

func amount(resource_id: String) -> float:
    return float(state.resources.get(resource_id, 0.0))

func can_consume(resource_id: String, quantity: float) -> bool:
    return quantity >= 0.0 and amount(resource_id) + 0.000001 >= quantity

func consume(resource_id: String, quantity: float) -> bool:
    if quantity <= 0.0:
        return true
    var available := amount(resource_id)
    if available + 0.000001 < quantity:
        shortage.emit(resource_id, quantity, available)
        return false
    _set_amount(resource_id, available - quantity)
    return true

func produce(resource_id: String, quantity: float, cap: float = -1.0) -> float:
    if quantity <= 0.0:
        return 0.0
    var old := amount(resource_id)
    var new_value := old + quantity
    if cap >= 0.0:
        new_value = minf(new_value, cap)
    _set_amount(resource_id, new_value)
    return new_value - old

func consume_many(costs: Dictionary) -> bool:
    for key in costs:
        if not can_consume(str(key), float(costs[key])):
            shortage.emit(str(key), float(costs[key]), amount(str(key)))
            return false
    for key in costs:
        consume(str(key), float(costs[key]))
    return true

func set_amount(resource_id: String, value: float) -> void:
    _set_amount(resource_id, maxf(0.0, value))

func _set_amount(resource_id: String, value: float) -> void:
    var old := amount(resource_id)
    state.resources[resource_id] = maxf(0.0, value)
    var actual := float(state.resources[resource_id])
    if not is_equal_approx(old, actual):
        resource_changed.emit(resource_id, actual, actual - old)
