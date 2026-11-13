extends Node3D
class_name MarsWorld

const TERRAIN_SCENE = preload("res://scenes/environment/MarsTerrain.tscn")


func _ready() -> void:
    create_environment()
    create_sun()
    create_camera()
    create_terrain()


func create_environment() -> void:
    var world_environment := WorldEnvironment.new()
    world_environment.name = "WorldEnvironment"

    var environment := Environment.new()

    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#38251F")

    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#D9A58B")
    environment.ambient_light_energy = 0.45

    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

    world_environment.environment = environment
    add_child(world_environment)


func create_sun() -> void:
    var sun := DirectionalLight3D.new()
    sun.name = "SunLight"

    sun.rotation_degrees = Vector3(-45.0, -35.0, 0.0)
    sun.light_color = Color("#FFE0B5")
    sun.light_energy = 1.4
    sun.shadow_enabled = true

    add_child(sun)


func create_camera() -> void:
    var camera := Camera3D.new()
    camera.name = "IsometricCamera"

    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 42.0
    camera.position = Vector3(30.0, 28.0, 30.0)

    add_child(camera)

    camera.look_at(Vector3.ZERO, Vector3.UP)
    camera.current = true


func create_terrain() -> void:
    var terrain := TERRAIN_SCENE.instantiate()
    terrain.name = "MarsTerrain"

    add_child(terrain)
