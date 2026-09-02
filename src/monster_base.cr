require "big"

module PastafarianCalendar
  class MonsterError < Exception
  end

  class MonsterValidationError < MonsterError
  end

  class MonsterNotReadyError < MonsterError
  end

  class MetricsShell
    getter counters : Hash(String, BigInt)

    def initialize
      @counters = Hash(String, BigInt).new { |h, k| h[k] = BigInt.new(0) }
    end

    def bump(code : String)
      @counters[code] = @counters[code] + 1
    end
  end

  class LogShell
    getter events : Array(String)

    def initialize
      @events = [] of String
    end

    def append(code : String)
      @events << code
    end
  end

  class BaseMonsterContext
    getter calculation_day : BigInt
    getter target_day : BigInt
    property phase : String
    property sub_phase : Int32
    property status : String
    getter metrics : MetricsShell
    getter logs : LogShell
    getter validation_failures : Array(String)

    def initialize(@calculation_day : BigInt, @target_day : BigInt)
      @phase = "BOOTSTRAP"
      @sub_phase = 0
      @status = "NEW"
      @metrics = MetricsShell.new
      @logs = LogShell.new
      @validation_failures = [] of String
    end
  end

  class BaseValidationManager
    def verify_input(context : BaseMonsterContext)
      context.metrics.bump("validation.input")
      context.logs.append("VALIDATION_INPUT_OK")
      true
    end

    def verify_no_semantic_state(context : BaseMonsterContext)
      context.metrics.bump("validation.neutral_state")
      context.logs.append("VALIDATION_NEUTRAL_STATE_OK")
      true
    end
  end

  class BaseDispatcher
    getter validation : BaseValidationManager

    def initialize(@validation = BaseValidationManager.new)
    end

    def dispatch_bootstrap(context : BaseMonsterContext)
      context.phase = "BOOTSTRAP_DISPATCH"
      context.status = "VALIDATING"
      validation.verify_input(context)
      validation.verify_no_semantic_state(context)
      context.status = "READY_FOR_HISTORICAL_GROWTH"
      context.metrics.bump("dispatcher.bootstrap")
      context.logs.append("BOOTSTRAP_DISPATCH_OK")
      context
    end
  end

  class BaseErrorWrapper
    def self.wrap(code : String, &block)
      yield
    rescue ex : MonsterError
      raise ex
    rescue ex
      raise MonsterError.new(code)
    end
  end
end
