mod support;

use num_bigint::{BigInt, BigUint};
use num_traits::One;
use pastafarian_calendar_rust_az::source_language_catalog::{
    cutlet_name, month_name, CUTLET_NAMES, MONTH_NAMES,
};
use pastafarian_calendar_rust_az::{
    MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, MonsterPhase, MonsterStatus,
    PhaseHandler,
};
use std::collections::BTreeSet;
use support::normative_oracle as oracle;

#[test]
fn embedded_constants_are_exact() {
    oracle::validate_embedded_constants();
}

#[test]
fn save_fixtures_match_reference() {
    let m = oracle::m_bigint();
    let cases = [
        (BigInt::one(), BigInt::one()),
        (&m - BigInt::one(), &m - BigInt::one()),
        (m.clone(), m.clone()),
        (&m + BigInt::one(), BigInt::one()),
        (&m * BigInt::from(2u8), m.clone()),
    ];
    for (input, expected) in cases {
        assert_eq!(oracle::save(input), expected);
    }
}

#[test]
fn day_count_fixtures_match_reference() {
    let f = oracle::foundation_day();
    let cases = [
        (f.clone(), BigInt::from(1u8)),
        (&f + BigInt::one(), BigInt::from(3u8)),
        (&f - BigInt::one(), BigInt::from(2u8)),
        (&f + BigInt::from(2u8), BigInt::from(5u8)),
        (&f - BigInt::from(2u8), BigInt::from(4u8)),
    ];
    for (day, expected) in cases {
        assert_eq!(oracle::day_count(&day), expected);
    }
}

#[test]
fn work_count_direction_and_distance_fixtures_match_reference() {
    let f = oracle::foundation_day();
    let same = oracle::work_counts(&f, &f);
    assert_eq!(same.distance, BigInt::one());
    assert_eq!(same.direction, 2);
    let forward = oracle::work_counts(&f, &(&f + BigInt::from(7u8)));
    assert_eq!(forward.distance, BigInt::from(8u8));
    assert_eq!(forward.direction, 3);
    let backward = oracle::work_counts(&f, &(&f - BigInt::from(7u8)));
    assert_eq!(backward.distance, BigInt::from(8u8));
    assert_eq!(backward.direction, 1);
}

#[test]
fn stone_snapshot_fixture_matches_reference() {
    let stones = oracle::build_stones();
    assert_eq!(stones.len(), 46);
    assert_eq!(
        stones[1],
        [378u64, 1073, 2375, 6195, 10493].map(BigInt::from)
    );
}

#[test]
fn permutation_edge_fixtures_match_reference() {
    assert_eq!(oracle::bowl_order_from_number(1), [1, 2, 3, 4, 5, 6]);
    assert_eq!(oracle::bowl_order_from_number(720), [6, 5, 4, 3, 2, 1]);
    assert_eq!(
        oracle::bowl_order_from_drop(&BigInt::from(720u16)),
        [6, 5, 4, 3, 2, 1]
    );
}

#[test]
fn bounded_composition_count_and_unrank_are_lexicographic() {
    let mut family = oracle::BoundedCompositionCounter::new(7, 2, 1, 6);
    assert_eq!(family.count_all(), BigUint::from(6u8));
    assert_eq!(family.unrank1(&BigUint::from(1u8)), vec![1, 6]);
    assert_eq!(family.unrank1(&BigUint::from(6u8)), vec![6, 1]);
}

#[test]
fn cutlet_boundary_filter_count_and_unrank_are_exact() {
    let mut family = oracle::CutletPartitionCounter::new(6, 3, Some(2));
    let total = family.count_all();
    let mut rows = Vec::new();
    let mut a = 1usize;
    while a <= 4 {
        let mut b = 1usize;
        while a + b <= 5 {
            let c = 6 - a - b;
            if c >= 1 {
                let prefix1 = a;
                let prefix2 = a + b;
                if prefix1 == 2 || prefix2 == 2 {
                    rows.push(vec![a, b, c]);
                }
            }
            b += 1;
        }
        a += 1;
    }
    assert_eq!(total, BigUint::from(rows.len()));
    for (idx, expected) in rows.iter().enumerate() {
        assert_eq!(family.unrank1(&BigUint::from(idx + 1)), expected.clone());
    }
}

#[test]
fn distinct_name_unrank_never_repeats_indices() {
    let total = oracle::falling_factorial(17, 6);
    let ranks = [BigUint::one(), &total / BigUint::from(2u8), total.clone()];
    for rank in ranks {
        let rank = if rank == BigUint::from(0u8) {
            BigUint::one()
        } else {
            rank
        };
        let row = oracle::unrank_distinct_indices(17, 6, &rank);
        let unique: BTreeSet<u8> = row.iter().copied().collect();
        assert_eq!(row.len(), 6);
        assert_eq!(unique.len(), 6);
    }
}

#[test]
fn small_weaving_family_matches_explicit_lexicographic_rows() {
    let mut family = oracle::WeavingCounter::new(&[2, 2]);
    assert_eq!(family.count_all(), BigUint::from(2u8));
    assert_eq!(family.unrank1(&BigUint::from(1u8)), vec![1, 1, 2, 2]);
    assert_eq!(family.unrank1(&BigUint::from(2u8)), vec![1, 2, 1, 2]);
}

#[test]
fn source_language_catalog_is_frozen_index_order() {
    assert_eq!(CATALOG_VERSION, "az-1");
    assert_eq!(CUTLET_NAMES.len(), 17);
    assert_eq!(MONTH_NAMES.len(), 47);
    for (offset, item) in CUTLET_NAMES.iter().enumerate() {
        assert_eq!(usize::from(item.canonical_index), offset + 1);
        assert_eq!(cutlet_name(item.canonical_index), Some(item.source_text));
    }
    for (offset, item) in MONTH_NAMES.iter().enumerate() {
        assert_eq!(usize::from(item.canonical_index), offset + 1);
        assert_eq!(month_name(item.canonical_index), Some(item.source_text));
    }
    let cutlet_unique: BTreeSet<&str> = CUTLET_NAMES.iter().map(|x| x.source_text).collect();
    let month_unique: BTreeSet<&str> = MONTH_NAMES.iter().map(|x| x.source_text).collect();
    assert_eq!(cutlet_unique.len(), 17);
    assert_eq!(month_unique.len(), 47);
}

#[test]
fn source_language_catalog_exact_strings_are_frozen() {
    let expected_cutlets = [
        "bürünc",
        "tülkü",
        "böyrək",
        "Laqaş",
        "düşüncə",
        "doqquzun dörd hissəsi",
        "Palguraş",
        "papirus",
        "salxım",
        "əqrəb",
        "kül",
        "buğda",
        "çay",
        "gülüş",
        "Akkad",
        "buynuz",
        "boş küp",
    ];
    let expected_months = [
        "gil",
        "nar",
        "dirsək",
        "qısqanclıq",
        "Eridu",
        "diş məcunu",
        "beşin üç hissəsi",
        "Karşumab",
        "pələng",
        "qalay",
        "duman",
        "kündür",
        "iy",
        "qabırğa",
        "keçibuynuzu",
        "Uruk",
        "utanc",
        "dəvə",
        "mis",
        "quyu",
        "yumurta sarısı",
        "ulduz",
        "bal",
        "dalaq",
        "əhəngdaşı",
        "sevinc",
        "əncir",
        "Ninova",
        "qurbağa",
        "qatran",
        "şam",
        "bağlı qapı",
        "küncüt",
        "ənsə",
        "gümüş",
        "zanbaq",
        "fırtına",
        "eşşək",
        "un",
        "peşmanlıq",
        "Babil",
        "dil",
        "kətan",
        "duz",
        "armud",
        "yay",
        "qum",
    ];
    let actual_cutlets: Vec<&str> = CUTLET_NAMES.iter().map(|entry| entry.source_text).collect();
    let actual_months: Vec<&str> = MONTH_NAMES.iter().map(|entry| entry.source_text).collect();
    assert_eq!(actual_cutlets.as_slice(), expected_cutlets.as_slice());
    assert_eq!(actual_months.as_slice(), expected_months.as_slice());
}

#[test]
fn sauce_is_deterministic_for_bootstrap_fixture() {
    let f = oracle::foundation_day();
    let first = oracle::sauce(&f, &f);
    let second = oracle::sauce(&f, &f);
    assert_eq!(first, second);
    assert_eq!(first.order_at_drop_46.len(), 6);
}

#[test]
fn base_monster_shell_is_semantically_neutral() {
    let manager = MonsterManager::default();
    let context = manager
        .execute_bootstrap_shell(BigInt::from(oracle::FOUNDATION_DAY_I64), BigInt::from(oracle::FOUNDATION_DAY_I64))
        .expect("İlkin quruluş qabığı uğurla işləməlidir.");
    assert_eq!(context.phase, MonsterPhase::Complete);
    assert_eq!(context.status, MonsterStatus::Complete);
    assert_eq!(context.metrics.get("bootstrap.calls"), 1);
    assert_eq!(context.metrics.get("bootstrap.success"), 1);
}

struct FailingBootstrapHandler;

impl PhaseHandler for FailingBootstrapHandler {
    fn name(&self) -> &'static str {
        "QəsdənUğursuzİlkinİşləyici"
    }

    fn handle(&self, _context: &mut MonsterContext) -> Result<(), MonsterError> {
        Err(MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "Sınaq üçün qəsdən yaradılmış ilkin xəta.".to_owned(),
        })
    }
}

#[test]
fn base_error_boundary_wraps_without_changing_machine_code() {
    let mut manager = MonsterManager::default();
    manager.dispatcher_mut().register(FailingBootstrapHandler);
    let error = manager
        .execute_bootstrap_shell(BigInt::from(1u8), BigInt::from(1u8))
        .expect_err("Qəsdən uğursuz işləyici səhv qaytarmalıdır.");
    assert_eq!(error.code, MonsterErrorCode::InvalidState);
    assert!(error.message.contains("İlkin səhv sərhədi (dispatcher)"));
}

#[test]
fn future_patch_scar_names_are_absent_from_production_stage01() {
    let production = concat!(
        include_str!("../src/lib.rs"),
        include_str!("../src/source_language_catalog.rs")
    );
    let forbidden = [
        "oldRemainder",
        "oldDayTag",
        "oldDistance",
        "mutateStonesWrong",
        "orderAt46Latch",
        "biasedLegacyPick",
        "LEGACY_YEAR_MAX",
        "oldJumpGuess",
        "VirtualLegacyList",
        "oldContiguousMonthDayGuess",
    ];
    for name in forbidden {
        assert!(!production.contains(name), "Gələcək mərhələ izi tapıldı: {name}");
    }
}
