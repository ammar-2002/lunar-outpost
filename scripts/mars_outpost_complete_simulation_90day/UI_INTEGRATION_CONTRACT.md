# UI Integration Contract

Attach `outpost_game_controller.gd` to a Node named `OutpostGameController` under Main.
The controller owns the clock and simulation manager. Do not add a second clock or duplicate resource calculations.

Connect these signals:
- ui_state_changed(snapshot): update resource bars, crop trays, crew stats and power UI.
- clock_ui_changed(clock_state): update day/hour, speed and progress UI.
- mission_ui_changed(mission_board): update current mission and completed/failed list.
- disaster_ui_changed(disaster): show a disaster notification.
- warning_ui_raised(code, message): show resource/crew warnings.
- action_result(action, result): show success/failure feedback.
- campaign_finished(report): show end-of-expedition results.

Call methods on the controller, not on internal systems:
plant_crop(crop_id), harvest_crop(crop_instance_id), water_crop(crop_instance_id),
exercise_crew(), clean_solar_panels(), repair_power_system(), perform_eva(),
refill_suit_oxygen(), complete_systems_check(), complete_radiation_drill(),
pause_game(), resume_game(), set_game_speed(multiplier), reset_game().

Always inspect the returned Dictionary's `ok` field before showing success.
Use `get_ui_snapshot()` for initial UI population after connecting signals.
