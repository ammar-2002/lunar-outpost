extends RefCounted
class_name OutpostHealthSystem

signal crew_status_changed(crew: Dictionary)
var state: OutpostSimulationState
var resources: OutpostResourceManager
var config: OutpostSimulationConfig

func setup(sim_state: OutpostSimulationState, resource_manager: OutpostResourceManager, cfg: OutpostSimulationConfig) -> void:
    state = sim_state
    resources = resource_manager
    config = cfg

func advance_day() -> void:
    state.crew.fitness = maxf(0.0, float(state.crew.fitness) - config.daily_fitness_decay)
    state.crew.happiness = maxf(0.0, float(state.crew.happiness) - config.daily_happiness_decay)
    if float(state.crew.radiation_dose_msv) > config.radiation_warning_msv:
        state.crew.happiness = maxf(0.0, float(state.crew.happiness) - 0.5)
    if float(state.crew.health) < 50.0:
        state.crew.fitness = maxf(0.0, float(state.crew.fitness) - 1.0)
    crew_status_changed.emit(state.crew.duplicate(true))

func exercise_crew() -> Dictionary:
    if float(state.crew.fitness) >= 100.0:
        return {"ok": false, "reason": "Fitness is already at maximum"}
    if not resources.consume("battery_kwh", config.exercise_power_kwh):
        return {"ok": false, "reason": "Not enough stored power"}
    state.crew.fitness = minf(100.0, float(state.crew.fitness) + config.exercise_fitness_gain)
    state.crew.happiness = minf(100.0, float(state.crew.happiness) + config.exercise_happiness_gain)
    crew_status_changed.emit(state.crew.duplicate(true))
    return {"ok": true, "fitness": state.crew.fitness, "happiness": state.crew.happiness}

func perform_demanding_activity(fitness_cost: float = 4.0) -> Dictionary:
    if float(state.crew.fitness) < 20.0:
        return {"ok": false, "reason": "Crew fitness is too low for this activity"}
    state.crew.fitness = maxf(0.0, float(state.crew.fitness) - fitness_cost)
    return {"ok": true, "fitness": state.crew.fitness}
