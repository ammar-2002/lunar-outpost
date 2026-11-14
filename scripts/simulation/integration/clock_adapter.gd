class_name ClockAdapter
extends RefCounted
## Call this from the teammate's clock signal/callback.
## Adapt the connection to the actual clock API once its script is available.

var simulation: SimulationManager


func setup(simulation_manager: SimulationManager) -> void:
    simulation = simulation_manager


func on_time_advanced(elapsed_hours: float) -> void:
    if is_instance_valid(simulation):
        simulation.advance_simulation(elapsed_hours)
