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

pub fn (_ BaseValidationManager) require_discrete_integer(_ BigInt) ! {
	return
}

pub fn (_ BaseValidationManager) require_catalog_shape(catalog []CanonicalName) ! {
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

pub fn (_ BaseErrorWrapper) wrap(message string, phase string) string {
	return '${phase}: ${message}'
}

pub struct BaseMetricsManager {}

pub fn (_ BaseMetricsManager) bump(mut context MonsterContext, key string) {
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
		errors:     BaseErrorWrapper{}
		metrics:    BaseMetricsManager{}
	}
}

pub fn new_monster_context(calculation_day BigInt, target_day BigInt) MonsterContext {
	return MonsterContext{
		calculation_day:     calculation_day
		target_day:          target_day
		phase:               'BOOTSTRAP'
		sub_phase:           0
		mode:                'BASE_ONLY'
		status:              'NEW'
		current_handler:     'BaseDispatcher'
		previous_handler:    ''
		branch_trace:        []string{}
		metrics:             map[string]u64{}
		logs:                []string{}
		diagnostics:         []string{}
		warnings:            []string{}
		last_error:          ''
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
	// ደረጃ 3፦ የታሪካዊውን adapter ተከትሎ PATCH 01 ይጠራል።
	patched_probe := calendar_save_spaghetti(calculation_day)
	patched_day_tag := calendar_day_tag_spaghetti(target_day)
	dispatcher := new_base_dispatcher()
	legacy_distance := dispatcher.dispatch_legacy_distance(calculation_day, target_day)
	patched_distance := calendar_distance_spaghetti(calculation_day, target_day)
	message := 'ዋናው የስፓጌቲ ቀን መንገድ ገና አልተገነባም፤ PATCH_01 SAVE='
	prefix := message + patched_probe.str() + '; PATCH_02 dayTag='
	details := prefix + patched_day_tag.str() + '; DISCOVERY_03 oldDistance='
	full := details + legacy_distance.str() + '; PATCH_03 distance='
	legacy_stone := dispatcher.dispatch_legacy_stones(2, initial_stones())
	patched_stone := calendar_stones_spaghetti(2, initial_stones())
	before_stones := full + patched_distance.str() + '; DISCOVERY_04 oldStoneB='
	stone_details := before_stones + legacy_stone.b.str() + '; PATCH_04 stoneB='
	hidden := calendar_hidden_spaghetti(calculation_day, target_day)
	hidden_details := stone_details + patched_stone.b.str() + '; DISCOVERY_05 oldHidden1='
	legacy_hidden_one := old_hidden_slot(hidden, 1)
	patched_hidden_one := calendar_hidden_by_nearness(hidden, 1)
	final_details := hidden_details + legacy_hidden_one.str() + '; PATCH_05 hidden1='
	visible := new_legacy_visible_drop_store()
	mut prior_diagnostic := 'AVAILABLE'
	_ = dispatcher.dispatch_legacy_prior(visible, 1, 1) or {
		prior_diagnostic = 'ERROR'
		big_zero()
	}
	patched_prior := calendar_prior_spaghetti(visible, hidden, 1, 1)!
	prior_details := final_details + patched_hidden_one.str() + '; DISCOVERY_06 oldPriorSlot0='
	patch_details := prior_details + prior_diagnostic + '; PATCH_06 priorSlot0='
	return error(patch_details + patched_prior.str())
}
