extends RefCounted
class_name OutpostSimulationState

var elapsed_hours: float = 0.0
var day: int = 1
var hour_of_day: float = 0.0
var campaign_days: int = 90
var resources: Dictionary = {}
var crops: Array[Dictionary] = []
var crew := {
    "fitness": 75.0,
    "happiness": 75.0,
    "health": 100.0,
    "radiation_dose_msv": 0.0,
    "crew_count": 4
}
var power := {
    "solar_condition": 1.0,
    "dust_level": 0.0,
    "storm_days_remaining": 0,
    "power_generated_today_kwh": 0.0,
    "power_used_today_kwh": 0.0
}
var status: String = "operational"
var warnings: Array[String] = []
var history: Array[Dictionary] = []

func snapshot() -> Dictionary:
    return {
        "elapsed_hours": elapsed_hours,
        "day": day,
        "hour_of_day": hour_of_day,
        "campaign_days": campaign_days,
        "resources": resources.duplicate(true),
        "crops": crops.duplicate(true),
        "crew": crew.duplicate(true),
        "power": power.duplicate(true),
        "status": status,
        "warnings": warnings.duplicate()
    }
