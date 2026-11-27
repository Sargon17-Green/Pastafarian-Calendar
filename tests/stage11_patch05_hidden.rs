#[path = "stage10_support/mod.rs"]
mod stage10_support;

use num_bigint::BigInt;
use pastafarian_calendar_rust_az::discovery05_hidden_probe::observe_legacy_hidden_drop;
use pastafarian_calendar_rust_az::patch05_hidden_probe::{
    calendar_hidden_spaghetti, corrected_hidden_by_nearness, observe_corrected_hidden_drop,
    HiddenDropPatch05,
};
use pastafarian_calendar_rust_az::{MonsterContext, MonsterErrorCode, PhaseHandler};
use stage10_support::{independent_hidden_values, independent_stones, FOUNDATION};

#[test]
fn stage11_patch05_successor_matrix() {
    let f = BigInt::from(FOUNDATION);
    let wide = BigInt::from(1u8) << 129usize;
    let huge = BigInt::from(1u8) << 1031usize;
    let pairs = [
        (f.clone(), f.clone()),
        (&f - 10, &f + 11),
        (&f + 34, &f - 19),
        (&f - 90_001, &f - 90_001),
        (&f + 123_456_789, &f - 987_654_321),
        (&f - 1, &f + 1),
        (&f + 1, &f - 1),
        (&f - 1, &f - 1),
        (&f + 1, &f + 1),
        (-&wide, wide.clone()),
        (wide.clone(), -&wide),
        (-&huge, huge.clone()),
        (huge.clone(), -&huge),
    ];
    let stones = independent_stones();
    for (case, (c, t)) in pairs.iter().enumerate() {
        println!("STAGE11_INPUT case={case} c={c} t={t}");
        let expected = independent_hidden_values(c, t, &stones);
        let legacy = observe_legacy_hidden_drop(c.clone(), t.clone(), 1).unwrap();
        for slot in 0..8 {
            let logical = if slot == 0 { 0 } else { 8 - slot };
            assert_eq!(legacy.backward_storage[slot], expected[logical]);
            println!(
                "STAGE11_STORAGE case={case} slot={slot} value={}",
                legacy.backward_storage[slot]
            );
        }
        for k in 1..=7 {
            let result = observe_corrected_hidden_drop(c.clone(), t.clone(), k).unwrap();
            assert_eq!(result.corrected.actual, expected[k]);
            assert_eq!(result.corrected.physical_index, 8 - k);
            assert_eq!(result.backward_storage, legacy.backward_storage);
            assert_eq!(
                result.context.discovery05_actual,
                Some(expected[8 - k].clone())
            );
            assert_eq!(result.context.metrics.get("discovery05.builds"), 1);
            assert_eq!(
                result.context.metrics.get("discovery05.legacy.direct.read"),
                1
            );
            assert_eq!(result.context.metrics.get("patch05.corrected.read"), 1);
            assert_eq!(result.context.metrics.get("patch05.applied"), 1);
            println!(
                "STAGE11_CELL case={case} k={k} slot={} corrected={} legacy={}",
                result.corrected.physical_index,
                result.corrected.actual,
                result.context.discovery05_actual.as_ref().unwrap()
            );
        }
    }
    let default = calendar_hidden_spaghetti(f.clone(), f.clone()).unwrap();
    assert_eq!(
        default.corrected.actual.to_string(),
        "119390830530032782664128530203002080344"
    );
    assert_ne!(
        default.context.discovery05_actual,
        Some(default.corrected.actual)
    );
    println!("STAGE11_PATCH05_MATRIX=91 STORAGE=104");
    println!("STAGE11_STRICT_GREEN_K1=PASS");
}

#[test]
fn stage11_patch05_guards_are_atomic() {
    let f = BigInt::from(FOUNDATION);
    let legacy = observe_legacy_hidden_drop(f.clone(), f.clone(), 1).unwrap();
    let storage = &legacy.backward_storage;
    for k in [0, 8, usize::MAX] {
        assert_eq!(
            corrected_hidden_by_nearness(storage, k).unwrap_err().code,
            MonsterErrorCode::InvalidState
        );
    }
    for len in [0, 1, 7, 9] {
        assert_eq!(
            corrected_hidden_by_nearness(&vec![BigInt::from(0u8); len], 1)
                .unwrap_err()
                .code,
            MonsterErrorCode::InvalidState
        );
    }
    let mut bad_sentinel = storage.clone();
    bad_sentinel[0] = BigInt::from(1u8);
    assert_eq!(
        corrected_hidden_by_nearness(&bad_sentinel, 1)
            .unwrap_err()
            .code,
        MonsterErrorCode::InvalidState
    );
    let handler = HiddenDropPatch05 { requested_k: 1 };
    let mut missing = MonsterContext::new(f.clone(), f.clone());
    let mut wrong_request = legacy.context.clone();
    wrong_request.discovery05_requested_k = Some(2);
    let mut wrong_counts = legacy.context.clone();
    wrong_counts.metrics.bump("discovery05.builds");
    let mut wrong_storage = legacy.context.clone();
    wrong_storage.discovery05_backward_storage = Some(bad_sentinel);
    let mut wrong_legacy = legacy.context.clone();
    wrong_legacy.discovery05_actual = Some(BigInt::from(0u8));
    for context in [
        &mut missing,
        &mut wrong_request,
        &mut wrong_counts,
        &mut wrong_storage,
        &mut wrong_legacy,
    ] {
        let before = context.clone();
        assert_eq!(
            handler.handle(context).unwrap_err().code,
            MonsterErrorCode::InvalidState
        );
        assert_eq!(*context, before);
    }
    let mut valid = legacy.context.clone();
    handler.handle(&mut valid).unwrap();
    let before = valid.clone();
    assert_eq!(
        handler.handle(&mut valid).unwrap_err().code,
        MonsterErrorCode::InvalidState
    );
    assert_eq!(valid, before);
    assert!(legacy.context.patch05_hidden_observation.is_none());
    println!("STAGE11_PATCH05_GUARDS=PASS");
}
