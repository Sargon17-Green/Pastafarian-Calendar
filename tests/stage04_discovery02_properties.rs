//! Stage4/DISCOVERY02: independent metamorphic checks, not a historical RED claim.
#[rustfmt::skip]
mod support;

use num_bigint::BigInt;
use num_integer::Integer;
use num_traits::{One, Zero};
use pastafarian_calendar_rust_az::discovery02_day_tag_probe::candidate_day_tag;
use std::collections::BTreeSet;
use support::normative_oracle as oracle;

#[test]
fn signed_local_window_is_bijective_and_reversible() {
    let foundation = oracle::foundation_day();
    let mut observed = BTreeSet::new();
    for offset in -512i32..=512 {
        let day = &foundation + BigInt::from(offset);
        let before = day.clone();
        let tag = candidate_day_tag(&day);
        assert_eq!(day, before, "day input must not be mutated");
        assert!(tag > BigInt::zero(), "tag must be positive");
        assert_eq!(tag, oracle::day_count(&day));
        assert!(observed.insert(tag.clone()), "tag collision at offset {offset}");
        let restored = if tag.is_odd() {
            &foundation + ((&tag - BigInt::one()) / BigInt::from(2u8))
        } else {
            &foundation - (&tag / BigInt::from(2u8))
        };
        assert_eq!(restored, day, "round-trip at offset {offset}");
    }
    assert_eq!(observed.len(), 1025);
    for tag in 1u16..=1025u16 {
        assert!(observed.contains(&BigInt::from(tag)), "missing tag {tag}");
    }
    println!("STAGE04_DISCOVERY02_BIJECTION_CASES=1025");
}

#[test]
fn symmetric_huge_offsets_keep_adjacent_even_odd_tags() {
    let foundation = oracle::foundation_day();
    for bits in [1usize, 127, 1025, 4096] {
        let delta = BigInt::one() << bits;
        let future = &foundation + &delta;
        let past = &foundation - &delta;
        let future_before = future.clone();
        let past_before = past.clone();
        let future_tag = candidate_day_tag(&future);
        let past_tag = candidate_day_tag(&past);
        assert_eq!(future, future_before);
        assert_eq!(past, past_before);
        assert_eq!(future_tag, oracle::day_count(&future));
        assert_eq!(past_tag, oracle::day_count(&past));
        assert!(future_tag.is_odd(), "future day at 2^{bits}");
        assert!(past_tag.is_even(), "past day at 2^{bits}");
        assert_eq!(&future_tag - &past_tag, BigInt::one());
        assert_eq!(past_tag, &delta << 1usize);
    }
    println!("STAGE04_DISCOVERY02_SYMMETRIC_HUGE_CASES=8");
}
