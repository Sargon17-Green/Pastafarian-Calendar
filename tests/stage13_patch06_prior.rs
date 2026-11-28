#[path = "stage10_support/mod.rs"]
mod stage10_support;

use num_bigint::BigInt;
use pastafarian_calendar_rust_az::discovery06_prior_probe::PriorOutcome;
use pastafarian_calendar_rust_az::patch06_prior_probe::{
    corrected_prior, observe_corrected_prior, PriorPatch06,
};
use pastafarian_calendar_rust_az::{MonsterContext, PhaseHandler};
use stage10_support::{independent_hidden_values, independent_stones, FOUNDATION};

#[test]
fn stage13_signed_wide_raw_matrix() {
    let f = BigInt::from(FOUNDATION);
    let wide = BigInt::from(1u8) << 180usize;
    let zero = BigInt::from(0u8);
    let one = BigInt::from(1u8);
    let modulus = (&one << 127usize) - &one;
    let pairs = [
        (f.clone(), f.clone()),
        (&f - &one, f.clone()),
        (f.clone(), &f - &one),
        (&f + &one, f.clone()),
        (f.clone(), &f + &one),
        (zero.clone(), one.clone()),
        (one.clone(), zero.clone()),
        (-&wide, wide.clone()),
        (wide.clone(), -&wide),
        (wide.clone(), &wide + &one),
        (&wide + &one, wide.clone()),
        (-&wide, -&wide),
        (wide.clone(), wide.clone()),
    ];
    let stones = independent_stones();
    for (pair, (c, t)) in pairs.iter().enumerate() {
        println!("STAGE13_INPUT pair={pair} c={c} t={t}");
        let hidden = independent_hidden_values(c, t, &stones);
        let mut red = 0;
        let mut control = 0;
        for i in 1..=46 {
            let prefix: Vec<BigInt> = (1..i)
                .map(|j| match j % 3 {
                    0 => modulus.clone(),
                    1 => one.clone(),
                    _ => BigInt::from((pair + 1) * 100 + j),
                })
                .collect();
            let raw_prefix = prefix
                .iter()
                .map(ToString::to_string)
                .collect::<Vec<_>>()
                .join(",");
            println!("STAGE13_PREFIX pair={pair} i={i} values={raw_prefix}");
            for back in [1, 3, 7] {
                let context =
                    observe_corrected_prior(c.clone(), t.clone(), prefix.clone(), i, back).unwrap();
                let legacy = context.discovery06_prior_observation.unwrap();
                let observed = context.patch06_prior_observation.unwrap();
                assert_eq!(context.metrics.get("patch06.applied"), 1);
                assert_eq!(context.metrics.get("discovery06.prior.calls"), 1);
                assert_eq!(context.metrics.get("patch05.applied"), 1);
                assert_eq!((observed.i, observed.back), (i, back));
                assert_eq!(observed.slot, i as i32 - back as i32);
                let actual = match observed.outcome {
                    PriorOutcome::MissingVisibleSlot => "MISSING".to_owned(),
                    PriorOutcome::Visible(value) => value.to_string(),
                };
                let expected = if back >= i {
                    assert_eq!(legacy.outcome, PriorOutcome::MissingVisibleSlot);
                    red += 1;
                    &hidden[back + 1 - i]
                } else {
                    assert_eq!(
                        legacy.outcome,
                        PriorOutcome::Visible(prefix[i - back - 1].clone())
                    );
                    control += 1;
                    &prefix[i - back - 1]
                };
                assert_eq!(actual, expected.to_string());
                println!(
                    "STAGE13_RAW pair={pair} i={i} back={back} slot={} actual={actual} expected={expected}",
                    observed.slot
                );
            }
        }
        assert_eq!((red, control), (11, 127));
        println!("STAGE13_RAW_TOTAL pair={pair} RED={red} CONTROL={control}");
    }
}

#[test]
fn stage13_guards_and_atomicity() {
    let f = BigInt::from(FOUNDATION);
    let context = observe_corrected_prior(f.clone(), f.clone(), Vec::new(), 1, 1).unwrap();
    let storage = context.discovery05_backward_storage.clone().unwrap();
    for (i, back) in [(0, 1), (47, 1), (1, 0), (1, 2), (usize::MAX, 7)] {
        assert!(corrected_prior(&[], &storage, i, back).is_err());
    }
    assert!(corrected_prior(&[], &storage, 2, 1).is_err());
    assert!(corrected_prior(&[BigInt::from(0u8)], &storage, 2, 1).is_err());
    assert!(corrected_prior(&[], &[], 1, 1).is_err());
    let mut invalid = storage.clone();
    invalid[0] = BigInt::from(1u8);
    assert!(corrected_prior(&[], &invalid, 1, 1).is_err());
    invalid = storage;
    invalid[7] = BigInt::from(0u8);
    assert!(corrected_prior(&[], &invalid, 1, 1).is_err());
    let handler = PriorPatch06 {
        visible_prefix: Vec::new(),
        i: 1,
        back: 1,
    };
    let mut missing = MonsterContext::new(f.clone(), f);
    let before = missing.clone();
    assert!(handler.handle(&mut missing).is_err());
    assert_eq!(missing, before);
    let mut duplicate = context;
    let before = duplicate.clone();
    assert!(handler.handle(&mut duplicate).is_err());
    assert_eq!(duplicate, before);
}
