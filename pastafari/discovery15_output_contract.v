module pastafari

// Stage 30: deterministic five-field shape oracle; no assertion of date arithmetic.
pub fn discovery15_five_components(value CalendarResult) []string {
	return [value.year_number.str(), value.cutlet_name, value.day_in_cutlet.str(), value.month_name,
		value.day_in_month.str()]
}

fn discovery15_known_cutlet(name string) bool {
	for i in 1 .. 18 {
		candidate := cutlet_name_by_index(i) or { return false }
		if candidate == name {
			return true
		}
	}
	return false
}

fn discovery15_known_month(name string) bool {
	for i in 1 .. 48 {
		candidate := month_name_by_index(i) or { return false }
		if candidate == name {
			return true
		}
	}
	return false
}

pub fn discovery15_output_shape_oracle(value CalendarResult) bool {
	if big_cmp(value.day_in_cutlet, big_one()) < 0 || big_cmp(value.day_in_month, big_one()) < 0 {
		return false
	}
	if !discovery15_known_cutlet(value.cutlet_name) || !discovery15_known_month(value.month_name) {
		return false
	}
	return discovery15_five_components(value).len == 5
}
