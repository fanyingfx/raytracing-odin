package raytracing

import "core:math"
import la "core:math/linalg"
import "core:math/rand"
material_scatter :: proc(r_in: Ray, rec: HitRecord, attenuation: Color, scattered: Ray) -> bool {
	return false
}

Lambertian :: struct {
	albedo: Color,
}
Metal :: struct {
	albedo: Color,
	fuzz:   f64,
}

Dielectric :: struct {
	refraction_index: f64,
}

Material :: union {
	Lambertian,
	Metal,
	Dielectric,
}

lambertian_scatter :: proc(
	lam: Lambertian,
	r_in: Ray,
	rec: HitRecord,
	attenuation: ^Color,
	scattered: ^Ray,
) -> bool {
	scatter_direction := rec.normal + random_unit_vec()

	if vec_near_zero(scatter_direction) {
		scatter_direction = rec.normal
	}
	scattered^ = Ray{rec.p, scatter_direction}
	attenuation^ = lam.albedo
	return true
}
metal_scatter :: proc(
	metal: Metal,
	r_in: Ray,
	rec: HitRecord,
	attenuation: ^Color,
	scattered: ^Ray,
) -> bool {
	reflected := reflect(r_in.dir, rec.normal)
	reflected = la.normalize(reflected) + (metal.fuzz * random_unit_vec())
	scattered^ = {rec.p, reflected}
	attenuation^ = metal.albedo
	return la.dot(scattered.dir, rec.normal) > 0
}
dielectric_scatter :: proc(
	diel: Dielectric,
	r_in: Ray,
	rec: HitRecord,
	attenuation: ^Color,
	scattered: ^Ray,
) -> bool {
	reflectance :: proc(cosine: f64, refraction_index: f64) -> f64 {
		r0 := (1 - refraction_index) / (1 + refraction_index)
		r0 = r0 * r0
		return r0 + (1-r0)*math.pow((1-cosine),5)

	}
	attenuation^ = {1.0, 1.0, 1.0}
	ri := rec.front_face ? (1.0 / diel.refraction_index) : diel.refraction_index

	unit_direction := la.normalize(r_in.dir)

	cos_theta := min(la.dot(-unit_direction, rec.normal), 1.0)
	sin_theta := math.sqrt(1.0 - cos_theta * cos_theta)

	cannot_refract := ri * sin_theta > 1.0
	direction: Vec3

	if cannot_refract || reflectance(cos_theta,ri)>rand.float64(){

		direction = reflect(unit_direction, rec.normal)
	} else {

		direction = refract(unit_direction, rec.normal, ri)
	}

	scattered^ = {rec.p, direction}
	// refracted:= refract(unit_direction,rec.normal,ri)

	// scattered^ = Ray{rec.p,refracted}
	return true
}
