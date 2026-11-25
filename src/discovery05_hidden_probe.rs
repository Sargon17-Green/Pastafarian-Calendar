//! Stage10 / DISCOVERY05: preserve the historical reversed physical storage
//! and expose the direct-index read bug. PATCH05 is intentionally absent.

use num_bigint::BigInt;

use crate::discovery03_stone_probe::Stone;
use crate::discovery04_stone_probe::LegacyStoneDiscovery04;
use crate::patch01_save::normative_save;
use crate::patch02_work_counts::{LegacyTagDistanceDiscovery03, WorkCountsPatch02};
use crate::patch03_distance::Patch03DistanceCorrection;
use crate::patch04_stone_probe::StonePatch04;
use crate::{MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, PhaseHandler};

const HIDDEN_COUNT: usize = 7;
const STONE_COMPONENTS: usize = 5;
const PHYSICAL_STORAGE_LEN: usize = 8;
const GRIND_STONE_KINDS: [usize; 7] = [0, 1, 2, 3, 4, 0, 1];

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct HiddenWorkCounts {
    pub action: BigInt,
    pub target: BigInt,
    pub distance: BigInt,
    pub connection: BigInt,
    pub direction: u8,
}

/// Historical table is physically ordered hidden7, hidden6, ..., hidden1.
pub fn legacy_hidden_coefficients_reversed() -> [[u8; 4]; HIDDEN_COUNT] {
    [
        [15, 22, 30, 32],
        [13, 19, 26, 28],
        [11, 16, 22, 24],
        [9, 13, 18, 20],
        [7, 10, 14, 16],
        [5, 7, 10, 12],
        [3, 4, 6, 8],
    ]
}

pub fn hidden_coefficients_for_k(k: usize) -> Result<[u8; 4], MonsterError> {
    if !(1..=HIDDEN_COUNT).contains(&k) {
        return Err(MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY05: logical hidden index must be in 1..=7".to_owned(),
        });
    }
    Ok(legacy_hidden_coefficients_reversed()[HIDDEN_COUNT - k])
}

/// Computes logical hidden k using corrected PATCH02/03 counts and the
/// corrected PATCH04 stone row. No test oracle is used in production.
pub fn make_hidden_drop(
    k: usize,
    counts: &HiddenWorkCounts,
    stones: &[Stone],
) -> Result<BigInt, MonsterError> {
    let coefficients = hidden_coefficients_for_k(k)?;
    if stones.len() != 46 {
        return Err(MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY05: PATCH04 stone table must contain 46 rows".to_owned(),
        });
    }

    let row = &stones[k - 1];
    let mut value = counts.action.clone();
    value += &counts.target * BigInt::from(coefficients[0]);
    value += &counts.distance * BigInt::from(coefficients[1]);
    value += &counts.connection * BigInt::from(coefficients[2]);
    value += BigInt::from(counts.direction) * BigInt::from(coefficients[3]);
    for component in row {
        value += component;
    }
    value = normative_save(&value);

    for (offset, kind) in GRIND_STONE_KINDS.iter().enumerate() {
        let old = value.clone();
        let mut raw = &old * &old + BigInt::from(3u8) * &old;
        raw += &row[*kind];
        raw += BigInt::from(offset + 1);
        value = normative_save(&raw);
    }
    Ok(value)
}

/// Builds [sentinel, hidden7, hidden6, hidden5, hidden4, hidden3, hidden2, hidden1].
pub fn build_backward_storage(
    counts: &HiddenWorkCounts,
    stones: &[Stone],
) -> Result<Vec<BigInt>, MonsterError> {
    if stones.len() != 46 {
        return Err(MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY05: PATCH04 stone table must contain 46 rows".to_owned(),
        });
    }
    let mut backward = vec![BigInt::from(0u8); PHYSICAL_STORAGE_LEN];
    for k in 1..=HIDDEN_COUNT {
        backward[PHYSICAL_STORAGE_LEN - k] = make_hidden_drop(k, counts, stones)?;
    }
    Ok(backward)
}

/// Historical defect: logical k is used as a physical index without translation.
pub fn legacy_hidden_direct_by_assumed_nearness(
    backward: &[BigInt],
    k: usize,
) -> Result<BigInt, MonsterError> {
    if !(1..=HIDDEN_COUNT).contains(&k) {
        return Err(MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY05: logical hidden index must be in 1..=7".to_owned(),
        });
    }
    if backward.len() != PHYSICAL_STORAGE_LEN {
        return Err(MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY05: backward storage must contain sentinel plus seven drops"
                .to_owned(),
        });
    }
    Ok(backward[k].clone())
}

/// Production accessor intentionally retains the Stage10 wrong direct read.
pub fn calendar_hidden_by_nearness(
    backward: &[BigInt],
    k: usize,
) -> Result<BigInt, MonsterError> {
    legacy_hidden_direct_by_assumed_nearness(backward, k)
}

pub struct LegacyHiddenDropDiscovery05 {
    pub requested_k: usize,
}

impl PhaseHandler for LegacyHiddenDropDiscovery05 {
    fn name(&self) -> &'static str {
        "DISCOVERY05:LEGACY-BACKWARD-HIDDEN-DIRECT-ACCESS"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        if context.discovery05_backward_storage.is_some()
            || context.metrics.get("discovery05.builds") != 0
            || context.metrics.get("discovery05.legacy.direct.read") != 0
        {
            return Err(MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "DISCOVERY05 duplicate invocation".to_owned(),
            });
        }
        if !(1..=HIDDEN_COUNT).contains(&self.requested_k) {
            return Err(MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "DISCOVERY05 invalid requested hidden index".to_owned(),
            });
        }

        let work = context.work_counts_observation.as_ref().ok_or_else(|| MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY05 requires PATCH02 work counts".to_owned(),
        })?;
        let distance = context
            .patch03_distance_observation
            .as_ref()
            .map(|observation| observation.distance.clone())
            .ok_or_else(|| MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "DISCOVERY05 requires corrected PATCH03 distance".to_owned(),
            })?;
        let patch = context.patch04_stone_observation.as_ref().ok_or_else(|| MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY05 requires PATCH04 corrected stones".to_owned(),
        })?;
        let legacy = context.discovery04_stone_observation.as_ref().ok_or_else(|| MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY05 requires the preserved DISCOVERY04 observation".to_owned(),
        })?;

        if context.metrics.get("patch02.work_counts.calls") != 1
            || context.metrics.get("patch02.legacy.action.calls") != 1
            || context.metrics.get("patch02.legacy.target.calls") != 1
            || context.metrics.get("discovery03.distance.calls") != 1
            || context.metrics.get("patch03.distance.calls") != 1
            || context.metrics.get("discovery04.stones.calls") != 1
            || context.metrics.get("patch04.applied") != 1
            || context.metrics.get("patch04.legacy.calls") != 45
            || work.connection != &work.action + &work.target
            || !(1..=3).contains(&work.direction)
            || patch.row_count != 46
            || patch.component_count != 230
            || patch.legacy_calls != 45
            || patch.corrected_rows.len() != 46
            || patch.legacy_garbage_rows.len() != 46
            || legacy.row_count != 46
            || legacy.component_count != 230
            || legacy.rows.len() != 46
        {
            return Err(MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "DISCOVERY05 prerequisites or Stage08/09 table shape mismatch".to_owned(),
            });
        }

        let counts = HiddenWorkCounts {
            action: work.action.clone(),
            target: work.target.clone(),
            distance,
            connection: work.connection.clone(),
            direction: work.direction,
        };
        let backward = build_backward_storage(&counts, &patch.corrected_rows)?;
        let actual = legacy_hidden_direct_by_assumed_nearness(&backward, self.requested_k)?;
        let corrected_stone_rows = patch.corrected_rows.clone();
        let legacy_calls = patch.legacy_calls;

        // Commit the complete observation atomically only after every operation succeeds.
        context.discovery05_stone_rows = Some(corrected_stone_rows);
        context.discovery05_patch04_legacy_calls = legacy_calls;
        context.discovery05_backward_storage = Some(backward);
        context.discovery05_hidden_count = HIDDEN_COUNT;
        context.discovery05_requested_k = Some(self.requested_k);
        context.discovery05_actual = Some(actual);
        context.logs.push(format!(
            "DISCOVERY05: hidden_count=7 requested_k={} actual={} physical_order=7..1",
            self.requested_k,
            context.discovery05_actual.as_ref().expect("just committed")
        ));
        context.diagnostics.push("DISCOVERY05_BACKWARD_HIDDEN_DIRECT_ACCESS".to_owned());
        context.metrics.bump("discovery05.builds");
        context.metrics.bump("discovery05.legacy.direct.read");
        Ok(())
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Discovery05Observation {
    pub backward_storage: Vec<BigInt>,
    pub requested_k: usize,
    pub actual: BigInt,
    pub context: MonsterContext,
}

/// Execute the actual production route through Stage10. The default query is logical hidden1.
pub fn calendar_hidden_spaghetti(
    calculation_day: BigInt,
    target_day: BigInt,
) -> Result<Discovery05Observation, MonsterError> {
    observe_legacy_hidden_drop(calculation_day, target_day, 1)
}

pub fn observe_legacy_hidden_drop(
    calculation_day: BigInt,
    target_day: BigInt,
    requested_k: usize,
) -> Result<Discovery05Observation, MonsterError> {
    if !(1..=HIDDEN_COUNT).contains(&requested_k) {
        return Err(MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY05: requested hidden index must be in 1..=7".to_owned(),
        });
    }
    let mut manager = MonsterManager::default();
    manager.dispatcher_mut().register(WorkCountsPatch02);
    manager
        .dispatcher_mut()
        .register(LegacyTagDistanceDiscovery03);
    manager.dispatcher_mut().register(Patch03DistanceCorrection);
    manager.dispatcher_mut().register(LegacyStoneDiscovery04);
    manager.dispatcher_mut().register(StonePatch04);
    manager
        .dispatcher_mut()
        .register(LegacyHiddenDropDiscovery05 { requested_k });
    let context = manager.execute_bootstrap_shell(calculation_day, target_day)?;
    let backward_storage = context
        .discovery05_backward_storage
        .clone()
        .ok_or_else(|| MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY05 backward storage is missing".to_owned(),
        })?;
    let actual = context
        .discovery05_actual
        .clone()
        .ok_or_else(|| MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY05 direct-read result is missing".to_owned(),
        })?;
    Ok(Discovery05Observation {
        backward_storage,
        requested_k,
        actual,
        context,
    })
}
