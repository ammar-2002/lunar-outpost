class_name HealthSystem
extends RefCounted

var _resources: ResourceManager
var _state: SimulationState
var _config: SimulationConfig


func setup(
    resource_manager: ResourceManager,
    simulation_state: SimulationState,
    config: SimulationConfig
) -> void:
    _resources = resource_manager
    _state = simulation_state
    _config = config


func advance(hours: float) -> void:
    _state.fitness = clampf(
        _state.fitness - _config.fitness_decay_per_hour * hours,
        0.0,
        100.0
    )
    _state.happiness = clampf(
        _state.happiness - _config.happiness_decay_per_hour * hours,
        0.0,
        100.0
    )


func exercise(duration_hours: float, fitness_gain_per_hour: float) -> bool:
    if duration_hours <= 0.0 or fitness_gain_per_hour < 0.0:
        return false

    _state.fitness = clampf(
        _state.fitness + duration_hours * fitness_gain_per_hour,
        0.0,
        100.0
    )
    return true


func can_perform_activity(required_fitness: float) -> bool:
    return _state.fitness >= required_fitness


func eat_food(food_id: StringName, quantity: float, fitness_effect: float = 0.0) -> bool:
    if quantity <= 0.0:
        return false

    var food_key := StringName("food_%s" % String(food_id))
    if not _resources.consume(food_key, quantity):
        return false

    # Temporary prototype hook. Later, calculate this from nutrition data
    # and cumulative diet rather than applying a direct instant fitness boost.
    _state.fitness = clampf(_state.fitness + fitness_effect, 0.0, 100.0)
    return true
