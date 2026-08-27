functor
import
   Application
   System
   Catalog at '../src/SourceLanguageCatalog.ozf'
   Bootstrap at '../src/MonsterBootstrap.ozf'
   Ref at 'NormativeReference.ozf'
define
   proc {Fail Name Got Expected}
      {System.showInfo 'NEUSPJEH: '#Name}
      raise testFailure(name:Name got:Got expected:Expected) end
   end

   proc {AssertEqual Name Got Expected}
      if Got == Expected then skip else {Fail Name Got Expected} end
   end

   proc {AssertTrue Name Value}
      if Value then skip else {Fail Name Value true} end
   end

   fun {AllBetween Xs Lo Hi}
      case Xs
      of nil then true
      [] X|Xr then X >= Lo andthen X =< Hi andthen {AllBetween Xr Lo Hi}
      end
   end

   fun {AllDistinct Xs}
      case Xs
      of nil then true
      [] X|Xr then not {List.member X Xr} andthen {AllDistinct Xr}
      end
   end

   proc {Run}
      F = Ref.foundationDay
      M = Ref.m
      Counts0 = {Ref.workCounts F F}
      CountsForward = {Ref.workCounts F F+1}
      CountsBackward = {Ref.workCounts F+1 F}
      Stones = {Ref.buildStones}
      SecondStone = {List.nth Stones 2}
      Hidden = {Ref.buildHiddenDrops Counts0 Stones}
      Visible = {Ref.buildVisibleDrops Counts0 Stones Hidden}
      Sauce0 = {Ref.sauce F F}
      Stream0 = {Ref.askBowl Sauce0 1 1}
      Bounded = {Ref.makeBoundedCompositionFamily 6 2 1 5}
      CutletNoBoundary = {Ref.makeCutletPartitionFamily 6 3 none}
      CutletBoundary = {Ref.makeCutletPartitionFamily 6 3 2}
      Weave22 = {Ref.makeWeavingFamily [2 2]}
      Weave111 = {Ref.makeWeavingFamily [1 1 1]}
      WideRank = {Ref.chooseRankWide answerStream(first:1 directionStep:1) M+1}
      Context = {Bootstrap.newMonsterContext F F}
   in
      {AssertTrue catalogValid {Catalog.validateCatalog}}
      {AssertEqual cutletCount Catalog.cutletCount 17}
      {AssertEqual monthCount Catalog.monthCount 47}
      {AssertEqual firstCutletName {Catalog.cutletName 1} "bronca"}
      {AssertEqual wheatCutletName {Catalog.cutletName 12} "pšenica"}
      {AssertEqual emptyJugCutletName {Catalog.cutletName 17} "prazni vrč"}
      {AssertEqual firstMonthName {Catalog.monthName 1} "glina"}
      {AssertEqual lastMonthName {Catalog.monthName 47} "pijesak"}

      {AssertEqual tabletsDay Ref.tabletsDay ~278522}
      {AssertEqual foundationDay F ~15055671}
      {AssertEqual tabletsDistance Ref.tabletsDay-F 14777149}
      {AssertEqual bigCount M 170141183460469231731687303715884105727}

      {AssertEqual floorDivPositive {Ref.floorDiv 11 5} 2}
      {AssertEqual floorDivNegative {Ref.floorDiv ~1 5} ~1}
      {AssertEqual regularModNegative {Ref.regularMod ~1 5} 4}
      {AssertEqual ceilDivBasic {Ref.ceilDiv 10 3} 4}

      {AssertEqual saveOne {Ref.save 1} 1}
      {AssertEqual saveMMinusOne {Ref.save M-1} M-1}
      {AssertEqual saveM {Ref.save M} M}
      {AssertEqual saveMPlusOne {Ref.save M+1} 1}
      {AssertEqual saveTwoM {Ref.save 2*M} M}

      {AssertEqual dayCountFoundation {Ref.dayCount F} 1}
      {AssertEqual dayCountBefore {Ref.dayCount F-1} 2}
      {AssertEqual dayCountAfter {Ref.dayCount F+1} 3}
      {AssertEqual dayCountBeforeTwo {Ref.dayCount F-2} 4}
      {AssertEqual dayCountAfterTwo {Ref.dayCount F+2} 5}

      {AssertEqual workCountsSame Counts0 workCounts(action:1 target:1 distance:1 connection:2 direction:2)}
      {AssertEqual workCountsForward CountsForward workCounts(action:1 target:3 distance:2 connection:4 direction:3)}
      {AssertEqual workCountsBackward CountsBackward workCounts(action:3 target:1 distance:2 connection:4 direction:1)}

      {AssertEqual stoneCount {List.length Stones} 46}
      {AssertEqual secondStone SecondStone stone(wheat:378 barley:1073 salt:2375 bitter:6195 red:10493)}
      {AssertEqual hiddenCount {List.length Hidden} 7}
      {AssertTrue hiddenRange {AllBetween Hidden 1 M}}
      {AssertEqual visibleCount {List.length Visible} 46}
      {AssertTrue visibleRange {AllBetween Visible 1 M}}

      {AssertEqual permutationFirst {Ref.bowlOrderFromNumber 1} [1 2 3 4 5 6]}
      {AssertEqual permutationLast {Ref.bowlOrderFromNumber 720} [6 5 4 3 2 1]}
      {AssertEqual drop720Order {Ref.bowlOrderFromDrop 720} [6 5 4 3 2 1]}
      {AssertEqual drop721Order {Ref.bowlOrderFromDrop 721} [1 2 3 4 5 6]}

      {AssertEqual sauceBowlCount {List.length Sauce0.bowls} 6}
      {AssertTrue sauceBowlRange {AllBetween Sauce0.bowls 1 M}}
      {AssertEqual sauceOrderCount {List.length Sauce0.orderAtDrop46} 6}
      {AssertTrue sauceOrderDistinct {AllDistinct Sauce0.orderAtDrop46}}
      {AssertTrue streamFirstRange Stream0.first >= 1 andthen Stream0.first =< M}
      {AssertTrue streamDirection Stream0.directionStep == 1 orelse Stream0.directionStep == ~1}
      {AssertEqual sauceDeterministic {Ref.sauce F F} Sauce0}

      {AssertEqual chooseShortOne {Ref.chooseRankShort answerStream(first:1 directionStep:1) 10} 1}
      {AssertEqual chooseShortRejectWrap {Ref.chooseRankShort answerStream(first:M directionStep:1) 2} 1}
      {AssertEqual chooseShortM {Ref.chooseRankShort answerStream(first:M directionStep:1) M} M}
      {AssertTrue chooseWideRange WideRank>=1 andthen WideRank=<M+1}

      {AssertEqual fallingFactorial {Ref.fallingFactorial 5 3} 60}
      {AssertEqual distinctRank1 {Ref.unrankDistinctIndices 3 2 1} [1 2]}
      {AssertEqual distinctRank2 {Ref.unrankDistinctIndices 3 2 2} [1 3]}
      {AssertEqual distinctRank6 {Ref.unrankDistinctIndices 3 2 6} [3 2]}

      {AssertEqual boundedCount {Bounded.count} 5}
      {AssertEqual boundedFirst {Bounded.unrank1 1} [1 5]}
      {AssertEqual boundedMiddle {Bounded.unrank1 3} [3 3]}
      {AssertEqual boundedLast {Bounded.unrank1 5} [5 1]}

      {AssertEqual cutletCountNoBoundary {CutletNoBoundary.count} 10}
      {AssertEqual cutletCountBoundary {CutletBoundary.count} 4}
      {AssertEqual cutletBoundaryFirst {CutletBoundary.unrank1 1} [1 1 4]}
      {AssertEqual cutletBoundaryLast {CutletBoundary.unrank1 4} [2 3 1]}

      {AssertEqual weave22Count {Weave22.count} 2}
      {AssertEqual weave22First {Weave22.unrank1 1} [1 1 2 2]}
      {AssertEqual weave22Second {Weave22.unrank1 2} [1 2 1 2]}
      {AssertEqual weave111Count {Weave111.count} 1}
      {AssertEqual weave111Only {Weave111.unrank1 1} [1 2 3]}

      {AssertTrue bootstrapContext {Bootstrap.validateMonsterContext Context}}
      try
         _ = {Bootstrap.calendarDateSpaghetti F F}
         {Fail productionMustNotReturn returnedValue stageNotIntegrated}
      catch stageNotIntegrated(stage:1 calculationDay:F targetDay:F) then skip
      [] E then {Fail productionWrongException E stageNotIntegrated}
      end

      {System.showInfo 'SVE PROVJERE ETAPE 1 SU PROŠLE'}
   end

   Status = try {Run} 0 catch E then
               {System.showInfo 'ETAPA 1 NIJE PROŠLA'}
               {System.show E}
               1
            end
in
   {Application.exit Status}
end
