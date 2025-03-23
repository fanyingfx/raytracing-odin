package raytracing
import "core:fmt"
import "core:os"

Camera :: struct {
	image_height:  int,
	image_width: int,
	center:        Point3,
	pixel00_loc:   Point3,
	pixel_delta_u: Vec3,
	pixel_delta_v: Vec3,
}
init_camera :: proc(aspect_ratio: f64, image_width: int) -> Camera {
	image_height_v := int(f64(image_width) / aspect_ratio)
	image_height := int(image_height_v if image_height_v >= 1 else 1)

	// Camera
	focal_length := 1.0
	viewport_height := 2.0
	viewport_width := viewport_height * (f64(image_width) / f64(image_height))
	center := Point3{0, 0, 0}

	// Calculate the vectors across the horizontal and down the vertical viewport edges.
	viewport_u := Vec3{viewport_width, 0, 0}
	viewport_v := Vec3{0, -viewport_height, 0}

	// Calculate the horizontal and vertical delta vectors from pixel to pixel.
	pixel_delta_u := viewport_u / f64(image_width)
	pixel_delta_v := viewport_v / f64(image_height)
	viewport_upper_left: Vec3 = center - Vec3{0, 0, focal_length} - viewport_u / 2 - viewport_v / 2

	pixel00_loc: Vec3 = viewport_upper_left + (0.5 * (pixel_delta_u + pixel_delta_v))
	return {image_width,image_height, center, pixel00_loc, pixel_delta_u, pixel_delta_v}
}
render :: proc(world:[]Hitable){
	camera:=init_camera(1.0,100)
	fmt.printf("P3\n%d %d\n255\n", camera.image_width, camera.image_height)
	for j in 0 ..< camera.image_height {
		fmt.eprintf("\rScanlines remaining: %d ", camera.image_height - j)
		for i in 0 ..< camera.image_width {
			pixel_center := camera.pixel00_loc + (f64(i) * camera.pixel_delta_u) + (f64(j) * camera.pixel_delta_v)
			ray_direction := pixel_center - camera.center

			r := Ray {
				orig = camera.center,
				dir  = ray_direction,
			}
			pixel_color := ray_color(r, world)
			write_color(os.stdout, pixel_color)
		}
	}
}
