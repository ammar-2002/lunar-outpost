class_name CropData
extends Resource
## Create one .tres resource per crop type in the Inspector.
## Values are gameplay parameters until verified against suitable research.

@export var crop_id: StringName = &"lettuce"
@export var display_name: String = "Lettuce"
@export var growth_duration_hours: float = 240.0
@export var water_per_hour: float = 0.0
@export var energy_per_hour: float = 0.0
@export var food_yield: float = 1.0
@export var oxygen_output_per_hour: float = 0.0
@export var nutrition: Dictionary = {}
