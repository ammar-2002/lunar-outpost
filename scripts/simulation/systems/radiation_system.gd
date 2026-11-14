extends RefCounted
class_name OutpostRadiationSystem

signal radiation_warning(level: String, accumulated_dose_msv: float)
var state: OutpostSimulationState
var config: OutpostSimulationConfig

func setup(sim_state: OutpostSimulationState, cfg: OutpostSimulationConfig) -> void:
    state = sim_state
    config = cfg

func advance_day() -> void:
    var dose := config.radiation_base_msv_per_day * config.radiation_shelter_factor
    state.crew.radiation_dose_msv = float(state.crew.radiation_dose_msv) + dose
    if float(state.crew.radiation_dose_msv) >= config.radiation_danger_msv:
        radiation_warning.emit("danger", float(state.crew.radiation_dose_msv))
    elif float(state.crew.radiation_dose_msv) >= config.radiation_warning_msv:
        radiation_warning.emit("warning", float(state.crew.radiation_dose_msv))

func apply_solar_particle_event(extra_dose_msv: float) -> void:
    state.crew.radiation_dose_msv = float(state.crew.radiation_dose_msv) + maxf(0.0, extra_dose_msv)
    radiation_warning.emit("solar_event", float(state.crew.radiation_dose_msv))
