package raytracing
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import "core:os"
import "core:strings"
import "core:sync"
import "core:thread"
import "core:time"

Infinity :: f64(0h7ff00000_00000000)

Vec3 :: [3]f64
Color :: Vec3
Point3 :: Vec3


Ray :: struct {
	orig: Point3,
	dir:  Vec3,
}
Camera :: struct {
	image_width:         int,
	image_height:        int,
	center:              Point3,
	pixel00_loc:         Point3,
	pixel_delta_u:       Vec3,
	pixel_delta_v:       Vec3,
	pixel_samples_scale: f64,
	samples_per_pixel:   int,
	max_depth:           int,
	u, v, w:             Vec3,
	defocus_angle:       f64,
	defocus_disk_u:      Vec3,
	defocus_disk_v:      Vec3,
}
init_camera :: proc(
	aspect_ratio: f64,
	image_width: int,
	samples_per_pixel: int,
	max_depth: int,
	vfov: f64,
	lookfrom: Point3,
	lookat: Point3,
	vup: Vec3,
	defocus_angle: f64,
	focus_dist: f64,
) -> Camera {
	image_height_v := int(f64(image_width) / aspect_ratio)
	image_height := int(image_height_v if image_height_v >= 1 else 1)

	pixel_samples_scale := 1.0 / f64(samples_per_pixel)
	center := lookfrom

	focal_length := la.length(lookfrom - lookat)
	theta := math.to_radians(vfov)
	h := math.tan(theta / 2)

	viewport_height := 2.0 * h * focus_dist
	viewport_width := viewport_height * (f64(image_width) / f64(image_height))

	w := la.normalize(lookfrom - lookat)
	u := la.normalize(la.cross(vup, w))
	v := la.cross(w, u)


	viewport_u := viewport_width * u
	viewport_v := -viewport_height * v

	pixel_delta_u := viewport_u / f64(image_width)
	pixel_delta_v := viewport_v / f64(image_height)
	viewport_upper_left: Vec3 = center - (focus_dist * w) - viewport_u / 2 - viewport_v / 2

	pixel00_loc: Vec3 = viewport_upper_left + (0.5 * (pixel_delta_u + pixel_delta_v))

	defocus_radius := focus_dist * math.tan(math.to_radians(defocus_angle / 2))
	defocus_disk_u := u * defocus_radius
	defocus_disk_v := v * defocus_radius

	return {
		image_width,
		image_height,
		center,
		pixel00_loc,
		pixel_delta_u,
		pixel_delta_v,
		pixel_samples_scale,
		samples_per_pixel,
		max_depth,
		u,
		v,
		w,
		defocus_angle,
		defocus_disk_u,
		defocus_disk_v,
	}
}
sample_square :: proc() -> Vec3 {
	return {random_f64() - 0.5, random_f64() - 0.5, 0}

}
get_ray :: proc(camera: Camera, i: int, j: int) -> Ray {
	defocus_disk_sample :: proc(camera: Camera) -> Point3 {
		p := random_in_uint_disk()
		return camera.center + (p.x * camera.defocus_disk_u) + (p.y * camera.defocus_disk_v)
	}
	offset := sample_square()
	pixel_sample :=
		camera.pixel00_loc +
		((f64(i) + offset.x) * camera.pixel_delta_u) +
		((f64(j) + offset.y) * camera.pixel_delta_v)

	ray_origin := camera.defocus_angle <= 0 ? camera.center : defocus_disk_sample(camera)
	ray_direction := pixel_sample - ray_origin

	return {ray_origin, ray_direction}
}
Thread_Data :: struct {
	camera:     Camera,
	world:      []ScreenObject,
	line_start: int,
	line_end:   int,
	sb:         strings.Builder,
}
sema: sync.Atomic_Sema
render :: proc(camera: Camera, world: []ScreenObject, sb: ^strings.Builder) {
	fmt.sbprintf(sb, "P3\n%d %d\n255\n", camera.image_width, camera.image_height)
	THREADS_NUM :: 16
	threads_data: [THREADS_NUM]Thread_Data
	threads: [THREADS_NUM]^thread.Thread

	step := camera.image_height / THREADS_NUM
	d: Thread_Data = {
		camera = camera,
		world  = world,
	}
	for &d, idx in threads_data {
		t := thread.create(thread_render_proc1)
		assert(t != nil)
		d.camera = camera
		d.world = world
		d.line_start = idx * step
		d.line_end = d.line_start + step
		if idx == THREADS_NUM - 1 {
			d.line_end = camera.image_height
		}
		t.data = &d
		t.id = idx
		thread.start(t)
		// wait enougth time to start thread
		sync.atomic_sema_wait_with_timeout(&sema, time.Millisecond * 50)
		threads[idx] = t
	}
	thread.join_multiple(..threads[:])
	for th in threads {
		d := (^Thread_Data)(th.data)
		fmt.sbprintf(sb, "%s", d.sb.buf[:])
		thread.destroy(th)
	}

}

thread_render_proc1 :: proc(t: ^thread.Thread) {
	d := (^Thread_Data)(t.data)
	for j in d.line_start ..< d.line_end {
		fmt.printfln("thread-%d Remaing %d", t.id, d.line_end - j)
		render_line(j, d.camera, d.world, &d.sb)
	}
}
render_line :: proc(j: int, camera: Camera, world: []ScreenObject, sb: ^strings.Builder) {
	for i in 0 ..< camera.image_width {
		pixel_color := Color{0, 0, 0}
		for sample := 0; sample < camera.samples_per_pixel; sample += 1 {
			r := get_ray(camera, i, j)
			pixel_color += ray_color(r, camera.max_depth, world)
		}
		write_color(sb, camera.pixel_samples_scale * pixel_color)
	}

}
ray_at :: proc(ray: Ray, t: f64) -> Point3 {
	return ray.orig + t * ray.dir
}
ray_color :: proc(r: Ray, depth: int, world: []ScreenObject) -> Color {
	if depth <= 0 do return {0, 0, 0}
	rec: HitRecord
	if hit_list(world, r, {0.001, Infinity}, &rec) {

		scattered: Ray
		attenuation: Color
		is_scatter: bool

		switch mat in rec.mat {
		case Lambertian:
			is_scatter = lambertian_scatter(mat, r, rec, &attenuation, &scattered)
		case Metal:
			is_scatter = metal_scatter(mat, r, rec, &attenuation, &scattered)
		case Dielectric:
			is_scatter = dielectric_scatter(mat, r, rec, &attenuation, &scattered)
		}
		if is_scatter do return attenuation * ray_color(scattered, depth - 1, world)
		return {0, 0, 0}
	}
	unit_direction := la.normalize(r.dir)
	a := 0.5 * (unit_direction.y + 1.0)
	return (1.0 - a) * Color{1.0, 1.0, 1.0} + a * Color{0.5, 0.7, 1.0}
}

linear_to_gamma :: proc(linear_component: f64) -> f64 {
	if linear_component > 0 {
		return math.sqrt(linear_component)
	}
	return 0
}

write_color :: proc(sb: ^strings.Builder, color: Color) {
	intensity := Interval{0.0, 0.999}

	r := linear_to_gamma(color.r)
	g := linear_to_gamma(color.g)
	b := linear_to_gamma(color.b)

	ir := i64(256 * interval_clamp(intensity, r))
	ig := i64(256 * interval_clamp(intensity, g))
	ib := i64(256 * interval_clamp(intensity, b))
	fmt.sbprintf(sb, "%d %d %d\n", ir, ig, ib)
}
print_color :: proc(color: Color) {
	intensity := Interval{0.0, 0.999}

	r := linear_to_gamma(color.r)
	g := linear_to_gamma(color.g)
	b := linear_to_gamma(color.b)

	ir := i64(256 * interval_clamp(intensity, r))
	ig := i64(256 * interval_clamp(intensity, g))
	ib := i64(256 * interval_clamp(intensity, b))
	fmt.printfln("%d %d %d\n", ir, ig, ib)
}
