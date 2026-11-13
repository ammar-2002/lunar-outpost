class_name EventAdapter
extends RefCounted
## Normalizes external event dictionaries before passing them to the simulation.

var simulation: SimulationManager


func setup(simulation_manager: SimulationManager) -> void:
    simulation = simulation_manager


func on_event_triggered(event_data: Dictionary) -> void:
    if is_instance_valid(simulation):
        simulation.apply_event(event_data)
