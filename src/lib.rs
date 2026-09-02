use num_bigint::BigInt;
use std::collections::BTreeMap;

pub mod source_language_catalog;

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum MonsterPhase {
    Bootstrap,
    Dispatch,
    Validate,
    Complete,
    Failed,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum MonsterStatus {
    New,
    Running,
    Validated,
    Complete,
    Failed,
}

#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct MonsterMetrics {
    counters: BTreeMap<String, u64>,
}

impl MonsterMetrics {
    pub fn bump(&mut self, key: &str) {
        let value = self.counters.entry(key.to_owned()).or_insert(0);
        *value = value.saturating_add(1);
    }

    pub fn get(&self, key: &str) -> u64 {
        self.counters.get(key).copied().unwrap_or(0)
    }
}

#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct MonsterLog {
    entries: Vec<String>,
}

impl MonsterLog {
    pub fn push(&mut self, text: impl Into<String>) {
        self.entries.push(text.into());
    }

    pub fn entries(&self) -> &[String] {
        &self.entries
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct MonsterContext {
    pub calculation_day: BigInt,
    pub target_day: BigInt,
    pub phase: MonsterPhase,
    pub status: MonsterStatus,
    pub retry_budget: u8,
    pub recovery_depth: u8,
    pub current_handler: Option<String>,
    pub previous_handler: Option<String>,
    pub branch_trace: Vec<String>,
    pub metrics: MonsterMetrics,
    pub logs: MonsterLog,
    pub diagnostics: Vec<String>,
    pub warnings: Vec<String>,
    pub validation_failures: Vec<String>,
}

impl MonsterContext {
    pub fn new(calculation_day: BigInt, target_day: BigInt) -> Self {
        Self {
            calculation_day,
            target_day,
            phase: MonsterPhase::Bootstrap,
            status: MonsterStatus::New,
            retry_budget: 0,
            recovery_depth: 0,
            current_handler: None,
            previous_handler: None,
            branch_trace: Vec::new(),
            metrics: MonsterMetrics::default(),
            logs: MonsterLog::default(),
            diagnostics: Vec::new(),
            warnings: Vec::new(),
            validation_failures: Vec::new(),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum MonsterErrorCode {
    InvalidState,
    BootstrapOnly,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct MonsterError {
    pub code: MonsterErrorCode,
    pub message: String,
}

impl MonsterError {
    pub fn bootstrap_only() -> Self {
        Self {
            code: MonsterErrorCode::BootstrapOnly,
            message: "Normativ istehsal yolu 1-ci mərhələdə qəsdən aktiv deyil.".to_owned(),
        }
    }
}

#[derive(Default)]
pub struct MonsterErrorBoundary;

impl MonsterErrorBoundary {
    pub fn wrap(&self, boundary: &str, error: MonsterError) -> MonsterError {
        MonsterError {
            code: error.code,
            message: format!("İlkin səhv sərhədi ({boundary}): {}", error.message),
        }
    }
}

pub trait PhaseHandler {
    fn name(&self) -> &'static str;
    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError>;
}

#[derive(Default)]
pub struct MonsterDispatcher {
    handlers: Vec<Box<dyn PhaseHandler + Send + Sync>>,
}

impl MonsterDispatcher {
    pub fn register<H>(&mut self, handler: H)
    where
        H: PhaseHandler + Send + Sync + 'static,
    {
        self.handlers.push(Box::new(handler));
    }

    pub fn dispatch_all(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        context.phase = MonsterPhase::Dispatch;
        context.status = MonsterStatus::Running;
        for handler in &self.handlers {
            context.previous_handler = context.current_handler.take();
            context.current_handler = Some(handler.name().to_owned());
            context.branch_trace.push(handler.name().to_owned());
            handler.handle(context)?;
            context.metrics.bump("dispatcher.handler.completed");
        }
        Ok(())
    }
}

#[derive(Default)]
pub struct MonsterValidationManager;

impl MonsterValidationManager {
    pub fn validate_base_context(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        context.phase = MonsterPhase::Validate;
        if context.recovery_depth != 0 {
            let text = "Bootstrap kontekstində bərpa dərinliyi sıfır olmalıdır.".to_owned();
            context.validation_failures.push(text.clone());
            context.status = MonsterStatus::Failed;
            context.phase = MonsterPhase::Failed;
            return Err(MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: text,
            });
        }
        context.status = MonsterStatus::Validated;
        Ok(())
    }
}

#[derive(Default)]
pub struct MonsterManager {
    dispatcher: MonsterDispatcher,
    validator: MonsterValidationManager,
    error_boundary: MonsterErrorBoundary,
}

impl MonsterManager {
    pub fn dispatcher_mut(&mut self) -> &mut MonsterDispatcher {
        &mut self.dispatcher
    }

    pub fn execute_bootstrap_shell(
        &self,
        calculation_day: BigInt,
        target_day: BigInt,
    ) -> Result<MonsterContext, MonsterError> {
        let mut context = MonsterContext::new(calculation_day, target_day);
        context.logs.push("İlkin quruluş çağırışı başladı.");
        context.metrics.bump("bootstrap.calls");
        if let Err(error) = self.dispatcher.dispatch_all(&mut context) {
            return Err(self.error_boundary.wrap("dispatcher", error));
        }
        if let Err(error) = self.validator.validate_base_context(&mut context) {
            return Err(self.error_boundary.wrap("validator", error));
        }
        context.status = MonsterStatus::Complete;
        context.phase = MonsterPhase::Complete;
        context.logs.push("İlkin quruluş çağırışı tamamlandı.");
        context.metrics.bump("bootstrap.success");
        Ok(context)
    }
}

pub fn calendar_date_spaghetti(
    _calculation_day: BigInt,
    _target_day: BigInt,
) -> Result<[String; 5], MonsterError> {
    Err(MonsterError::bootstrap_only())
}
