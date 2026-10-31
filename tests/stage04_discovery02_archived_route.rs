//! Stage4/DISCOVERY02: arxivdə təsdiqlənmiş tarixi gün-etiketi marşrutunun sübutu.
//! Mənbə: python-turkish-v1.0.0-verified-20261030,
//! src/pastafari_calendar/legacy_day_counts.py, blob 405f461b2e2cdd170ded010e6f8046b78d6b4ab6.
//! Burada yalnız ayrıca test müşahidəsi var; istehsal yoluna bağlanmır.
#[rustfmt::skip]
mod support;

use num_bigint::BigInt;
use num_traits::{One, Signed, Zero};
use pastafarian_calendar_rust_az::discovery02_day_tag_probe::candidate_day_tag;
use support::normative_oracle as oracle;

const ARCHIVED_FOUNDATION_DAY: i64 = -15_055_671;

// Tarixi Python oldDayTag marşrutunun müstəqil Rust riyazi rekonstruksiyası.
// Normativ oracle bu funksiyadan istifadə etmir.
fn archived_legacy_day_tag(day: &BigInt) -> BigInt {
    (day - BigInt::from(ARCHIVED_FOUNDATION_DAY)).abs() << 1usize
}

// Tarixi Python dayTagWithFoundationScar düzəlişinin test-only rekonstruksiyası.
fn archived_patched_day_tag(day: &BigInt) -> BigInt {
    let mut tag = archived_legacy_day_tag(day);
    let foundation = BigInt::from(ARCHIVED_FOUNDATION_DAY);
    if day >= &foundation {
        tag += BigInt::one();
    }
    if day == &foundation && tag != BigInt::one() {
        tag = BigInt::one();
    }
    tag
}

fn witness_offsets() -> Vec<BigInt> {
    let mut offsets = (-3i8..=3i8).map(BigInt::from).collect::<Vec<_>>();
    for bits in [127usize, 1025, 4096, 8192] {
        let magnitude = BigInt::one() << bits;
        offsets.push(-magnitude.clone());
        offsets.push(magnitude);
    }
    offsets
}

#[test]
fn archived_legacy_route_exposes_exact_red_and_control() {
    let foundation = BigInt::from(ARCHIVED_FOUNDATION_DAY);
    assert_eq!(foundation, oracle::foundation_day());
    let mut red = 0usize;
    let mut control = 0usize;
    let offsets = witness_offsets();
    assert_eq!(offsets.len(), 15);

    for offset in offsets {
        let day = &foundation + &offset;
        let legacy = archived_legacy_day_tag(&day);
        let normative = oracle::day_count(&day);
        if offset >= BigInt::zero() {
            assert_ne!(legacy, normative, "RED offset {offset}");
            assert_eq!(&normative - &legacy, BigInt::one());
            red += 1;
        } else {
            assert_eq!(legacy, normative, "CONTROL offset {offset}");
            control += 1;
        }
        assert_eq!(candidate_day_tag(&day), normative);
    }

    assert_eq!((red, control), (8, 7));
    println!("STAGE04_DISCOVERY02_ARCHIVED_RED=8 CONTROL=7 UNEXPECTED=0");
}

#[test]
fn archived_patch_and_current_candidate_match_independent_oracle() {
    let foundation = BigInt::from(ARCHIVED_FOUNDATION_DAY);
    let mut count = 0usize;
    for offset in witness_offsets() {
        let day = &foundation + &offset;
        let before = day.clone();
        let normative = oracle::day_count(&day);
        assert_eq!(archived_patched_day_tag(&day), normative);
        assert_eq!(candidate_day_tag(&day), normative);
        assert_eq!(day, before);
        count += 1;
    }
    assert_eq!(count, 15);
    println!("STAGE04_DISCOVERY02_ARCHIVED_PATCH_CONTROL=15");
}
