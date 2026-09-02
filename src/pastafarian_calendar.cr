require "big"
require "./source_language_catalog"
require "./monster_base"

module PastafarianCalendar
  VERSION = "0.1.0-stage01"
  PROGRAMMING_LANGUAGE = "Crystal"
  NATURAL_LANGUAGE = "ગુજરાતી"

  def self.bootstrap_context(calculation_day : BigInt, target_day : BigInt) : BaseMonsterContext
    context = BaseMonsterContext.new(calculation_day, target_day)
    BaseErrorWrapper.wrap("E_BOOTSTRAP_DISPATCH") do
      BaseDispatcher.new.dispatch_bootstrap(context)
    end
  end

  def self.calendar_date_spaghetti(calculation_day : BigInt, target_day : BigInt)
    bootstrap_context(calculation_day, target_day)
    raise MonsterNotReadyError.new("E_STAGE01_PRODUCTION_SKELETON")
  end
end
