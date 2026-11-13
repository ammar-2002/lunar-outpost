class_name SimulationState
extends RefCounted
## Runtime state for one outpost simulation.
## Resource quantities are stored by StringName keys in `resources`.

var resources: Dictionary = {
    &"water": 100.0,
    &"oxygen": 100.0,
    &"suit_oxygen": 20.0,
    &"battery_energy": 100.0,
    &"food_lettuce": 0.0,
    &"food_radish": 0.0,
    &"food_potato": 0.0,
    &"food_soy": 0.0,
    &"food_tomato": 0.0,
    &"seed_lettuce": 3.0,
    &"seed_radish": 3.0,
    &"seed_potato": 3.0,
    &"seed_soy": 3.0,
    &"seed_tomato": 3.0,
}

var fitness: float = 75.0
var happiness: float = 75.0
var accumulated_radiation_dose: float = 0.0
var crops: Array[CropInstance] = []


func make_snapshot() -> Dictionary:
    var crop_snapshots: Array[Dictionary] = []
    for crop in crops:
        crop_snapshots.append(crop.make_snapshot())

    return {
        "resources": resources.duplicate(true),
        "fitness": fitness,
        "happiness": happiness,
        "accumulated_radiation_dose": accumulated_radiation_dose,
        "crops": crop_snapshots,
    }
