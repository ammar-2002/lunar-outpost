class_name CropInstance
extends RefCounted

var crop_data: CropData
var growth_hours: float = 0.0
var is_failed: bool = false
var is_harvested: bool = false


func get_growth_fraction() -> float:
    if crop_data == null or crop_data.growth_duration_hours <= 0.0:
        return 0.0
    return clampf(growth_hours / crop_data.growth_duration_hours, 0.0, 1.0)


func is_ready() -> bool:
    return (
        crop_data != null
        and not is_failed
        and not is_harvested
        and growth_hours >= crop_data.growth_duration_hours
    )


func make_snapshot() -> Dictionary:
    return {
        "crop_id": String(crop_data.crop_id) if crop_data != null else "",
        "growth_hours": growth_hours,
        "growth_fraction": get_growth_fraction(),
        "is_failed": is_failed,
        "is_harvested": is_harvested,
        "is_ready": is_ready(),
    }
