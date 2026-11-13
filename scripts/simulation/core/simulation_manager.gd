class_name SimulationManager
extends Node
## Coordinates simulation systems. The external clock decides when/how much
## time passes; this node only simulates the duration it receives.

signal simulation_updated(snapshot: Dictionary)
signal warning_triggered(message: String)
signal simulation_error(message: String)

@export var config: SimulationConfig

var state: SimulationState
var resources: ResourceManager

var power: PowerSystem
var agriculture: AgricultureSystem
var life_support: LifeSupportSystem
var health: HealthSystem
var radiation: RadiationSystem

var _is_initialized: bool = false


func _ready() -> void:
    initialize_simulation()


func initialize_simulation() -> void:
    if _is_initialized:
        return

    if config == null:
        config = SimulationConfig.new()

    state = SimulationState.new()
    resources = ResourceManager.new()
    resources.setup(state)
    resources.resource_changed.connect(_on_resource_changed)

    power = PowerSystem.new()
    power.setup(resources, config)

    agriculture = AgricultureSystem.new()
    agriculture.setup(resources, state)

    life_support = LifeSupportSystem.new()
    life_support.setup(resources, config)

    health = HealthSystem.new()
    health.setup(resources, state, config)

    radiation = RadiationSystem.new()
    radiation.setup(state)

    _is_initialized = true
    simulation_updated.emit(state.make_snapshot())


func advance_simulation(total_hours: float) -> void:
    if not _is_initialized:
        initialize_simulation()

    if total_hours <= 0.0:
        simulation_error.emit("Simulation time must be greater than zero.")
        return

    var remaining := total_hours
    var step := maxf(config.step_hours, 0.05)

    while remaining > 0.0001:
        var current_step := minf(step, remaining)
        _simulate_step(current_step)
        remaining -= current_step

    simulation_updated.emit(state.make_snapshot())


func _simulate_step(hours: float) -> void:
    # Fixed order: generation -> powered systems -> life support -> health.
    # Each subsystem must use ResourceManager for all shared resource changes.
    power.advance(hours)
    agriculture.advance(hours)
    life_support.advance(hours)
    health.advance(hours)


func apply_event(event_data: Dictionary) -> void:
    if not _is_initialized:
        initialize_simulation()

    var event_type := StringName(event_data.get("type", ""))

    match event_type:
        &"dust_storm":
            power.apply_dust_storm(
                float(event_data.get("intensity", 0.0)),
                float(event_data.get("duration_hours", 0.0))
            )
        &"radiation":
            radiation.apply_exposure(
                float(event_data.get("dose_rate", 0.0)),
                float(event_data.get("duration_hours", 0.0)),
                float(event_data.get("shielding_factor", 1.0))
            )
        _:
            warning_triggered.emit("Unknown simulation event: %s" % event_type)

    simulation_updated.emit(state.make_snapshot())


func get_simulation_state() -> SimulationState:
    return state


func get_snapshot() -> Dictionary:
    if not _is_initialized:
        initialize_simulation()
    return state.make_snapshot()


func _on_resource_changed(resource_id: StringName, new_amount: float) -> void:
    if new_amount <= 0.0:
        warning_triggered.emit("%s reserve is empty." % String(resource_id))
