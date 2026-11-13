class_name PowerSystem
extends RefCounted

var _resources: ResourceManager
var _config: SimulationConfig

var _dust_storm_factor: float = 1.0
var _dust_storm_hours_remaining: float = 0.0


func setup(resource_manager: ResourceManager, config: SimulationConfig) -> void:
    _resources = resource_manager
    _config = config


func advance(hours: float) -> void:
    var generation := (
        _config.solar_generation_per_hour
        * _dust_storm_factor
        * hours
    )
    _resources.produce(
        &"battery_energy",
        generation,
        _config.battery_capacity
    )

    var equipment_cost := _config.base_equipment_energy_per_hour * hours
    if equipment_cost > 0.0:
        _resources.consume(&"battery_energy", equipment_cost)

    if _dust_storm_hours_remaining > 0.0:
        _dust_storm_hours_remaining = maxf(
            0.0,
            _dust_storm_hours_remaining - hours
        )
        if _dust_storm_hours_remaining <= 0.0:
            _dust_storm_factor = 1.0


func apply_dust_storm(intensity: float, duration_hours: float) -> void:
    if duration_hours <= 0.0:
        return

    # Intensity is normalized 0..1. The conversion to panel output is a
    # gameplay model and should be calibrated/labelled as an approximation.
    var normalized_intensity := clampf(intensity, 0.0, 1.0)
    _dust_storm_factor = 1.0 - (0.8 * normalized_intensity)
    _dust_storm_hours_remaining = maxf(
        _dust_storm_hours_remaining,
        duration_hours
    )
