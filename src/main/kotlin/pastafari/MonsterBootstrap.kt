package pastafari

data class BaseMonsterContext(
    val calculationDay: ExactInt,
    val targetDay: ExactInt,
    var phase: String = "BOOT",
    var status: String = "NEW",
    val branchTrace: MutableList<String> = mutableListOf(),
    val diagnostics: MutableList<String> = mutableListOf()
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
    val errors: BaseErrorWrapper = BaseErrorWrapper()
) {
    init {
        dispatcher.register("BOOT") { context ->
            validation.requireBootstrapContext(context)
            context.branchTrace.add("BOOT")
            context.status = "READY"
            metrics.bump("bootstrap.ready")
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
}
