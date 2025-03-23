package raytracing
import "core:math/linalg"
HitRecord :: struct {
	p:          Point3,
	normal:     Vec3,
	front_face: bool,
	t:          f64,
    mat: ^Material
}

set_face_normal :: proc(hit_record: ^HitRecord, r: Ray, outward_normal: Vec3) {
	hit_record.front_face = linalg.dot(r.dir, outward_normal) < 0
	hit_record.normal = hit_record.front_face ? outward_normal : -outward_normal
}

Hitable :: union {
	Sphere,
}

hit :: proc(obj: Hitable, ray: Ray, ray_t: Interval, rec: ^HitRecord) -> bool {
	switch obj in obj {
	case Sphere:
		return hit_sphere(obj, ray, ray_t, rec)
	}
	panic("Unreachable")
}
hit_list :: proc(
	objs: []Hitable,
	r: Ray,
	ray_t: Interval,
	rec: ^HitRecord,
) -> bool {
	temp_rec: HitRecord
	hit_anything: bool
	closest_so_far := ray_t.max
	for obj in objs {
		if hit(obj, r, Interval{ray_t.min, closest_so_far}, &temp_rec) {
			hit_anything = true
			closest_so_far = temp_rec.t
			rec^ = temp_rec
		}
	}
	return hit_anything
}
