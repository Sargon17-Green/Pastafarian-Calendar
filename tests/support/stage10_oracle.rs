use num_bigint::BigInt;
use num_traits::{One, Signed};

pub const FOUNDATION: i64 = -15_055_671;

pub fn independent_save(raw: &BigInt) -> BigInt {
    let modulus = (BigInt::one() << 127usize) - BigInt::one();
    let mut remainder = (raw - BigInt::one()) % &modulus;
    if remainder.is_negative() {
        remainder += &modulus;
    }
    remainder + BigInt::one()
}

pub fn independent_day_tag(day: &BigInt) -> BigInt {
    let foundation = BigInt::from(FOUNDATION);
    if day == &foundation {
        BigInt::one()
    } else if day > &foundation {
        (day - foundation) * BigInt::from(2u8) + BigInt::one()
    } else {
        (foundation - day) * BigInt::from(2u8)
    }
}

pub fn independent_stones() -> Vec<[BigInt; 5]> {
    let mut rows = Vec::with_capacity(46);
    rows.push([17, 29, 43, 71, 101].map(BigInt::from));
    for row in 2..=46 {
        let old = rows.last().expect("seed row exists");
        rows.push([
            independent_save(&(&old[0] * &old[0] + BigInt::from(3u8) * &old[1] + BigInt::from(row))),
            independent_save(&(&old[1] * &old[1] + BigInt::from(5u8) * &old[2] + &old[0])),
            independent_save(&(&old[2] * &old[2] + BigInt::from(7u8) * &old[3] + &old[1])),
            independent_save(&(&old[3] * &old[3] + BigInt::from(11u8) * &old[4] + &old[2])),
            independent_save(&(&old[4] * &old[4] + BigInt::from(13u8) * &old[0] + &old[3])),
        ]);
    }
    rows
}

pub fn independent_hidden_values(
    calculation_day: &BigInt,
    target_day: &BigInt,
    stones: &[[BigInt; 5]],
) -> Vec<BigInt> {
    let action = independent_day_tag(calculation_day);
    let target = independent_day_tag(target_day);
    let distance = (target_day - calculation_day).abs() + BigInt::one();
    let connection = &action + &target;
    let direction = BigInt::from(if target_day < calculation_day {
        1u8
    } else if target_day == calculation_day {
        2u8
    } else {
        3u8
    });
    let coefficients = [
        [3u8, 4, 6, 8],
        [5u8, 7, 10, 12],
        [7u8, 10, 14, 16],
        [9u8, 13, 18, 20],
        [11u8, 16, 22, 24],
        [13u8, 19, 26, 28],
        [15u8, 22, 30, 32],
    ];
    let grind_kinds = [0usize, 1, 2, 3, 4, 0, 1];
    let mut hidden = vec![BigInt::from(0u8); 8];
    for k in 1..=7 {
        let row = &stones[k - 1];
        let coeff = coefficients[k - 1];
        let mut value = action.clone();
        value += &target * BigInt::from(coeff[0]);
        value += &distance * BigInt::from(coeff[1]);
        value += &connection * BigInt::from(coeff[2]);
        value += &direction * BigInt::from(coeff[3]);
        for component in row {
            value += component;
        }
        value = independent_save(&value);
        for (offset, kind) in grind_kinds.iter().enumerate() {
            let old = value.clone();
            let mut raw = &old * &old + BigInt::from(3u8) * &old;
            raw += &row[*kind];
            raw += BigInt::from(offset + 1);
            value = independent_save(&raw);
        }
        hidden[k] = value;
    }
    hidden
}
