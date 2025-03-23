package raytracing
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:os"

Infinity :: f64(0h7ff00000_00000000)

Vec3 :: [3]f64
Color :: Vec3
Point3 :: Vec3

Ray :: struct {
	orig: Point3,
	dir:  Vec3,
}

ray_at :: proc(ray: Ray, t: f64) -> Point3 {
	return ray.orig + t * ray.dir
}
ray_color :: proc(r: Ray, objs: []Hitable) -> Color {
	rec: HitRecord
	if hit_list(objs, r, {0, Infinity}, &rec) {
		return 0.5 * (rec.normal + Color{1, 1, 1})
	}
	unit_direction := la.normalize(r.dir)
	a := 0.5 * (unit_direction.y + 1.0)
	return (1.0 - a) * Color{1.0, 1.0, 1.0} + a * Color{0.5, 0.7, 1.0}
}

write_color :: proc(fd: os.Handle, color: Color) {
	ir := i64(255.999 * color.r)
	ig := i64(255.999 * color.g)
	ib := i64(255.999 * color.b)
	fmt.fprintf(fd, "%d %d %d\n", ir, ig, ib)
}

// IMAGE
main :: proc() {


	world: [dynamic]Hitable
	defer delete(world)
	append(&world, Sphere{center = {0, 0, -1}, radius = 0.5})
	append(&world, Sphere{center = {0, -100.5, -1}, radius = 100})

	render(world[:])


	fmt.eprint("\rDone.                 \n")
}
