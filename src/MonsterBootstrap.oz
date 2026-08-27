functor
import
   Catalog at 'SourceLanguageCatalog.ozf'
export
   NewMonsterContext
   ValidateMonsterContext
   CalendarDateSpaghetti

define
   % Etapa 1 smije sadržavati samo neutralnu infrastrukturu.
   % Nijedna povijesna pogreška ni zakrpa 01--26 ovdje još ne postoji.

   fun {NewMonsterContext CalculationDay TargetDay}
      monsterContext(
         calculationDay:CalculationDay
         targetDay:TargetDay
         phase:bootstrap
         subPhase:0
         mode:authoritative
         status:new
         retryBudget:0
         recoveryDepth:0
         currentHandler:none
         previousHandler:none
         branchTrace:nil
         metrics:metrics(calls:0 validations:0 failures:0)
         logs:nil
         diagnostics:nil
         warnings:nil
         validationFailures:nil
         pendingSemanticState:none
         committedSemanticState:none
         resultFive:none)
   end

   fun {ValidateMonsterContext Context}
      {Int.is Context.calculationDay}
      andthen {Int.is Context.targetDay}
      andthen Context.phase == bootstrap
      andthen Context.mode == authoritative
      andthen Context.pendingSemanticState == none
      andthen Context.resultFive == none
      andthen {Catalog.validateCatalog}
   end

   fun {CalendarDateSpaghetti CalculationDay TargetDay}
      Context = {NewMonsterContext CalculationDay TargetDay}
   in
      if {ValidateMonsterContext Context} then
         % Proizvodni put namjerno nije implementiran prije povijesnih etapa.
         % Referentni algoritam iz testnoga stabla nikada nije zamjenski izlaz.
         raise stageNotIntegrated(stage:1 calculationDay:CalculationDay targetDay:TargetDay) end
      else
         raise invalidBootstrapContext end
      end
   end
end
