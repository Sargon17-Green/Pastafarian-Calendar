module pastafari

pub struct CalendarResult {
pub:
	year_number   BigInt
	cutlet_name   string
	day_in_cutlet BigInt
	month_name    string
	day_in_month  BigInt
}

pub struct MonsterContext {
pub:
	calculation_day BigInt
	target_day      BigInt
mut:
	phase               string
	sub_phase           int
	mode                string
	status              string
	current_handler     string
	previous_handler    string
	branch_trace        []string
	metrics             map[string]u64
	logs                []string
	diagnostics         []string
	warnings            []string
	last_error          string
	validation_failures []string
}

pub struct BaseValidationManager {}

pub fn (BaseValidationManager) require_discrete_integer(_ BigInt) ! {
	return
}

pub fn (BaseValidationManager) require_catalog_shape(catalog []CanonicalName) ! {
	mut cutlets := 0
	mut months := 0
	for item in catalog {
		match item.kind {
			.cutlet { cutlets++ }
			.month { months++ }
		}
	}
	if cutlets != 17 || months != 47 {
		return error('የምንጭ ቋንቋ ካታሎጉ 17 ቆራጮችንና 47 ወራትን መያዝ አለበት')
	}
}

pub struct BaseErrorWrapper {}

pub fn (BaseErrorWrapper) wrap(message string, phase string) string {
	return '${phase}: ${message}'
}

pub struct BaseMetricsManager {}

pub fn (BaseMetricsManager) bump(mut context MonsterContext, key string) {
	context.metrics[key] = context.metrics[key] + 1
}

pub struct BaseDispatcher {
pub:
	validation BaseValidationManager
	errors     BaseErrorWrapper
	metrics    BaseMetricsManager
}

pub fn new_base_dispatcher() BaseDispatcher {
	return BaseDispatcher{
		validation: BaseValidationManager{}
		errors: BaseErrorWrapper{}
		metrics: BaseMetricsManager{}
	}
}

pub fn new_monster_context(calculation_day BigInt, target_day BigInt) MonsterContext {
	return MonsterContext{
		calculation_day: calculation_day
		target_day: target_day
		phase: 'BOOTSTRAP'
		sub_phase: 0
		mode: 'BASE_ONLY'
		status: 'NEW'
		current_handler: 'BaseDispatcher'
		previous_handler: ''
		branch_trace: []string{}
		metrics: map[string]u64{}
		logs: []string{}
		diagnostics: []string{}
		warnings: []string{}
		last_error: ''
		validation_failures: []string{}
	}
}

pub fn bootstrap_validate(calculation_day BigInt, target_day BigInt) !MonsterContext {
	mut context := new_monster_context(calculation_day, target_day)
	dispatcher := new_base_dispatcher()
	dispatcher.validation.require_discrete_integer(calculation_day)!
	dispatcher.validation.require_discrete_integer(target_day)!
	dispatcher.validation.require_catalog_shape(source_language_catalog())!
	context.branch_trace << 'BOOTSTRAP_VALIDATED'
	context.status = 'READY_FOR_HISTORICAL_GROWTH'
	dispatcher.metrics.bump(mut context, 'bootstrap.validations')
	return context
}

pub fn calendar_date_spaghetti(calculation_day BigInt, target_day BigInt) !CalendarResult {
	_ = bootstrap_validate(calculation_day, target_day)!
	return error('ዋናው የስፓጌቲ መንገድ በታሪካዊ ደረጃዎቹ ገና አልተገነባም')
}
