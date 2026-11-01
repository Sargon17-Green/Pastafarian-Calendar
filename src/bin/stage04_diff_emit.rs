//! Mərhələ 4: Python arxiv marşrutu ilə birbaşa diferensial üçün Rust TSV çıxışı.
//! Bu binary yalnız QA üçündür; istehsalın beş-komponentli girişini dəyişmir.

use num_bigint::BigInt;
use num_traits::One;
use pastafarian_calendar_rust_az::discovery02_day_tag_probe::candidate_day_tag;

#[allow(dead_code)]
#[rustfmt::skip]
#[path = "../../tests/support/normative_oracle.rs"]
mod normative_oracle;

fn main() {
    let foundation = normative_oracle::foundation_day();
    let mut offsets: Vec<BigInt> = (-3i8..=3i8).map(BigInt::from).collect();
    for bits in [127usize, 1025, 4096, 8192] {
        let magnitude = BigInt::one() << bits;
        offsets.push(-magnitude.clone());
        offsets.push(magnitude);
    }
    assert_eq!(offsets.len(), 15);
    println!("index\tday\toracle\tcandidate");
    for (index, offset) in offsets.iter().enumerate() {
        let day = &foundation + offset;
        println!(
            "{}\t{}\t{}\t{}",
            index,
            day,
            normative_oracle::day_count(&day),
            candidate_day_tag(&day)
        );
    }
}
