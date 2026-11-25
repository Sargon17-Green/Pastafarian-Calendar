mod support;

use num_bigint::BigInt;
use num_traits::One;

use pastafarian_calendar_rust_az::discovery05_hidden_probe::{
    calendar_hidden_by_nearness, calendar_hidden_spaghetti, observe_legacy_hidden_drop,
    LegacyHiddenDropDiscovery05,
};
use pastafarian_calendar_rust_az::{calendar_date_spaghetti, MonsterContext, MonsterErrorCode, PhaseHandler};
use support::stage10_oracle::{independent_hidden_values, independent_stones, FOUNDATION};

#[test]
fn stage10_backward_storage_expected_red_and_context_guards() {
    let foundation = BigInt::from(FOUNDATION);
    let stones = independent_stones();
    let expected = independent_hidden_values(&foundation, &foundation, &stones);
    let observed = calendar_hidden_spaghetti(foundation.clone(), foundation.clone()).unwrap();

    assert_eq!(observed.requested_k, 1);
    assert_eq!(observed.backward_storage.len(), 8);
    assert_eq!(observed.backward_storage[0], BigInt::from(0u8));
    assert_eq!(observed.actual, observed.backward_storage[1]);
    assert_eq!(observed.context.discovery05_hidden_count, 7);
    assert_eq!(observed.context.discovery05_requested_k, Some(1));
    assert_eq!(observed.context.discovery05_actual, Some(observed.actual.clone()));
    assert_eq!(observed.context.discovery05_patch04_legacy_calls, 45);
    assert_eq!(observed.context.discovery05_stone_rows.as_ref().unwrap().len(), 46);
    assert_eq!(observed.context.discovery05_stone_rows.as_ref().unwrap(), &observed.context.patch04_stone_observation.as_ref().unwrap().corrected_rows);
    assert_eq!(observed.context.metrics.get("discovery05.builds"), 1);
    assert_eq!(observed.context.metrics.get("discovery05.legacy.direct.read"), 1);
    assert_eq!(
        observed.context.branch_trace,
        vec![
            "PATCH02:NORMATIVE-WORK-COUNTS".to_owned(),
            "DISCOVERY03:LEGACY-TAG-DISTANCE".to_owned(),
            "PATCH03:CHRONOLOGICAL-DISTANCE-CORRECTION".to_owned(),
            "DISCOVERY04:LEGACY-SEQUENTIAL-STONES".to_owned(),
            "PATCH04:SNAPSHOT-STONE-CORRECTION".to_owned(),
            "DISCOVERY05:LEGACY-BACKWARD-HIDDEN-DIRECT-ACCESS".to_owned(),
        ]
    );

    let mut red = 0usize;
    let mut matched = 0usize;
    for k in 1..=7 {
        assert_eq!(observed.backward_storage[8 - k], expected[k]);
        let actual = calendar_hidden_by_nearness(&observed.backward_storage, k).unwrap();
        let class = if actual == expected[k] {
            matched += 1;
            "MATCH"
        } else {
            red += 1;
            "RED"
        };
        println!(
            "STAGE10_HIDDEN_CELL case=0 k={} actual={} expected={} class={}",
            k, actual, expected[k], class
        );
    }
    for slot in 0..8 {
        println!(
            "STAGE10_STORAGE_SLOT case=0 slot={} value={}",
            slot, observed.backward_storage[slot]
        );
    }
    assert_eq!((red, matched), (6, 1));
    assert_eq!(expected[1].to_string(), "119390830530032782664128530203002080344");
    assert_eq!(expected[2].to_string(), "11877236279154673426874867061566696749");
    assert_eq!(expected[3].to_string(), "24217814924229232987463457533828175476");
    assert_eq!(expected[4].to_string(), "166629231917547214614573522551290204247");
    assert_eq!(expected[5].to_string(), "81202913407267092008896220686064041568");
    assert_eq!(expected[6].to_string(), "73551520026920072430116213847585486272");
    assert_eq!(expected[7].to_string(), "6164285870955721082771365327359496898");

    let kotlin_subset = [1usize, 2, 4, 6, 7];
    let kotlin_red = kotlin_subset.iter().filter(|k| observed.backward_storage[**k] != expected[**k]).count();
    let kotlin_match = kotlin_subset.len() - kotlin_red;
    assert_eq!((kotlin_red, kotlin_match), (4, 1));
    let v_subset = [1usize, 2, 3, 4, 7];
    let v_red = v_subset.iter().filter(|k| observed.backward_storage[**k] != expected[**k]).count();
    let v_match = v_subset.len() - v_red;
    assert_eq!((v_red, v_match), (4, 1));

    let patch = observed.context.patch04_stone_observation.as_ref().unwrap();
    for row in 0..46 {
        for col in 0..5 {
            assert_eq!(patch.corrected_rows[row][col], stones[row][col]);
        }
    }

    let mut duplicate = observed.context.clone();
    let before_duplicate = duplicate.clone();
    let duplicate_error = LegacyHiddenDropDiscovery05 { requested_k: 1 }
        .handle(&mut duplicate)
        .unwrap_err();
    assert_eq!(duplicate_error.code, MonsterErrorCode::InvalidState);
    assert_eq!(duplicate, before_duplicate);

    let mut missing = MonsterContext::new(foundation.clone(), foundation.clone());
    let before_missing = missing.clone();
    let missing_error = LegacyHiddenDropDiscovery05 { requested_k: 1 }
        .handle(&mut missing)
        .unwrap_err();
    assert_eq!(missing_error.code, MonsterErrorCode::InvalidState);
    assert_eq!(missing, before_missing);

    for invalid in [0usize, 8usize] {
        assert_eq!(
            observe_legacy_hidden_drop(foundation.clone(), foundation.clone(), invalid)
                .unwrap_err()
                .code,
            MonsterErrorCode::InvalidState
        );
    }
    let short_storage = vec![BigInt::from(0u8); 7];
    assert_eq!(
        calendar_hidden_by_nearness(&short_storage, 1).unwrap_err().code,
        MonsterErrorCode::InvalidState
    );
    assert_eq!(
        calendar_hidden_by_nearness(&observed.backward_storage, 0)
            .unwrap_err()
            .code,
        MonsterErrorCode::InvalidState
    );

    let mut detached = observed.backward_storage.clone();
    let original_slot = observed.backward_storage[1].clone();
    detached[1] = BigInt::from(0u8);
    assert_eq!(observed.context.discovery05_backward_storage.as_ref().unwrap()[1], original_slot);
    let second = calendar_hidden_spaghetti(foundation.clone(), foundation.clone()).unwrap();
    assert_eq!(second.backward_storage, observed.backward_storage);
    assert_ne!(
        second.context.discovery05_backward_storage.as_ref().unwrap().as_ptr(),
        observed.context.discovery05_backward_storage.as_ref().unwrap().as_ptr()
    );

    assert_eq!(
        calendar_date_spaghetti(foundation.clone(), foundation)
            .unwrap_err()
            .code,
        MonsterErrorCode::BootstrapOnly
    );

    println!("STAGE10_BACKWARD_STORAGE_PASS_7");
    println!("STAGE10_PATCH04_ROWS_GREEN_230");
    println!("STAGE10_PRODUCTION_WRONG_K1_PASS");
    println!("STAGE10_EXPECTED_RED_6_MATCH_1");
    println!("STAGE10_KOTLIN_SUBSET_RED_4_MATCH_1");
    println!("STAGE10_V_SUBSET_RED_4_MATCH_1");
    println!("STAGE10_CONTEXT_GUARDS_REPLAY_PASS");
    println!("STAGE10_EARLIER_ROUTES_PASS");
    println!("STAGE10_COMPLETE_EXPECTED_RED");
}
