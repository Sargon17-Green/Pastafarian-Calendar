use num_bigint::BigInt;
use num_traits::{One, Signed};

use pastafarian_calendar_rust_az::discovery03_stone_probe::Stone;
use pastafarian_calendar_rust_az::discovery04_stone_probe::{
    calendar_stones_spaghetti, mutate_stones_wrong, LegacyStoneDiscovery04,
};
use pastafarian_calendar_rust_az::{
    calendar_date_spaghetti, MonsterContext, MonsterErrorCode, PhaseHandler,
};

fn independent_save(raw: &BigInt) -> BigInt {
    let modulus = (BigInt::one() << 127usize) - BigInt::one();
    let mut remainder = (raw - BigInt::one()) % &modulus;
    if remainder.is_negative() {
        remainder += &modulus;
    }
    remainder + BigInt::one()
}

fn independent_snapshot_table() -> Vec<Stone> {
    let mut rows = Vec::with_capacity(46);
    rows.push([17, 29, 43, 71, 101].map(BigInt::from));
    for row_index in 2usize..=46 {
        let old = rows.last().expect("seed exists").clone();
        let i = BigInt::from(row_index);
        rows.push([
            independent_save(&(&old[0] * &old[0] + BigInt::from(3u8) * &old[1] + &i)),
            independent_save(&(&old[1] * &old[1] + BigInt::from(5u8) * &old[2] + &old[0])),
            independent_save(&(&old[2] * &old[2] + BigInt::from(7u8) * &old[3] + &old[1])),
            independent_save(&(&old[3] * &old[3] + BigInt::from(11u8) * &old[4] + &old[2])),
            independent_save(&(&old[4] * &old[4] + BigInt::from(13u8) * &old[0] + &old[3])),
        ]);
    }
    rows
}

#[test]
fn stage08_discovery04_keeps_sequential_bug_visible_as_expected_red() {
    let foundation = BigInt::from(-15_055_671i64);
    let calculation_day = &foundation - BigInt::one();
    let target_day = &foundation + BigInt::one();
    let observed = calendar_stones_spaghetti(calculation_day.clone(), target_day.clone())
        .expect("PATCH02 -> DISCOVERY03 -> PATCH03 -> DISCOVERY04");
    let expected = independent_snapshot_table();

    assert_eq!(observed.rows.len(), 46);
    assert_eq!(expected.len(), 46);
    assert_eq!(observed.rows[0], [17, 29, 43, 71, 101].map(BigInt::from));
    assert_eq!(observed.rows[1], [378, 1434, 3780, 9932, 25047].map(BigInt::from));
    assert_eq!(expected[1], [378, 1073, 2375, 6195, 10493].map(BigInt::from));

    let maximum = (BigInt::one() << 127usize) - BigInt::one();
    for value in observed.rows.iter().flatten().chain(expected.iter().flatten()) {
        assert!(value >= &BigInt::one() && value <= &maximum);
    }

    let fields = ["w", "b", "s", "m", "r"];
    let mut red = 0usize;
    let mut matches = 0usize;
    for row in 1..46 {
        for column in 0..5 {
            let legacy = &observed.rows[row][column];
            let snapshot = &expected[row][column];
            let class = if legacy == snapshot {
                matches += 1;
                "MATCH"
            } else {
                red += 1;
                "RED"
            };
            println!(
                "STAGE08_STONE_CELL row={} field={} legacy={} expected={} class={}",
                row + 1, fields[column], legacy, snapshot, class
            );
        }
    }
    assert_eq!(red, 224);
    assert_eq!(matches, 1);
    assert_eq!(observed.context.metrics.get("patch02.work_counts.calls"), 1);
    assert_eq!(observed.context.metrics.get("discovery03.distance.calls"), 1);
    assert_eq!(observed.context.metrics.get("patch03.distance.calls"), 1);
    assert_eq!(observed.context.metrics.get("discovery04.stones.calls"), 1);
    assert_eq!(observed.context.metrics.get("dispatcher.handler.completed"), 4);
    assert_eq!(
        observed.context.branch_trace,
        vec![
            "PATCH02:NORMATIVE-WORK-COUNTS".to_owned(),
            "DISCOVERY03:LEGACY-TAG-DISTANCE".to_owned(),
            "PATCH03:CHRONOLOGICAL-DISTANCE-CORRECTION".to_owned(),
            "DISCOVERY04:LEGACY-SEQUENTIAL-STONES".to_owned(),
        ]
    );
    let stored = observed.context.discovery04_stone_observation.as_ref().unwrap();
    assert_eq!(stored.row_count, 46);
    assert_eq!(stored.component_count, 230);
    assert_eq!(stored.rows, observed.rows);

    let repeated = calendar_stones_spaghetti(calculation_day.clone(), target_day.clone()).unwrap();
    assert_eq!(observed.rows, repeated.rows);
    let mut first_copy = observed.rows.clone();
    let second_copy = repeated.rows.clone();
    first_copy[0][0] += BigInt::one();
    assert_ne!(first_copy, second_copy);

    let mut guards = 0usize;
    let mut duplicate = observed.context.clone();
    let before_duplicate = duplicate.clone();
    let duplicate_error = LegacyStoneDiscovery04.handle(&mut duplicate).unwrap_err();
    assert_eq!(duplicate_error.code, MonsterErrorCode::InvalidState);
    assert_eq!(duplicate, before_duplicate);
    guards += 1;

    let mut missing_stage07 = MonsterContext::new(foundation.clone(), foundation.clone());
    let before_missing = missing_stage07.clone();
    let missing_error = LegacyStoneDiscovery04.handle(&mut missing_stage07).unwrap_err();
    assert_eq!(missing_error.code, MonsterErrorCode::InvalidState);
    assert_eq!(missing_stage07, before_missing);
    guards += 1;

    let seed: Stone = [17, 29, 43, 71, 101].map(BigInt::from);
    for invalid_index in [1usize, 47usize] {
        let mut row = seed.clone();
        let before = row.clone();
        let error = mutate_stones_wrong(invalid_index, &mut row).unwrap_err();
        assert_eq!(error.code, MonsterErrorCode::InvalidState);
        assert_eq!(row, before);
        guards += 1;
    }

    let bootstrap_error = calendar_date_spaghetti(foundation.clone(), foundation).unwrap_err();
    assert_eq!(bootstrap_error.code, MonsterErrorCode::BootstrapOnly);
    assert_eq!(guards, 4);

    println!("STAGE08_STONE_SEED=17,29,43,71,101");
    println!("STAGE08_DISCOVERY04_ROWS=46 CELLS=230");
    println!("STAGE08_DISCOVERY04_EXPECTED_RED=224 MATCH=1 UNEXPECTED=0 GUARDS=4");
    println!("STAGE08_DISCOVERY04_BOOTSTRAP_ONLY=PASS");
}
