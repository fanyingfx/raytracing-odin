package raytracing
Interval :: struct {
	min: f64,
	max: f64,
}

EMPTY_INTERVAL :: Interval{Infinity, -Infinity}
UNIVERSE_INTERVAL :: Interval{-Infinity, Infinity}

interval_size :: proc(interval: Interval) -> f64 {
	return interval.max - interval.min
}

interval_contains :: proc(interval: Interval, x: f64) -> bool {
	return interval.min <= x && x <= interval.max
}
interval_surrounds :: proc(interval: Interval, x: f64) -> bool {

	return interval.min < x && x < interval.max
}
