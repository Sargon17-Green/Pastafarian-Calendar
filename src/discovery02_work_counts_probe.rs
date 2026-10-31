//! Mərhələ 4 / DISCOVERY02: iki günün müstəqil müsbət iş-sayı zondu.
//! Tarixi legacy qüsuru və ya EXPECTED_RED iddiası yoxdur.
//! Beş tarix komponentini istehsal edən girişə qoşulmur.

use num_bigint::BigInt;
use std::cmp::Ordering;

use crate::discovery02_day_tag_probe::candidate_day_tag;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct CandidateWorkCounts {
    pub action: BigInt,
    pub target: BigInt,
    pub distance: BigInt,
    pub connection: BigInt,
    pub direction: u8,
}

/// Girişlər dəyişmir. Məsafə hər iki ucu daxil edir; eyni gün üçün 1-dir.
pub fn candidate_work_counts(
    calculation_day: &BigInt,
    target_day: &BigInt,
) -> CandidateWorkCounts {
    let action = candidate_day_tag(calculation_day);
    let target = candidate_day_tag(target_day);
    let mut distance = target_day - calculation_day;
    if distance < BigInt::from(0u8) {
        distance = -distance;
    }
    distance += BigInt::from(1u8);
    let connection = &action + &target;
    let direction = match target_day.cmp(calculation_day) {
        Ordering::Less => 1,
        Ordering::Equal => 2,
        Ordering::Greater => 3,
    };
    CandidateWorkCounts {
        action,
        target,
        distance,
        connection,
        direction,
    }
}
