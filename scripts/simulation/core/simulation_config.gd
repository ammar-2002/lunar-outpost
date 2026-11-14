extends Resource
class_name OutpostSimulationConfig

## Tunable educational gameplay values. These are game-balance assumptions, not
## certified Mars habitat engineering specifications.

@export var campaign_days: int = 90
@export var real_seconds_per_game_day: float = 400.0 # 6m 40s; 90 days = 10 hours at 1x
@export var speed_options: Array[float] = [1.0, 2.0, 4.0]
@export var max_crew: int = 4

@export var starting_water_l: float = 1800.0
@export var starting_oxygen_kg: float = 220.0
@export var starting_suit_oxygen_kg: float = 36.0
@export var starting_battery_kwh: float = 180.0
@export var battery_capacity_kwh: float = 300.0
@export var starting_food_kg: float = 205.0
@export var starting_seeds: int = 12
@export var starting_fertilizer_kg: float = 35.0

@export var crew_water_l_per_person_day: float = 3.5
@export var crew_oxygen_kg_per_person_day: float = 0.84
@export var crew_food_kg_per_person_day: float = 0.62
@export var base_power_kwh_per_day: float = 38.0
@export var greenhouse_power_kwh_per_day: float = 12.0
@export var solar_generation_kwh_per_day: float = 78.0
@export var solar_dust_loss_per_day: float = 0.012
@export var solar_cleaning_restore: float = 0.25
@export var water_recovery_fraction: float = 0.82
@export var oxygen_regeneration_kg_per_day: float = 2.8
@export var oxygen_generator_water_l_per_day: float = 4.2
@export var oxygen_generator_power_kwh_per_day: float = 3.0
@export var oxygen_emergency_threshold_kg: float = 35.0
@export var water_emergency_threshold_l: float = 250.0
@export var food_emergency_threshold_kg: float = 25.0

@export var daily_fitness_decay: float = 0.45
@export var daily_happiness_decay: float = 0.35
@export var exercise_fitness_gain: float = 3.0
@export var exercise_power_kwh: float = 2.0
@export var exercise_happiness_gain: float = 1.0
@export var radiation_base_msv_per_day: float = 0.45
@export var radiation_shelter_factor: float = 0.35
@export var radiation_warning_msv: float = 25.0
@export var radiation_danger_msv: float = 50.0

@export var disaster_daily_chance: float = 0.12
@export var dust_storm_duration_min_days: int = 2
@export var dust_storm_duration_max_days: int = 5
@export var dust_storm_solar_reduction: float = 0.65
@export var dust_storm_water_leak_l_per_day: float = 8.0
@export var equipment_failure_chance: float = 0.035
@export var crop_pest_chance: float = 0.025
@export var radiation_event_chance: float = 0.025
@export var random_seed: int = 0 # 0 = random seed; non-zero = reproducible run
