package raytracing

import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import "core:time"

vec_near_zero :: proc(vec: Vec3) -> bool {
	s := 1e-8
	return (math.abs(vec.x) < s) && (math.abs(vec.y) < s) && (math.abs(vec.z) < s)
}
random_f64 :: proc() -> f64 {
	return rand.float64_range(0, 1)
}
random_vec :: proc() -> Vec3 {
	return {random_f64(), random_f64(), random_f64()}
}
random_vec_range :: proc(min: f64, max: f64) -> Vec3 {
	return {
		rand.float64_range(min, max),
		rand.float64_range(min, max),
		rand.float64_range(min, max),
	}
}
random_unit_vec :: proc() -> Vec3 {
	return la.normalize(random_vec_range(-1, 1))
}

random_on_hemisphere :: proc(normal: Vec3) -> Vec3 {
	on_unit_sphere := random_unit_vec()

	if la.dot(on_unit_sphere, normal) > 0 {
		return on_unit_sphere
	}

	return -on_unit_sphere

}
random_in_uint_disk :: proc() -> Vec3 {
	for {
		p: Vec3 = {rand.float64_range(-1, 1), rand.float64_range(-1, 1), 0}
		if la.length2(p) < 1 do return p
	}
}
reflect :: proc(v: Vec3, n: Vec3) -> Vec3 {
	return v - 2 * la.dot(v, n) * n
}

refract :: proc(uv: Vec3, n: Vec3, etai_over_etat: f64) -> Vec3 {
	cos_theta := min(la.dot(-uv, n), 1.0)
	r_out_prep: Vec3 = etai_over_etat * (uv + cos_theta * n)
	r_out_parallel: Vec3 = -math.sqrt(math.abs(1.0 - la.length2(r_out_prep))) * n
	return r_out_prep + r_out_parallel
}
