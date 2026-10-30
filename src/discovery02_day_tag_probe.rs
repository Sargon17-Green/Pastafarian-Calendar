//! Mərhələ 4 — DISCOVERY02: gün-sayğacı üçün ayrıca müsbət baza zondudur.
//! Bu fayl tarixi qüsur və ya EXPECTED_RED olduğunu iddia etmir.
//! İstehsalın beş-komponentli təqvim girişinə hələ bağlanmır.

use num_bigint::{BigInt, Sign};
use num_traits::Signed;

/// F = -15_055_671. F və sonrakı günlər tək, əvvəlkilər cüt etiketi alır.
/// Hər işarəli BigInt gün üçün nəticə müsbətdir.
pub fn candidate_day_tag(day: &BigInt) -> BigInt {
    let delta = day - BigInt::from(-15_055_671i64);
    let side_bit = if delta.sign() == Sign::Minus {
        0u8
    } else {
        1u8
    };
    (delta.abs() << 1usize) + BigInt::from(side_bit)
}
