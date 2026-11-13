extends StaticBody3D
class_name MarsTerrain

@export var terrain_size: float = 100.0
@export_range(32, 256) var resolution: int = 160

const BASE_COLOR := Color("#96351F")
const LIGHT_COLOR := Color("#C45A35")
const DARK_COLOR := Color("#672719")

var height_noise := FastNoiseLite.new()
var color_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()


func _ready() -> void:
    configure_noise()
    create_terrain()


func configure_noise() -> void:
    height_noise.seed = 42
    height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    height_noise.frequency = 0.025
    height_noise.fractal_octaves = 4
    height_noise.fractal_lacunarity = 2.0
    height_noise.fractal_gain = 0.45

    color_noise.seed = 87
    color_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    color_noise.frequency = 0.045
    color_noise.fractal_octaves = 3

    detail_noise.seed = 123
    detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    detail_noise.frequency = 0.12


func get_height(x: float, z: float) -> float:
    var large_shape := height_noise.get_noise_2d(x, z) * 1.4
    var small_shape := detail_noise.get_noise_2d(x, z) * 0.22

    var height := large_shape + small_shape

    # Three shallow impact depressions with raised rims.
    var craters := [
        {"center": Vector2(-20.0, -12.0), "radius": 7.0},
        {"center": Vector2(18.0, 10.0), "radius": 5.0},
        {"center": Vector2(-8.0, 25.0), "radius": 4.0}
    ]

    for crater in craters:
        var center: Vector2 = crater["center"]
        var radius: float = crater["radius"]
        var distance := Vector2(x, z).distance_to(center)

        var bowl := -0.65 * exp(-pow(distance / radius, 2.0) * 3.0)
        var rim := 0.20 * exp(-pow((distance - radius * 0.85) / (radius * 0.12), 2.0))

        height += bowl + rim

    return height


func get_ground_color(x: float, z: float) -> Color:
    var variation := color_noise.get_noise_2d(x, z)

    var color: Color

    if variation > 0.0:
        color = BASE_COLOR.lerp(LIGHT_COLOR, variation * 0.8)
    else:
        color = BASE_COLOR.lerp(DARK_COLOR, -variation * 0.8)

    return color


func create_terrain() -> void:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)

    var half_size := terrain_size / 2.0
    var step := terrain_size / float(resolution)

    for z in range(resolution):
        for x in range(resolution):
            var x0 := -half_size + x * step
            var x1 := x0 + step
            var z0 := -half_size + z * step
            var z1 := z0 + step

            var p00 := Vector3(x0, get_height(x0, z0), z0)
            var p10 := Vector3(x1, get_height(x1, z0), z0)
            var p01 := Vector3(x0, get_height(x0, z1), z1)
            var p11 := Vector3(x1, get_height(x1, z1), z1)

            add_vertex(surface, p00, x0, z0, half_size)
            add_vertex(surface, p01, x0, z1, half_size)
            add_vertex(surface, p10, x1, z0, half_size)

            add_vertex(surface, p10, x1, z0, half_size)
            add_vertex(surface, p01, x0, z1, half_size)
            add_vertex(surface, p11, x1, z1, half_size)

    surface.generate_normals()

    var terrain_mesh := surface.commit()

    var ground := MeshInstance3D.new()
    ground.name = "Ground"
    ground.mesh = terrain_mesh
    ground.material_override = create_ground_material()

    add_child(ground)

    # Generate collision matching the terrain surface.
    ground.create_trimesh_collision()


func add_vertex(
    surface: SurfaceTool,
    position: Vector3,
    x: float,
    z: float,
    half_size: float
) -> void:
    surface.set_color(get_ground_color(x, z))
    surface.set_uv(Vector2(
        (x + half_size) / terrain_size * 8.0,
        (z + half_size) / terrain_size * 8.0
    ))
    surface.add_vertex(position)


func create_ground_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()

    material.albedo_color = Color.WHITE
    material.vertex_color_use_as_albedo = true
    material.roughness = 1.0
    material.metallic = 0.0

    material.cull_mode = BaseMaterial3D.CULL_DISABLED

    return material
