package pastafari

data class BaseMonsterContext(
    val calculationDay: ExactInt,
    val targetDay: ExactInt,
    var phase: String = "BOOT",
    var status: String = "NEW",
    val branchTrace: MutableList<String> = mutableListOf(),
    val diagnostics: MutableList<String> = mutableListOf(),
    var discovery01Input: ExactInt? = null,
    var discovery01Output: ExactInt? = null,
    var patch01Input: ExactInt? = null,
    var patch01LegacyOutput: ExactInt? = null,
    var patch01Output: ExactInt? = null,
    var discovery02Input: ExactInt? = null,
    var discovery02Output: ExactInt? = null,
    var patch02Input: ExactInt? = null,
    var patch02LegacyOutput: ExactInt? = null,
    var patch02Output: ExactInt? = null,
    var discovery03CalculationDay: ExactInt? = null,
    var discovery03TargetDay: ExactInt? = null,
    var discovery03Output: ExactInt? = null
)

class MonsterValidationException(val machineCode: String) : RuntimeException(machineCode)

class BaseValidationManager {
    fun requireBootstrapContext(context: BaseMonsterContext) {
        if (context.phase.isEmpty()) throw MonsterValidationException("E_BOOT_PHASE")
        if (context.status.isEmpty()) throw MonsterValidationException("E_BOOT_STATUS")
    }
}

class BaseMetricsManager {
    private val counters = linkedMapOf<String, Long>()

    fun bump(key: String) {
        counters[key] = (counters[key] ?: 0L) + 1L
    }

    fun snapshot(): Map<String, Long> = counters.toMap()
}

class BaseErrorWrapper {
    fun wrap(code: String, cause: Throwable): MonsterValidationException {
        val suffix = cause::class.simpleName ?: "Throwable"
        return MonsterValidationException("${code}_${suffix}")
    }
}

fun interface BasePhaseHandler {
    fun handle(context: BaseMonsterContext)
}

class BaseMonsterDispatcher(
    private val handlers: MutableMap<String, BasePhaseHandler> = linkedMapOf()
) {
    fun register(phase: String, handler: BasePhaseHandler) {
        handlers[phase] = handler
    }

    fun dispatch(context: BaseMonsterContext) {
        val handler = handlers[context.phase] ?: throw MonsterValidationException("E_BOOT_HANDLER")
        handler.handle(context)
    }
}

class MonsterBootstrapManager(
    val dispatcher: BaseMonsterDispatcher = BaseMonsterDispatcher(),
    val validation: BaseValidationManager = BaseValidationManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    val errors: BaseErrorWrapper = BaseErrorWrapper(),
    val legacyRemainderAdapter: LegacyRemainderAdapter = LegacyRemainderAdapter(),
    val savePatchWrapper: SavePatchWrapper = SavePatchWrapper(),
    val legacyDayTagAdapter: LegacyDayTagAdapter = LegacyDayTagAdapter(),
    val dayTagPatchWrapper: DayTagPatchWrapper = DayTagPatchWrapper(),
    val legacyDistanceAdapter: LegacyDistanceAdapter = LegacyDistanceAdapter()
) {
    init {
        dispatcher.register("BOOT") { context ->
            validation.requireBootstrapContext(context)
            context.branchTrace.add("BOOT")
            context.status = "READY"
            metrics.bump("bootstrap.ready")
        }
        dispatcher.register("DISCOVERY_01") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_DISCOVERY01_CONTEXT_NOT_READY")
            val input = context.discovery01Input
                ?: throw MonsterValidationException("E_DISCOVERY01_NO_INPUT")
            // Galw'r graith go iawn; dim galwad at y cyfeirnod normadol.
            val legacy = legacyRemainderAdapter.oldRemainder(input)
            context.discovery01Output = legacy
            context.branchTrace.add("DISCOVERY_01")
            context.diagnostics.add("DISCOVERY_01_LEGACY_REMAINDER")
            context.status = "LEGACY_REMAINDER_OBSERVED"
            metrics.bump("discovery01.legacy")
        }
        dispatcher.register("DISCOVERY_02") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_DISCOVERY02_CONTEXT_NOT_READY")
            val input = context.discovery02Input
                ?: throw MonsterValidationException("E_DISCOVERY02_NO_INPUT")
            // Galw'r hen dag yn union; rhaid cadw'r anghysondeb yn weithredol.
            val legacy = legacyDayTagAdapter.oldDayTag(input)
            context.discovery02Output = legacy
            context.branchTrace.add("DISCOVERY_02")
            context.diagnostics.add("DISCOVERY_02_LEGACY_DAY_TAG")
            context.status = "LEGACY_DAY_TAG_OBSERVED"
            metrics.bump("discovery02.legacy")
        }
        dispatcher.register("DISCOVERY_03") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_DISCOVERY03_CONTEXT_NOT_READY")
            val calculation = context.discovery03CalculationDay
                ?: throw MonsterValidationException("E_DISCOVERY03_NO_CALCULATION_DAY")
            val target = context.discovery03TargetDay
                ?: throw MonsterValidationException("E_DISCOVERY03_NO_TARGET_DAY")
            if (calculation != context.calculationDay || target != context.targetDay) {
                throw MonsterValidationException("E_DISCOVERY03_CONTEXT_MISMATCH")
            }
            // Galw'r graith mewn cynhyrchu. Dim oracl, dim PATCH 03.
            val legacy = legacyDistanceAdapter.oldDistance(calculation, target)
            context.discovery03Output = legacy
            context.branchTrace.add("DISCOVERY_03")
            context.diagnostics.add("DISCOVERY_03_LEGACY_TAG_DISTANCE")
            context.status = "LEGACY_DISTANCE_OBSERVED"
            metrics.bump("discovery03.legacy")
        }
        dispatcher.register("PATCH_02") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_PATCH02_CONTEXT_NOT_READY")
            val input = context.patch02Input
                ?: throw MonsterValidationException("E_PATCH02_NO_INPUT")
            // Y graith gyntaf; ni ddylai'r patch alw'r oracl normadol.
            val legacy = legacyDayTagAdapter.oldDayTag(input)
            val patched = dayTagPatchWrapper.dayTagWithFoundationScar(input, legacy)
            // Ymrwymo atomig ar ôl i'r cyfrifiad cyfan lwyddo.
            context.patch02LegacyOutput = legacy
            context.patch02Output = patched
            context.branchTrace.add("PATCH_02")
            context.diagnostics.add("PATCH_02_FOUNDATION_SCAR_WRAPPER")
            context.status = "PATCHED_DAY_TAG"
            metrics.bump("patch02.legacy.calls")
            metrics.bump("patch02.applied")
        }
        dispatcher.register("PATCH_01") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_PATCH01_CONTEXT_NOT_READY")
            val input = context.patch01Input
                ?: throw MonsterValidationException("E_PATCH01_NO_INPUT")
            // Mae'r graith yn parhau'n fyw: galw'r hen addasydd yn gyntaf.
            val legacy = legacyRemainderAdapter.oldRemainder(input)
            val patched = savePatchWrapper.savePatch(legacy)
            // Ymrwymo'r canlyniadau gyda'i gilydd ar ôl cyfrifiad llwyddiannus.
            context.patch01LegacyOutput = legacy
            context.patch01Output = patched
            context.branchTrace.add("PATCH_01")
            context.diagnostics.add("PATCH_01_SAVE_WRAPPER")
            context.status = "PATCHED"
            metrics.bump("patch01.legacy.calls")
            metrics.bump("patch01.applied")
        }
    }

    fun prepare(calculationDay: ExactInt, targetDay: ExactInt): BaseMonsterContext {
        val context = BaseMonsterContext(calculationDay, targetDay)
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_BOOT_WRAP", e)
        }
    }

    /**
     * Llwybr cynhyrchu ar gyfer archwilio gwall Cam 2 yn unig.
     * Mae pob gwerth semantig yn perthyn i gyd-destun y galwad.
     */
    fun observeLegacyRemainder(
        calculationDay: ExactInt,
        targetDay: ExactInt,
        value: ExactInt
    ): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.discovery01Input = value
        context.phase = "DISCOVERY_01"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY01_WRAP", e)
        }
    }

    /** Llwybr cynhyrchu Cam 4, heb weithredu PATCH 02. */
    fun observeLegacyDayTag(
        calculationDay: ExactInt,
        targetDay: ExactInt,
        day: ExactInt
    ): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.discovery02Input = day
        context.phase = "DISCOVERY_02"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY02_WRAP", e)
        }
    }

    /** Cam 6: BOOT, yna pellter diffygiol o dagiau PATCH 02. */
    fun observeLegacyDistance(calculationDay: ExactInt, targetDay: ExactInt): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.discovery03CalculationDay = calculationDay
        context.discovery03TargetDay = targetDay
        context.phase = "DISCOVERY_03"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY03_WRAP", e)
        }
    }

    /** PATCH 02: BOOT, oldDayTag unwaith, yna'r amod Sylfaen. */
    fun applyDayTagPatch(
        calculationDay: ExactInt,
        targetDay: ExactInt,
        day: ExactInt
    ): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.patch02Input = day
        context.phase = "PATCH_02"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH02_WRAP", e)
        }
    }

    /** Galwad cynhyrchu Patch 01: BOOT, y graith, yna'r deunydd lapio SAVE. */
    fun applySavePatch(
        calculationDay: ExactInt,
        targetDay: ExactInt,
        value: ExactInt
    ): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.patch01Input = value
        context.phase = "PATCH_01"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH01_WRAP", e)
        }
    }
}
