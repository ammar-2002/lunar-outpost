class_name LifeSupportSystem
extends RefCounted

var _resources: ResourceManager
var _config: SimulationConfig


func setup(resource_manager: ResourceManager, config: SimulationConfig) -> void:
    _resources = resource_manager
    _config = config


func advance(hours: float) -> void:
    var oxygen_cost := _config.astronaut_oxygen_per_hour * hours
    var water_cost := _config.astronaut_water_per_hour * hours

    if oxygen_cost > 0.0 and not _resources.consume(&"oxygen", oxygen_cost):
        # No automatic game-over here: the manager/UI can apply consequences.
        pass

    if water_cost > 0.0 and not _resources.consume(&"water", water_cost):
        pass


func consume_suit_oxygen(duration_hours: float, rate_per_hour: float) -> bool:
    if duration_hours <= 0.0 or rate_per_hour < 0.0:
        return false
    return _resources.consume(
        &"suit_oxygen",
        duration_hours * rate_per_hour
    )
