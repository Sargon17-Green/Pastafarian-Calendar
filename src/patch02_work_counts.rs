//! Mərhələ 5 — PATCH02: iki gün üçün normativ iş sayları.
//! Tarixi Stage04 zonduna və test oracle-ına istinad etmir.
//! Beş sahəli yekun təqvim marşrutu hələ qəsdən bağlıdır.

use std::cmp::Ordering;

use num_bigint::BigInt;
use num_traits::{One, Signed};

use crate::{MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, PhaseHandler};

/// İki günü ayıran normativ göstəricilər, tam və işarəli BigInt ilə.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct WorkCounts {
    pub action: BigInt,
    pub target: BigInt,
    pub distance: BigInt,
    pub connection: BigInt,
    pub direction: u8,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Patch02Observation {
    pub calculation_day: BigInt,
    pub target_day: BigInt,
    pub counts: WorkCounts,
    pub context: MonsterContext,
}

pub struct WorkCountsPatch02;

/// F=-15055671. F-dən əvvəl cüt, F və sonra tək müsbət göstərici.
pub fn normative_day_tag(day: &BigInt) -> BigInt {
    let foundation = BigInt::from(-15_055_671i64);
    match day.cmp(&foundation) {
        Ordering::Less => (&foundation - day) << 1usize,
        Ordering::Equal | Ordering::Greater => ((day - &foundation) << 1usize) + BigInt::one(),
    }
}

/// Məsafəyə hər iki sərhəd daxildir; eyni günün məsafəsi 1-dir.
/// İstiqamət: əvvəl=1, eyni=2, sonra=3.
pub fn normative_work_counts(calculation_day: &BigInt, target_day: &BigInt) -> WorkCounts {
    let action = normative_day_tag(calculation_day);
    let target = normative_day_tag(target_day);
    let distance = (target_day - calculation_day).abs() + BigInt::one();
    let connection = &action + &target;
    let direction = match target_day.cmp(calculation_day) {
        Ordering::Less => 1,
        Ordering::Equal => 2,
        Ordering::Greater => 3,
    };
    WorkCounts {
        action,
        target,
        distance,
        connection,
        direction,
    }
}

impl PhaseHandler for WorkCountsPatch02 {
    fn name(&self) -> &'static str {
        "PATCH02:NORMATIVE-WORK-COUNTS"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        context.work_counts_observation = Some(normative_work_counts(
            &context.calculation_day,
            &context.target_day,
        ));
        context.metrics.bump("patch02.work_counts.calls");
        context
            .logs
            .push("PATCH02: normativ iki-gün iş sayları hesablandı.");
        Ok(())
    }
}

/// Müstəqil çağırış konteksti ilə istehsal dispetçeri; oracle istifadə olunmur.
pub fn calculate_work_counts(
    calculation_day: BigInt,
    target_day: BigInt,
) -> Result<Patch02Observation, MonsterError> {
    let mut manager = MonsterManager::default();
    manager.dispatcher_mut().register(WorkCountsPatch02);
    let context = manager.execute_bootstrap_shell(calculation_day.clone(), target_day.clone())?;
    let counts = context
        .work_counts_observation
        .clone()
        .ok_or_else(|| MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "PATCH02: iş sayları müşahidəsi yoxdur.".to_owned(),
        })?;
    Ok(Patch02Observation {
        calculation_day,
        target_day,
        counts,
        context,
    })
}
