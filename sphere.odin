package raytracing
import "core:math"
import "core:math/linalg"
Sphere :: struct {
	center: Point3,
	radius: f64,
	mat : ^Material
}
hit_sphere :: proc(
	sphere: Sphere,
	r: Ray,
    ray_t:Interval,
	rec: ^HitRecord,
) -> bool {
	oc := sphere.center - r.orig
	a := linalg.length2(r.dir)
	h := linalg.dot(r.dir, oc)
	c := linalg.length2(oc) - sphere.radius * sphere.radius
	discriminant := h * h - a * c
	if discriminant < 0 {

		return false
	}

	sqrtd := math.sqrt(discriminant)

	// Find the nearest root that lies in the acceptable range.
	root := (h - sqrtd) / a
	if !interval_surrounds(ray_t,root) {
		root = (h + sqrtd) / a
		if !interval_surrounds(ray_t,root) {
			return false
		}
	}

	rec.t = root
	rec.p = ray_at(r, rec.t)
	outward_normal := (rec.p - sphere.center) / sphere.radius
	set_face_normal(rec, r, outward_normal)
	rec.mat = sphere.mat

	return true
}

hit_sphere_list :: proc(
	spheres: []Sphere,
	r: Ray,
	// ray_tmin: f64,
	// ray_tmax: f64,
    ray_t:Interval,
	rec: ^HitRecord,
) -> bool {
	temp_rec: HitRecord
	hit_anything: bool
	closest_so_far := ray_t.max
	for sphere in spheres {
		if hit_sphere(sphere, r, Interval{ray_t.min, closest_so_far}, &temp_rec) {
			hit_anything = true
			closest_so_far = temp_rec.t
			rec^ = temp_rec
		}
	}
	return hit_anything
}
