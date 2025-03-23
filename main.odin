package raytracing
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import "core:os"
import "core:strings"


// IMAGE
main :: proc() {


	world: [dynamic]ScreenObject
	defer delete(world)
	sb: strings.Builder

	ground_material: Material = Lambertian{{0.5, 0.5, 0.5}}
	append(&world, Sphere{{0, -1000, 0}, 1000, &ground_material})

	for a := -11; a < 11; a += 1 {
		for b := -11; b < 11; b += 1 {
			choose_mat := rand.float64()
			center := Point3{f64(a) + 0.9 * rand.float64(), 0.2, f64(b) + rand.float64()}

			if la.length(center - Point3{4, 0.2, 0}) > 0.9 {
				sphere_material: ^Material = new(Material, context.temp_allocator)

				if choose_mat < 0.8 {
					// diffuse
					albedo: Color = random_vec() * random_vec()
					sphere_material^ = Lambertian{albedo}
				} else if choose_mat < 0.95 {
					//metal
					albedo := random_vec_range(0.5, 1)
					fuzz := rand.float64_range(0, 0.5)
					sphere_material^ = Metal{albedo, fuzz}
				} else {
					//glass
					sphere_material^ = Dielectric{1.5}
				}
				append(&world, Sphere{center, 0.2, sphere_material})
			}
		}
	}


	material1: Material = Dielectric{1.5}
	append(&world, Sphere{{0, 1, 0}, 1.0, &material1})

	material2: Material = Lambertian{{0.4, 0.2, 0.1}}
	append(&world, Sphere{{-4, 1, 0}, 1.0, &material2})

	material3: Material = Metal{{0.7, 0.6, 0.5}, 0.0}
	append(&world, Sphere{{4, 1, 0}, 1.0, &material3})


	aspect_ratio: f64 = 16.0 / 9.0
	image_width: int = 1200
	samples_per_pixel: int = 500
	max_depth: int = 50

	vfov: f64 = 20
	lookfrom: Point3 = {13, 2, 3}
	lookat: Point3 = {0, 0, 0}
	vup: Vec3 = {0, 1, 0}

	defocus_angle := 0.6
	focus_dist := 10.0

	camera := init_camera(
		aspect_ratio,
		image_width,
		samples_per_pixel,
		max_depth,
		vfov,
		lookfrom,
		lookat,
		vup,
		defocus_angle,
		focus_dist,
	)
	render(camera, world[:], &sb)
	free_all(context.temp_allocator)
	os.write_entire_file("image.ppm",sb.buf[:])

	fmt.eprint("\rDone.                 \n")
}
