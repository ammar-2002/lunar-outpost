class_name SimulationConfig
extends Resource
## Tunable gameplay parameters.
## Defaults are prototype placeholders, NOT NASA measurements or medical guidance.

@export_group("Simulation")
@export_range(0.05, 24.0, 0.05) var step_hours: float = 1.0

@export_group("Power")
@export var solar_generation_per_hour: float = 0.0
@export var battery_capacity: float = 100.0
@export var base_equipment_energy_per_hour: float = 0.0

@export_group("Life Support")
@export var astronaut_oxygen_per_hour: float = 0.0
@export var astronaut_water_per_hour: float = 0.0

@export_group("Health")
@export var food_units_per_hour: float = 0.0
@export var fitness_decay_per_hour: float = 0.0
@export var happiness_decay_per_hour: float = 0.0
