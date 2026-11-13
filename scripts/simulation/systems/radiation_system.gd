class_name RadiationSystem
extends RefCounted

var _state: SimulationState


func setup(simulation_state: SimulationState) -> void:
    _state = simulation_state


## dose_rate and resulting dose must use the same documented unit convention.
## shielding_factor is a simplified transmission fraction from 0..1.
func apply_exposure(
    dose_rate: float,
    duration_hours: float,
    shielding_factor: float = 1.0
) -> float:
    if dose_rate < 0.0 or duration_hours <= 0.0:
        return 0.0

    var transmission := clampf(shielding_factor, 0.0, 1.0)
    var dose := dose_rate * duration_hours * transmission
    _state.accumulated_radiation_dose += dose
    return dose


func get_total_dose() -> float:
    return _state.accumulated_radiation_dose
