extends RefCounted
class_name OutpostCropCatalog

## Harvest targets are game values informed by published terrestrial/ISS
## analogues. They are not predictions of crop growth on Mars.

const CROPS := {
    "radish": {
        "display_name": "Radish",
        "days_to_harvest": 27.0,
        "water_l_per_day": 0.22,
        "energy_kwh_per_day": 0.30,
        "fertilizer_kg": 0.35,
        "food_kg": 2.2,
        "oxygen_kg_per_day": 0.025,
        "nutrition": {"vitamins": 1.0, "protein": 0.2, "calories": 0.25},
        "description": "Fast first harvest; useful for an early food milestone."
    },
    "lettuce": {
        "display_name": "Red Romaine Lettuce",
        "days_to_harvest": 33.0,
        "water_l_per_day": 0.28,
        "energy_kwh_per_day": 0.34,
        "fertilizer_kg": 0.45,
        "food_kg": 2.8,
        "oxygen_kg_per_day": 0.030,
        "nutrition": {"vitamins": 1.0, "protein": 0.15, "calories": 0.2},
        "description": "Leafy fresh food; a NASA Veggie crop analogue."
    },
    "mizuna": {
        "display_name": "Mizuna Mustard",
        "days_to_harvest": 35.0,
        "water_l_per_day": 0.26,
        "energy_kwh_per_day": 0.33,
        "fertilizer_kg": 0.42,
        "food_kg": 2.5,
        "oxygen_kg_per_day": 0.028,
        "nutrition": {"vitamins": 0.9, "protein": 0.2, "calories": 0.2},
        "description": "Leafy crop with a useful harvest window."
    },
    "kale": {
        "display_name": "Red Russian Kale",
        "days_to_harvest": 42.0,
        "water_l_per_day": 0.30,
        "energy_kwh_per_day": 0.35,
        "fertilizer_kg": 0.48,
        "food_kg": 2.7,
        "oxygen_kg_per_day": 0.032,
        "nutrition": {"vitamins": 1.0, "protein": 0.25, "calories": 0.2},
        "description": "Later leafy harvest; outer leaves can be harvested in stages."
    },
    "tomato": {
        "display_name": "Dwarf Tomato",
        "days_to_harvest": 60.0,
        "water_l_per_day": 0.42,
        "energy_kwh_per_day": 0.48,
        "fertilizer_kg": 0.75,
        "food_kg": 3.2,
        "oxygen_kg_per_day": 0.040,
        "nutrition": {"vitamins": 0.8, "protein": 0.15, "calories": 0.35},
        "description": "Longer-term fruit crop; gameplay target within the CSA 50–90 day range."
    }
}

static func get_crop(crop_id: String) -> Dictionary:
    return CROPS.get(crop_id, {}).duplicate(true)

static func all_crop_ids() -> Array:
    return CROPS.keys()
