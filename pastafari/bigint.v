module pastafari

const bigint_base = u64(1_000_000_000)

pub struct BigInt {
pub:
	sign  int
	limbs []u32
}

pub fn big_zero() BigInt {
	return BigInt{}
}

pub fn big_one() BigInt {
	return BigInt{
		sign: 1
		limbs: [u32(1)]
	}
}

pub fn big_from_int(value int) BigInt {
	return big_from_i64(i64(value))
}

pub fn big_from_i64(value i64) BigInt {
	if value == 0 {
		return big_zero()
	}
	mut magnitude := u64(0)
	mut sign := 1
	if value < 0 {
		sign = -1
		magnitude = u64(-(value + 1)) + 1
	} else {
		magnitude = u64(value)
	}
	return big_from_u64_with_sign(magnitude, sign)
}

pub fn big_from_u64(value u64) BigInt {
	return big_from_u64_with_sign(value, 1)
}

fn big_from_u64_with_sign(value u64, sign int) BigInt {
	if value == 0 {
		return big_zero()
	}
	mut n := value
	mut limbs := []u32{}
	for n > 0 {
		limbs << u32(n % bigint_base)
		n /= bigint_base
	}
	return BigInt{
		sign: sign
		limbs: limbs
	}
}

fn big_normalized(sign int, limbs []u32) BigInt {
	mut end := limbs.len
	for end > 0 && limbs[end - 1] == 0 {
		end--
	}
	if end == 0 {
		return big_zero()
	}
	actual_sign := if sign < 0 { -1 } else { 1 }
	return BigInt{
		sign: actual_sign
		limbs: limbs[..end].clone()
	}
}

pub fn (a BigInt) is_zero() bool {
	return a.sign == 0 || a.limbs.len == 0
}

pub fn big_abs(a BigInt) BigInt {
	if a.is_zero() {
		return big_zero()
	}
	return BigInt{
		sign: 1
		limbs: a.limbs.clone()
	}
}

pub fn big_neg(a BigInt) BigInt {
	if a.is_zero() {
		return big_zero()
	}
	return BigInt{
		sign: -a.sign
		limbs: a.limbs.clone()
	}
}

fn big_cmp_abs(a BigInt, b BigInt) int {
	if a.limbs.len < b.limbs.len {
		return -1
	}
	if a.limbs.len > b.limbs.len {
		return 1
	}
	for step := 0; step < a.limbs.len; step++ {
		i := a.limbs.len - 1 - step
		if a.limbs[i] < b.limbs[i] {
			return -1
		}
		if a.limbs[i] > b.limbs[i] {
			return 1
		}
	}
	return 0
}

pub fn big_cmp(a BigInt, b BigInt) int {
	if a.sign < b.sign {
		return -1
	}
	if a.sign > b.sign {
		return 1
	}
	if a.sign == 0 {
		return 0
	}
	cmp := big_cmp_abs(a, b)
	return if a.sign > 0 { cmp } else { -cmp }
}

pub fn big_eq(a BigInt, b BigInt) bool {
	return big_cmp(a, b) == 0
}

fn big_add_abs(a BigInt, b BigInt) BigInt {
	max_len := if a.limbs.len > b.limbs.len { a.limbs.len } else { b.limbs.len }
	mut out := []u32{len: max_len + 1, init: 0}
	mut carry := u64(0)
	for i in 0 .. max_len {
		av := if i < a.limbs.len { u64(a.limbs[i]) } else { u64(0) }
		bv := if i < b.limbs.len { u64(b.limbs[i]) } else { u64(0) }
		sum := av + bv + carry
		out[i] = u32(sum % bigint_base)
		carry = sum / bigint_base
	}
	if carry > 0 {
		out[max_len] = u32(carry)
	}
	return big_normalized(1, out)
}

fn big_sub_abs(a BigInt, b BigInt) BigInt {
	mut out := []u32{len: a.limbs.len, init: 0}
	mut borrow := i64(0)
	for i in 0 .. a.limbs.len {
		av := i64(a.limbs[i])
		bv := if i < b.limbs.len { i64(b.limbs[i]) } else { i64(0) }
		mut value := av - bv - borrow
		if value < 0 {
			value += i64(bigint_base)
			borrow = 1
		} else {
			borrow = 0
		}
		out[i] = u32(value)
	}
	return big_normalized(1, out)
}

pub fn big_add(a BigInt, b BigInt) BigInt {
	if a.is_zero() {
		return BigInt{
			sign: b.sign
			limbs: b.limbs.clone()
		}
	}
	if b.is_zero() {
		return BigInt{
			sign: a.sign
			limbs: a.limbs.clone()
		}
	}
	if a.sign == b.sign {
		sum := big_add_abs(a, b)
		return BigInt{
			sign: a.sign
			limbs: sum.limbs
		}
	}
	cmp := big_cmp_abs(a, b)
	if cmp == 0 {
		return big_zero()
	}
	if cmp > 0 {
		diff := big_sub_abs(a, b)
		return BigInt{
			sign: a.sign
			limbs: diff.limbs
		}
	}
	diff := big_sub_abs(b, a)
	return BigInt{
		sign: b.sign
		limbs: diff.limbs
	}
}

pub fn big_sub(a BigInt, b BigInt) BigInt {
	return big_add(a, big_neg(b))
}

pub fn big_mul_small(a BigInt, factor u32) BigInt {
	if a.is_zero() || factor == 0 {
		return big_zero()
	}
	mut out := []u32{len: a.limbs.len + 1, init: 0}
	mut carry := u64(0)
	for i in 0 .. a.limbs.len {
		value := u64(a.limbs[i]) * u64(factor) + carry
		out[i] = u32(value % bigint_base)
		carry = value / bigint_base
	}
	if carry > 0 {
		out[a.limbs.len] = u32(carry)
	}
	return big_normalized(a.sign, out)
}

pub fn big_mul(a BigInt, b BigInt) BigInt {
	if a.is_zero() || b.is_zero() {
		return big_zero()
	}
	mut out := []u64{len: a.limbs.len + b.limbs.len + 1, init: 0}
	for i in 0 .. a.limbs.len {
		mut carry := u64(0)
		for j in 0 .. b.limbs.len {
			idx := i + j
			value := out[idx] + u64(a.limbs[i]) * u64(b.limbs[j]) + carry
			out[idx] = value % bigint_base
			carry = value / bigint_base
		}
		mut idx := i + b.limbs.len
		for carry > 0 {
			value := out[idx] + carry
			out[idx] = value % bigint_base
			carry = value / bigint_base
			idx++
		}
	}
	mut limbs := []u32{len: out.len, init: 0}
	for i, value in out {
		limbs[i] = u32(value)
	}
	return big_normalized(a.sign * b.sign, limbs)
}

pub fn big_square(a BigInt) BigInt {
	return big_mul(a, a)
}

fn big_shift_base_add(a BigInt, limb u32) BigInt {
	if a.is_zero() {
		if limb == 0 {
			return big_zero()
		}
		return BigInt{
			sign: 1
			limbs: [limb]
		}
	}
	mut out := []u32{len: a.limbs.len + 1, init: 0}
	out[0] = limb
	for i in 0 .. a.limbs.len {
		out[i + 1] = a.limbs[i]
	}
	return big_normalized(1, out)
}

fn big_div_mod_abs(a BigInt, b BigInt) (BigInt, BigInt) {
	if b.is_zero() {
		panic('በዜሮ መካፈል አይፈቀድም')
	}
	if big_cmp_abs(a, b) < 0 {
		return big_zero(), big_abs(a)
	}
	mut quotient := []u32{len: a.limbs.len, init: 0}
	mut remainder := big_zero()
	for step := 0; step < a.limbs.len; step++ {
		i := a.limbs.len - 1 - step
		remainder = big_shift_base_add(remainder, a.limbs[i])
		mut low := u64(0)
		mut high := bigint_base - 1
		mut digit := u64(0)
		for low <= high {
			mid := low + (high - low) / 2
			candidate := big_mul_small(b, u32(mid))
			cmp := big_cmp_abs(candidate, remainder)
			if cmp <= 0 {
				digit = mid
				low = mid + 1
			} else {
				if mid == 0 {
					break
				}
				high = mid - 1
			}
		}
		quotient[i] = u32(digit)
		if digit > 0 {
			remainder = big_sub_abs(remainder, big_mul_small(b, u32(digit)))
		}
	}
	return big_normalized(1, quotient), big_normalized(1, remainder.limbs)
}

pub fn big_div_mod_floor(a BigInt, b BigInt) (BigInt, BigInt) {
	if b.sign <= 0 {
		panic('አካፋዩ ከዜሮ በላይ መሆን አለበት')
	}
	if a.is_zero() {
		return big_zero(), big_zero()
	}
	q_abs, r_abs := big_div_mod_abs(big_abs(a), b)
	if a.sign > 0 {
		return q_abs, r_abs
	}
	if r_abs.is_zero() {
		return big_neg(q_abs), big_zero()
	}
	q := big_neg(big_add(q_abs, big_one()))
	r := big_sub(b, r_abs)
	return q, r
}

pub fn big_floor_div(a BigInt, b BigInt) BigInt {
	q, _ := big_div_mod_floor(a, b)
	return q
}

pub fn big_regular_mod(a BigInt, modulus BigInt) BigInt {
	_, r := big_div_mod_floor(a, modulus)
	return r
}

pub fn big_mod_small_nonnegative(a BigInt, modulus u32) u32 {
	if modulus == 0 {
		panic('ሞዱሉ ዜሮ መሆን አይችልም')
	}
	if a.sign < 0 {
		r := big_mod_small_nonnegative(big_abs(a), modulus)
		if r == 0 {
			return 0
		}
		return modulus - r
	}
	mut rem := u64(0)
	for step := 0; step < a.limbs.len; step++ {
		i := a.limbs.len - 1 - step
		rem = (rem * bigint_base + u64(a.limbs[i])) % u64(modulus)
	}
	return u32(rem)
}

pub fn big_pow_small(base BigInt, exponent int) BigInt {
	if exponent < 0 {
		panic('አሉታዊ ኃይል በዚህ የቁጥር አይነት አይፈቀድም')
	}
	mut result := big_one()
	mut factor := base
	mut e := exponent
	for e > 0 {
		if e % 2 == 1 {
			result = big_mul(result, factor)
		}
		e /= 2
		if e > 0 {
			factor = big_square(factor)
		}
	}
	return result
}

pub fn big_to_int(a BigInt) !int {
	if a.is_zero() {
		return 0
	}
	mut value := u64(0)
	for step := 0; step < a.limbs.len; step++ {
		i := a.limbs.len - 1 - step
		if value > (u64(0x7fffffff) / bigint_base) + 1 {
			return error('ቁጥሩ ወደ int ለመቀየር በጣም ትልቅ ነው')
		}
		value = value * bigint_base + u64(a.limbs[i])
	}
	if a.sign > 0 {
		if value > u64(0x7fffffff) {
			return error('ቁጥሩ ወደ int ለመቀየር በጣም ትልቅ ነው')
		}
		return int(value)
	}
	if value > u64(0x80000000) {
		return error('ቁጥሩ ወደ int ለመቀየር በጣም ትልቅ ነው')
	}
	return -int(value)
}

pub fn (a BigInt) str() string {
	if a.is_zero() {
		return '0'
	}
	mut out := if a.sign < 0 { '-' } else { '' }
	last := a.limbs.len - 1
	out += a.limbs[last].str()
	for step := 1; step < a.limbs.len; step++ {
		i := a.limbs.len - 1 - step
		chunk := a.limbs[i].str()
		out += '0'.repeat(9 - chunk.len) + chunk
	}
	return out
}
