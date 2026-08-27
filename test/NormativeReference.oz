functor
import
   Catalog at '../src/SourceLanguageCatalog.ozf'
export
   M
   TabletsDay
   FoundationDay
   RegularMod
   Save
   FloorDiv
   CeilDiv
   DayCount
   WorkCounts
   BuildStones
   BuildHiddenDrops
   BuildVisibleDrops
   BowlOrderFromNumber
   BowlOrderFromDrop
   Sauce
   AskBowl
   AnswerAt
   ChooseRankShort
   ChooseRankWide
   ChooseRank
   FallingFactorial
   UnrankDistinctIndices
   MakeBoundedCompositionFamily
   MakeCutletPartitionFamily
   MakeWeavingFamily
   CalendarDate

define
   % Čisti testni normativni referentni algoritam.
   % Proizvodni kod ne uvozi ovaj modul i ne smije ga koristiti kao zamjenski izlaz.

   M = 170141183460469231731687303715884105727
   TabletsDay = ~278522
   FoundationDay = ~15055671

   GateGapMin = 42
   GateGapMax = 963
   YearMinDays = 252
   YearMaxDays = 5778
   MinCutlets = 6
   MaxCutlets = 17
   MinMonths = 3
   MaxMonths = 47
   MinMonthDays = 4
   MaxMonthDays = 123

   SealGateGap = 1
   SealYear5000 = 10
   SealNextYear = 11
   SealPreviousYear = 12
   SealCutletCount = 20
   SealCutletPartition = 21
   SealCutletNames = 22
   SealMonthCount = 30
   SealMonthLengths = 31
   SealMonthWeaving = 32
   SealMonthNames = 33

   fun {AbsInt X}
      if X < 0 then ~X else X end
   end

   fun {MinInt A B}
      if A < B then A else B end
   end

   fun {MaxInt A B}
      if A > B then A else B end
   end

   fun {FloorDiv A B}
      Q = A div B
      R = A mod B
   in
      if B =< 0 then raise invalidDivisor(B) end
      elseif R \= 0 andthen A < 0 then Q-1
      else Q
      end
   end

   fun {RegularMod X D}
      if D < 1 then raise invalidModulus(D) end
      else X - {FloorDiv X D}*D
      end
   end

   fun {Save X}
      1 + {RegularMod X-1 M}
   end

   fun {CeilDiv A B}
      if A < 0 orelse B < 1 then raise invalidCeilDiv(A B) end
      else {FloorDiv A+B-1 B}
      end
   end

   fun {Wrap1 Position Size}
      1 + {RegularMod Position-1 Size}
   end

   fun {Square X} X*X end

   fun {Range A B}
      if A > B then nil else A|{Range A+1 B} end
   end

   fun {AppendOne Xs X}
      case Xs
      of nil then [X]
      [] Y|Yr then Y|{AppendOne Yr X}
      end
   end

   fun {Sum Xs}
      case Xs
      of nil then 0
      [] X|Xr then X+{Sum Xr}
      end
   end

   fun {MapList Xs F}
      case Xs
      of nil then nil
      [] X|Xr then {F X}|{MapList Xr F}
      end
   end

   fun {MapRange A B F}
      if A > B then nil
      else {F A}|{MapRange A+1 B F}
      end
   end

   fun {IndexOf Xs Wanted}
      fun {Loop Ys I}
         case Ys
         of nil then raise missingListMember(Wanted) end
         [] Y|Yr then if Y == Wanted then I else {Loop Yr I+1} end
         end
      end
   in
      {Loop Xs 1}
   end

   fun {RemoveNth Xs I}
      case Xs
      of nil then raise invalidRemovalIndex(I) end
      [] X|Xr then
         if I == 1 then Xr
         elseif I > 1 then X|{RemoveNth Xr I-1}
         else raise invalidRemovalIndex(I) end
         end
      end
   end

   fun {Factorial N}
      if N < 0 then raise negativeFactorial(N) end
      elseif N == 0 then 1
      else N*{Factorial N-1}
      end
   end

   fun {DayCount Day}
      if Day == FoundationDay then 1
      elseif Day > FoundationDay then 2*(Day-FoundationDay)+1
      else 2*(FoundationDay-Day)
      end
   end

   fun {WorkCounts CalculationDay TargetDay}
      C = {DayCount CalculationDay}
      T = {DayCount TargetDay}
      Distance = {AbsInt TargetDay-CalculationDay}+1
      Direction = if TargetDay < CalculationDay then 1
                  elseif TargetDay == CalculationDay then 2
                  else 3
                  end
   in
      workCounts(action:C target:T distance:Distance connection:C+T direction:Direction)
   end

   fun {NextStone I Old}
      stone(
         wheat:{Save {Square Old.wheat}+3*Old.barley+I}
         barley:{Save {Square Old.barley}+5*Old.salt+Old.wheat}
         salt:{Save {Square Old.salt}+7*Old.bitter+Old.barley}
         bitter:{Save {Square Old.bitter}+11*Old.red+Old.salt}
         red:{Save {Square Old.red}+13*Old.wheat+Old.bitter})
   end

   fun {BuildStones}
      First = stone(wheat:17 barley:29 salt:43 bitter:71 red:101)
      fun {Loop I Last Acc}
         if I > 46 then Acc
         else
            N = {NextStone I Last}
         in
            {Loop I+1 N {AppendOne Acc N}}
         end
      end
   in
      {Loop 2 First [First]}
   end

   StonesConstant = {BuildStones}

   fun {StoneValue Stone Kind}
      case Kind
      of wheat then Stone.wheat
      [] barley then Stone.barley
      [] salt then Stone.salt
      [] bitter then Stone.bitter
      [] red then Stone.red
      else raise unknownStoneKind(Kind) end
      end
   end

   fun {HiddenCoeff K}
      case K
      of 1 then coeff(a:3 b:4 c:6 d:8)
      [] 2 then coeff(a:5 b:7 c:10 d:12)
      [] 3 then coeff(a:7 b:10 c:14 d:16)
      [] 4 then coeff(a:9 b:13 c:18 d:20)
      [] 5 then coeff(a:11 b:16 c:22 d:24)
      [] 6 then coeff(a:13 b:19 c:26 d:28)
      [] 7 then coeff(a:15 b:22 c:30 d:32)
      else raise invalidHiddenIndex(K) end
      end
   end

   HiddenGrindKinds = [wheat barley salt bitter red wheat barley]

   fun {BuildOneHidden K Counts Stones}
      Co = {HiddenCoeff K}
      St = {List.nth Stones K}
      X0 = {Save Counts.action
                 +Co.a*Counts.target
                 +Co.b*Counts.distance
                 +Co.c*Counts.connection
                 +Co.d*Counts.direction
                 +St.wheat+St.barley+St.salt+St.bitter+St.red}
      fun {Grind G X}
         if G > 7 then X
         else
            Kind = {List.nth HiddenGrindKinds G}
            NX = {Save {Square X}+3*X+{StoneValue St Kind}+G}
         in
            {Grind G+1 NX}
         end
      end
   in
      {Grind 1 X0}
   end

   fun {BuildHiddenDrops Counts Stones}
      {MapRange 1 7 fun {$ K} {BuildOneHidden K Counts Stones} end}
   end

   VisibleGrinds = [
      grind(a:3  b:5  c:7  d:11 kind:wheat)
      grind(a:5  b:7  c:11 d:13 kind:barley)
      grind(a:7  b:11 c:13 d:17 kind:salt)
      grind(a:11 b:13 c:17 d:19 kind:bitter)
      grind(a:13 b:17 c:19 d:23 kind:red)
      grind(a:17 b:19 c:23 d:29 kind:wheat)
      grind(a:19 b:23 c:29 d:31 kind:barley)
      grind(a:23 b:29 c:31 d:37 kind:salt)
      grind(a:29 b:31 c:37 d:41 kind:bitter)
      grind(a:31 b:37 c:41 d:43 kind:red)
      grind(a:37 b:41 c:43 d:47 kind:wheat)
   ]

   fun {PriorDrop Visible Hidden I Back}
      Slot = I-Back
   in
      if Slot >= 1 then {List.nth Visible Slot}
      else {List.nth Hidden 1-Slot}
      end
   end

   fun {BuildOneVisible I Counts Stones Hidden Visible}
      P1 = {PriorDrop Visible Hidden I 1}
      P3 = {PriorDrop Visible Hidden I 3}
      P7 = {PriorDrop Visible Hidden I 7}
      St = {List.nth Stones I}
      X0 = {Save St.wheat*Counts.action
                 +St.barley*Counts.target
                 +St.salt*Counts.distance
                 +St.bitter*Counts.connection
                 +St.red*Counts.direction
                 +P1+3*P3+5*P7+I}
      fun {GrindRows Rows X}
         case Rows
         of nil then X
         [] Row|Rest then
            NX = {Save {Square X}+Row.a*X+Row.b*P1+Row.c*P3+Row.d*P7
                       +{StoneValue St Row.kind}}
         in
            {GrindRows Rest NX}
         end
      end
   in
      {GrindRows VisibleGrinds X0}
   end

   fun {BuildVisibleDrops Counts Stones Hidden}
      fun {Loop I Acc}
         if I > 46 then Acc
         else
            X = {BuildOneVisible I Counts Stones Hidden Acc}
         in
            {Loop I+1 {AppendOne Acc X}}
         end
      end
   in
      {Loop 1 nil}
   end

   fun {PermutationUnrank1 Rank1 ItemsAscending}
      N = {List.length ItemsAscending}
      fun {Loop Remaining SlotsLeft Rank0 Acc}
         if SlotsLeft == 0 then Acc
         else
            Block = {Factorial SlotsLeft-1}
            Q = Rank0 div Block
            NextRank = Rank0 mod Block
            Chosen = {List.nth Remaining Q+1}
         in
            {Loop {RemoveNth Remaining Q+1} SlotsLeft-1 NextRank {AppendOne Acc Chosen}}
         end
      end
   in
      if Rank1 < 1 orelse Rank1 > {Factorial N} then
         raise invalidPermutationRank(Rank1 N) end
      else
         {Loop ItemsAscending N Rank1-1 nil}
      end
   end

   fun {BowlOrderFromNumber OrderNumber}
      if OrderNumber < 1 orelse OrderNumber > 720 then raise invalidBowlOrder(OrderNumber) end
      else {PermutationUnrank1 OrderNumber [1 2 3 4 5 6]}
      end
   end

   fun {BowlOrderFromDrop DropValue}
      {BowlOrderFromNumber {RegularMod DropValue-1 720}+1}
   end

   BowlPrimes = [17 19 23 29 31 37]
   BowlStirKinds = [wheat barley salt bitter red wheat]

   fun {InitialBowls Counts}
      {MapRange 1 6
       fun {$ Id}
          P = {List.nth BowlPrimes Id}
          S = Counts.action+Counts.target*Id+Counts.distance+Counts.connection+Counts.direction+P*P
       in
          {Save S*S+Id}
       end}
   end

   fun {Pours I Drop Stones Old Order}
      St = {List.nth Stones I}
      FirstId = {List.nth Order 1}
      SecondId = {List.nth Order 2}
      ThirdId = {List.nth Order 3}
   in
      [
       {Save Drop*Drop+St.wheat*{List.nth Old FirstId}+3*I}
       {Save Drop*Drop+St.barley*{List.nth Old SecondId}+5*I}
       {Save Drop*Drop+St.salt*{List.nth Old ThirdId}+7*I}
       0 0 0
      ]
   end

   fun {StirDrop I Drop Stones Old Order Pour}
      fun {ForId Id}
         Position = {IndexOf Order Id}
         PrevId = {List.nth Order {Wrap1 Position-1 6}}
         NextId = {List.nth Order {Wrap1 Position+1 6}}
         Kind = {List.nth BowlStirKinds Position}
         St = {List.nth Stones I}
         Mixed = {List.nth Old Id}
                 +2*{List.nth Old PrevId}
                 +3*{List.nth Old NextId}
                 +{List.nth Pour Position}
                 +Drop
                 +{StoneValue St Kind}
      in
         {Save {Square Mixed}
              +5*{List.nth Old PrevId}*{List.nth Old NextId}
              +I*Position}
      end
   in
      {MapRange 1 6 ForId}
   end

   fun {ApplyVisibleDropsToBowls Bowls Visible Stones}
      fun {Loop I Current LastOrder}
         if I > 46 then pair(bowls:Current orderAtDrop46:LastOrder)
         else
            Drop = {List.nth Visible I}
            Order = {BowlOrderFromDrop Drop}
            Pour = {Pours I Drop Stones Current Order}
            Next = {StirDrop I Drop Stones Current Order Pour}
         in
            {Loop I+1 Next if I == 46 then Order else LastOrder end}
         end
      end
   in
      {Loop 1 Bowls none}
   end

   fun {PostStir12 Bowls}
      fun {Loop Stir Current}
         if Stir > 12 then Current
         else
            Saved = {Save {Sum Current}+149*Stir}
            Order = {BowlOrderFromNumber {RegularMod Saved-1 720}+1}
            fun {ForId Id}
               Position = {IndexOf Order Id}
               PrevId = {List.nth Order {Wrap1 Position-1 6}}
               NextId = {List.nth Order {Wrap1 Position+1 6}}
               Mixed = {List.nth Current Id}
                       +3*{List.nth Current PrevId}
                       +5*{List.nth Current NextId}
                       +Saved+Stir+Position*Position
            in
               {Save {Square Mixed}
                    +7*{List.nth Current PrevId}*{List.nth Current NextId}}
            end
            Next = {MapRange 1 6 ForId}
         in
            {Loop Stir+1 Next}
         end
      end
   in
      {Loop 1 Bowls}
   end

   fun {Sauce CalculationDay TargetDay}
      Counts = {WorkCounts CalculationDay TargetDay}
      Stones = StonesConstant
      Hidden = {BuildHiddenDrops Counts Stones}
      Visible = {BuildVisibleDrops Counts Stones Hidden}
      Initial = {InitialBowls Counts}
      Applied = {ApplyVisibleDropsToBowls Initial Visible Stones}
      Final = {PostStir12 Applied.bowls}
   in
      sauceResult(bowls:Final orderAtDrop46:Applied.orderAtDrop46)
   end

   fun {NextBowlInDrop46Order SauceResult QueriedBowlId}
      Position = {IndexOf SauceResult.orderAtDrop46 QueriedBowlId}
   in
      {List.nth SauceResult.orderAtDrop46 {Wrap1 Position+1 6}}
   end

   fun {AskBowl SauceResult QueriedBowlId Seal}
      NextId = {NextBowlInDrop46Order SauceResult QueriedBowlId}
      First = {Save {Square ({List.nth SauceResult.bowls QueriedBowlId}+Seal+181)}
                    +179*{List.nth SauceResult.bowls NextId}+Seal}
      DirectionNumber = {Save {Square (First+Seal+1+193)}
                              +193*First+197*{List.nth SauceResult.bowls 6}}
      Step = if {RegularMod DirectionNumber 2} == 1 then 1 else ~1 end
   in
      answerStream(first:First directionStep:Step)
   end

   fun {AnswerAt Stream K}
      1+{RegularMod Stream.first-1+Stream.directionStep*K M}
   end

   fun {ChooseRankShort Stream N}
      if N < 1 orelse N > M then raise invalidShortChoiceSize(N) end
      else
         Limit = {FloorDiv M N}*N
         fun {Loop K}
            X = {AnswerAt Stream K}
         in
            if X =< Limit then {RegularMod X-1 N}+1 else {Loop K+1} end
         end
      in
         {Loop 0}
      end
   end

   fun {SmallestPowerCount Base N}
      fun {Loop K Space}
         if Space >= N then pair(k:K space:Space)
         else {Loop K+1 Space*Base}
         end
      end
   in
      {Loop 1 Base}
   end

   fun {ChooseRankWide Stream N}
      if N =< M then raise invalidWideChoiceSize(N) end
      else
         P = {SmallestPowerCount M N}
         fun {Digits J Weight Acc}
            if J >= P.k then Acc
            else {Digits J+1 Weight*M Acc+({AnswerAt Stream J}-1)*Weight}
            end
         end
         Wide0 = {Digits 0 1 1}
         Limit = {FloorDiv P.space N}*N
         fun {Walk W}
            if W =< Limit then {RegularMod W-1 N}+1
            else {Walk 1+{RegularMod W-1+Stream.directionStep P.space}}
            end
         end
      in
         {Walk Wide0}
      end
   end

   fun {ChooseRank Stream N}
      if N < 1 then raise invalidChoiceSize(N) end
      elseif N =< M then {ChooseRankShort Stream N}
      else {ChooseRankWide Stream N}
      end
   end

   fun {FallingFactorial N K}
      fun {Loop J Acc}
         if J >= K then Acc else {Loop J+1 Acc*(N-J)} end
      end
   in
      if K < 0 orelse K > N then raise invalidFallingFactorial(N K) end
      else {Loop 0 1}
      end
   end

   fun {UnrankDistinctIndices N K Rank1}
      Remaining0 = {Range 1 N}
      fun {Loop Position Remaining R Acc}
         if Position > K then Acc
         else
            Suffix = K-Position
            Block = {FallingFactorial {List.length Remaining}-1 Suffix}
            fun {Pick CandidateIndex RR}
               if RR > Block then {Pick CandidateIndex+1 RR-Block}
               else choice(index:CandidateIndex rank:RR)
               end
            end
            Ch = {Pick 1 R}
            Selected = {List.nth Remaining Ch.index}
         in
            {Loop Position+1 {RemoveNth Remaining Ch.index} Ch.rank {AppendOne Acc Selected}}
         end
      end
      Total = {FallingFactorial N K}
   in
      if Rank1 < 1 orelse Rank1 > Total then raise invalidDistinctRank(Rank1 Total) end
      else {Loop 1 Remaining0 Rank1 nil}
      end
   end

   fun {MakeBoundedCompositionFamily Total Slots Lo Hi}
      Memo = {NewDictionary}
      MaxSlots = Slots
      fun {Key Rem K} (Rem*(MaxSlots+1))+K end
      fun {Count Rem K}
         if K == 0 then if Rem == 0 then 1 else 0 end
         elseif Rem < K*Lo orelse Rem > K*Hi then 0
         else
            Ky = {Key Rem K}
            Old = {Dictionary.condGet Memo Ky none}
         in
            if Old \= none then Old
            else
               fun {SumX X Acc}
                  if X > Hi then Acc
                  else {SumX X+1 Acc+{Count Rem-X K-1}}
                  end
               end
               V = {SumX Lo 0}
            in
               {Dictionary.put Memo Ky V}
               V
            end
         end
      end
      fun {Unrank Rank1}
         fun {Loop Position Rem R Acc}
            if Position > Slots then Acc
            else
               fun {Pick X RR}
                  if X > Hi then raise boundedUnrankFailure(Rem Position RR) end
                  else
                     Block = {Count Rem-X Slots-Position}
                  in
                     if RR > Block then {Pick X+1 RR-Block}
                     else choice(x:X rank:RR)
                     end
                  end
               end
               Ch = {Pick Lo R}
            in
               {Loop Position+1 Rem-Ch.x Ch.rank {AppendOne Acc Ch.x}}
            end
         end
      in
         if Rank1 < 1 orelse Rank1 > {Count Total Slots} then raise invalidBoundedRank(Rank1) end
         else {Loop 1 Total Rank1 nil}
         end
      end
   in
      family(count:fun {$} {Count Total Slots} end unrank1:Unrank)
   end

   fun {MakeCutletPartitionFamily GateGaps CutletCount RequiredBoundary}
      Memo = {NewDictionary}
      Base = GateGaps+1
      fun {Key Rem Slots Cumulative Hit}
         HitN = if Hit then 1 else 0 end
      in
         ((((Rem*(CutletCount+1))+Slots)*Base+Cumulative)*2)+HitN
      end
      fun {Count Rem Slots Cumulative Hit}
         if Slots == 0 then
            if Rem \= 0 then 0
            elseif RequiredBoundary == none then 1
            elseif Hit then 1 else 0
            end
         elseif Rem < Slots then 0
         else
            Ky = {Key Rem Slots Cumulative Hit}
            Old = {Dictionary.condGet Memo Ky none}
         in
            if Old \= none then Old
            else
               MaxX = Rem-(Slots-1)
               fun {SumX X Acc}
                  if X > MaxX then Acc
                  else
                     NextC = Cumulative+X
                     NextHit = if RequiredBoundary == none then Hit
                               elseif Hit then true
                               elseif NextC == RequiredBoundary then true
                               else false
                               end
                  in
                     if RequiredBoundary \= none andthen not Hit andthen NextC > RequiredBoundary then
                        {SumX X+1 Acc}
                     else
                        {SumX X+1 Acc+{Count Rem-X Slots-1 NextC NextHit}}
                     end
                  end
               end
               V = {SumX 1 0}
            in
               {Dictionary.put Memo Ky V}
               V
            end
         end
      end
      fun {Unrank Rank1}
         fun {Loop Rem Slots Cumulative Hit R Acc}
            if Slots == 0 then Acc
            else
               MaxX = Rem-(Slots-1)
               fun {Pick X RR}
                  if X > MaxX then raise cutletUnrankFailure(RR) end
                  else
                     NextC = Cumulative+X
                     NextHit = if RequiredBoundary == none then Hit
                               elseif Hit then true
                               elseif NextC == RequiredBoundary then true
                               else false
                               end
                  in
                     if RequiredBoundary \= none andthen not Hit andthen NextC > RequiredBoundary then
                        {Pick X+1 RR}
                     else
                        Block = {Count Rem-X Slots-1 NextC NextHit}
                     in
                        if RR > Block then {Pick X+1 RR-Block}
                        else choice(x:X rank:RR cumulative:NextC hit:NextHit)
                        end
                     end
                  end
               end
               Ch = {Pick 1 R}
            in
               {Loop Rem-Ch.x Slots-1 Ch.cumulative Ch.hit Ch.rank {AppendOne Acc Ch.x}}
            end
         end
      in
         if Rank1 < 1 orelse Rank1 > {Count GateGaps CutletCount 0 false} then
            raise invalidCutletPartitionRank(Rank1) end
         else
            {Loop GateGaps CutletCount 0 false Rank1 nil}
         end
      end
   in
      family(count:fun {$} {Count GateGaps CutletCount 0 false} end unrank1:Unrank)
   end

   fun {MakeWeavingFamily Lengths}
      MCount = {List.length Lengths}
      Memo = {NewDictionary}

      fun {EncodeRemaining Remaining}
         fun {Loop Rs Ls Weight Acc}
            case Rs#Ls
            of nil#nil then Acc
            [] (R|Rr)#(L|Lr) then {Loop Rr Lr Weight*(L+1) Acc+R*Weight}
            else raise weavingShapeMismatch end
            end
         end
      in
         {Loop Remaining Lengths 1 0}
      end

      fun {Key Remaining Opened Closed}
         Enc = {EncodeRemaining Remaining}
      in
         ((Enc*(MCount+1)+Opened)*(MCount+1))+Closed
      end

      fun {RemainingAt Remaining J} {List.nth Remaining J} end

      fun {ReplaceAt Xs I Value}
         case Xs
         of nil then raise invalidReplaceIndex(I) end
         [] X|Xr then
            if I == 1 then Value|Xr
            else X|{ReplaceAt Xr I-1 Value}
            end
         end
      end

      fun {Legal Remaining Opened Closed J}
         R = {RemainingAt Remaining J}
         Original = {List.nth Lengths J}
         AlreadyOpened = R < Original
         WillClose = R == 1
      in
         R > 0
         andthen (AlreadyOpened orelse J == Opened+1)
         andthen (not WillClose orelse J == Closed+1)
      end

      fun {Move Remaining Opened Closed J}
         R = {RemainingAt Remaining J}
         Original = {List.nth Lengths J}
         NewOpened = if R == Original then J else Opened end
         NewRemaining = {ReplaceAt Remaining J R-1}
         NewClosed = if R-1 == 0 then J else Closed end
      in
         state(remaining:NewRemaining opened:NewOpened closed:NewClosed)
      end

      fun {AllZero Xs}
         case Xs
         of nil then true
         [] X|Xr then X == 0 andthen {AllZero Xr}
         end
      end

      fun {Count Remaining Opened Closed}
         if {AllZero Remaining} then 1
         else
            Ky = {Key Remaining Opened Closed}
            Old = {Dictionary.condGet Memo Ky none}
         in
            if Old \= none then Old
            else
               fun {SumJ J Acc}
                  if J > MCount then Acc
                  elseif {Legal Remaining Opened Closed J} then
                     S = {Move Remaining Opened Closed J}
                  in
                     {SumJ J+1 Acc+{Count S.remaining S.opened S.closed}}
                  else {SumJ J+1 Acc}
                  end
               end
               V = {SumJ 1 0}
            in
               {Dictionary.put Memo Ky V}
               V
            end
         end
      end

      fun {Unrank Rank1}
         TotalDays = {Sum Lengths}
         fun {Loop Remaining Opened Closed R Position Acc}
            if Position > TotalDays then Acc
            else
               fun {Pick J RR}
                  if J > MCount then raise weavingUnrankFailure(RR Position) end
                  elseif not {Legal Remaining Opened Closed J} then {Pick J+1 RR}
                  else
                     S = {Move Remaining Opened Closed J}
                     Block = {Count S.remaining S.opened S.closed}
                  in
                     if RR > Block then {Pick J+1 RR-Block}
                     else choice(j:J rank:RR state:S)
                     end
                  end
               end
               Ch = {Pick 1 R}
            in
               {Loop Ch.state.remaining Ch.state.opened Ch.state.closed Ch.rank Position+1 {AppendOne Acc Ch.j}}
            end
         end
         Total = {Count Lengths 0 0}
      in
         if Rank1 < 1 orelse Rank1 > Total then raise invalidWeavingRank(Rank1 Total) end
         else {Loop Lengths 0 0 Rank1 1 nil}
         end
      end
   in
      family(count:fun {$} {Count Lengths 0 0} end unrank1:Unrank)
   end

   fun {MakeGateEngine}
      Cache = {NewDictionary}
      {Dictionary.put Cache 0 FoundationDay}

      fun {GateGap SignedIndex}
         QuestionDay = FoundationDay+SignedIndex
         R = {Sauce FoundationDay QuestionDay}
         Stream = {AskBowl R 1 SealGateGap}
      in
         41+{ChooseRank Stream 922}
      end

      fun {Gate K}
         Existing = {Dictionary.condGet Cache K none}
      in
         if Existing \= none then Existing
         elseif K > 0 then
            V = {Gate K-1}+{GateGap K}
         in
            {Dictionary.put Cache K V}
            V
         else
            V = {Gate K+1}-{GateGap K}
         in
            {Dictionary.put Cache K V}
            V
         end
      end

      fun {IndexAtOrBefore Day}
         G0 = {Gate 0}
         fun {Forward Hi}
            if {Gate Hi} > Day then pair(lo:Hi div 2 hi:Hi)
            else {Forward Hi*2}
            end
         end
         fun {Backward Lo}
            if {Gate Lo} =< Day then pair(lo:Lo hi:Lo div 2)
            else {Backward Lo*2}
            end
         end
         Bounds = if Day >= G0 then {Forward 1} else {Backward ~1} end
         fun {Binary Lo Hi}
            if Lo >= Hi then Lo
            else
               Mid = Lo+{FloorDiv Hi-Lo+1 2}
            in
               if {Gate Mid} =< Day then {Binary Mid Hi}
               else {Binary Lo Mid-1}
               end
            end
         end
      in
         {Binary Bounds.lo Bounds.hi}
      end

      fun {IndexAtOrAfter Day}
         I = {IndexAtOrBefore Day}
      in
         if {Gate I} == Day then I else I+1 end
      end

      fun {ExactIndex Day}
         I = {IndexAtOrBefore Day}
      in
         if {Gate I} == Day then I else none end
      end
   in
      gateEngine(get:Gate indexAtOrBefore:IndexAtOrBefore indexAtOrAfter:IndexAtOrAfter exactIndex:ExactIndex)
   end

   fun {YearLength Engine OpenIndex CloseIndex}
      {Engine.get CloseIndex}-{Engine.get OpenIndex}
   end

   fun {ValidYearPair Engine OpenIndex CloseIndex}
      L = {YearLength Engine OpenIndex CloseIndex}
   in
      CloseIndex-OpenIndex >= 6 andthen L >= YearMinDays andthen L =< YearMaxDays
   end

   fun {StableInsertYearCandidate Engine Candidate Sorted ByOpeningTie}
      case Sorted
      of nil then [Candidate]
      [] H|T then
         LC = {YearLength Engine Candidate.open Candidate.close}
         LH = {YearLength Engine H.open H.close}
         Before = if LC < LH then true
                  elseif LC > LH then false
                  elseif ByOpeningTie then {Engine.get Candidate.open} < {Engine.get H.open}
                  else true
                  end
      in
         if Before then Candidate|Sorted
         else H|{StableInsertYearCandidate Engine Candidate T ByOpeningTie}
         end
      end
   end

   fun {SortYearCandidates Engine Xs ByOpeningTie}
      case Xs
      of nil then nil
      [] X|Xr then {StableInsertYearCandidate Engine X {SortYearCandidates Engine Xr ByOpeningTie} ByOpeningTie}
      end
   end

   fun {MakeYear Engine Number OpenIndex CloseIndex}
      year(number:Number openGateIndex:OpenIndex closeGateIndex:CloseIndex
           openGateDay:{Engine.get OpenIndex} closeGateDay:{Engine.get CloseIndex})
   end

   fun {Year5000 CalculationDay Engine}
      LowIndex = {Engine.indexAtOrBefore CalculationDay-YearMaxDays}
      HighIndex = {Engine.indexAtOrAfter CalculationDay+YearMaxDays}
      fun {Pairs I J Acc}
         if I >= HighIndex then Acc
         elseif J > HighIndex then {Pairs I+1 I+2 Acc}
         else
            OpenDay = {Engine.get I}
            CloseDay = {Engine.get J}
            Good = {ValidYearPair Engine I J}
                   andthen OpenDay < CalculationDay
                   andthen CalculationDay =< CloseDay
            NextAcc = if Good then {AppendOne Acc candidate(open:I close:J)} else Acc end
         in
            {Pairs I J+1 NextAcc}
         end
      end
      Candidates = {SortYearCandidates Engine {Pairs LowIndex LowIndex+1 nil} true}
      R = {Sauce CalculationDay CalculationDay}
      Stream = {AskBowl R 1 SealYear5000}
      Rank = {ChooseRank Stream {List.length Candidates}}
      Chosen = {List.nth Candidates Rank}
   in
      {MakeYear Engine 5000 Chosen.open Chosen.close}
   end

   fun {NextYear CalculationDay Known Engine}
      Open = Known.closeGateIndex
      fun {Collect J Acc}
         L = {Engine.get J}-{Engine.get Open}
      in
         if L > YearMaxDays then Acc
         elseif {ValidYearPair Engine Open J} then {Collect J+1 {AppendOne Acc candidate(open:Open close:J)}}
         else {Collect J+1 Acc}
         end
      end
      Candidates = {SortYearCandidates Engine {Collect Open+1 nil} false}
      R = {Sauce CalculationDay {Engine.get Open}}
      Rank = {ChooseRank {AskBowl R 1 SealNextYear} {List.length Candidates}}
      C = {List.nth Candidates Rank}
   in
      {MakeYear Engine Known.number+1 Open C.close}
   end

   fun {PreviousYear CalculationDay Known Engine}
      Close = Known.openGateIndex
      fun {Collect I Acc}
         L = {Engine.get Close}-{Engine.get I}
      in
         if L > YearMaxDays then Acc
         elseif {ValidYearPair Engine I Close} then {Collect I-1 {AppendOne Acc candidate(open:I close:Close)}}
         else {Collect I-1 Acc}
         end
      end
      Candidates = {SortYearCandidates Engine {Collect Close-1 nil} false}
      R = {Sauce CalculationDay {Engine.get Close}}
      Rank = {ChooseRank {AskBowl R 1 SealPreviousYear} {List.length Candidates}}
      C = {List.nth Candidates Rank}
   in
      {MakeYear Engine Known.number-1 C.open Close}
   end

   fun {FindTargetYear CalculationDay TargetDay Engine}
      fun {Walk Y}
         if TargetDay > Y.closeGateDay then {Walk {NextYear CalculationDay Y Engine}}
         elseif TargetDay =< Y.openGateDay then {Walk {PreviousYear CalculationDay Y Engine}}
         else Y
         end
      end
   in
      {Walk {Year5000 CalculationDay Engine}}
   end

   fun {ChooseCutletCount StructureSauce Year}
      Gaps = Year.closeGateIndex-Year.openGateIndex
      Candidates = {MapList {Range MinCutlets MaxCutlets}
                    fun {$ K} if K =< Gaps then K else none end end}
      fun {RemoveNone Xs}
         case Xs
         of nil then nil
         [] X|Xr then if X == none then {RemoveNone Xr} else X|{RemoveNone Xr} end
         end
      end
      Cs = {RemoveNone Candidates}
      Rank = {ChooseRank {AskBowl StructureSauce 2 SealCutletCount} {List.length Cs}}
   in
      {List.nth Cs Rank}
   end

   fun {ChooseCutletPartition CalculationDay StructureSauce Year CutletCount Engine}
      G = Year.closeGateIndex-Year.openGateIndex
      Exact = {Engine.exactIndex CalculationDay}
      Required = if Exact \= none andthen Exact > Year.openGateIndex andthen Exact < Year.closeGateIndex
                 then Exact-Year.openGateIndex else none end
      Family = {MakeCutletPartitionFamily G CutletCount Required}
      Rank = {ChooseRank {AskBowl StructureSauce 2 SealCutletPartition} {Family.count}}
   in
      {Family.unrank1 Rank}
   end

   fun {ChooseCutletNameIndices StructureSauce CutletCount}
      N = {FallingFactorial Catalog.cutletCount CutletCount}
      Rank = {ChooseRank {AskBowl StructureSauce 5 SealCutletNames} N}
   in
      {UnrankDistinctIndices Catalog.cutletCount CutletCount Rank}
   end

   fun {MaterializeCutlets Year Partition NameIndices Engine}
      fun {Loop Parts Names Cursor Acc}
         case Parts#Names
         of nil#nil then Acc
         [] (P|Pr)#(N|Nr) then
            Close = Cursor+P
            C = cutlet(nameIndex:N openGateIndex:Cursor closeGateIndex:Close
                        firstDay:{Engine.get Cursor}+1 lastDay:{Engine.get Close})
         in
            {Loop Pr Nr Close {AppendOne Acc C}}
         else raise cutletMaterializationShapeMismatch end
         end
      end
   in
      {Loop Partition NameIndices Year.openGateIndex nil}
   end

   fun {ChooseMonthCount StructureSauce Year}
      L = Year.closeGateDay-Year.openGateDay
      Low = {CeilDiv L MaxMonthDays}
      High = {MinInt MaxMonths {FloorDiv L MinMonthDays}}
      Candidates = {Range Low High}
      Rank = {ChooseRank {AskBowl StructureSauce 3 SealMonthCount} {List.length Candidates}}
   in
      if Low < MinMonths orelse Low > High then raise invalidMonthBounds(L Low High) end
      else {List.nth Candidates Rank}
      end
   end

   fun {ChooseMonthLengths StructureSauce Year MonthCount}
      L = Year.closeGateDay-Year.openGateDay
      Family = {MakeBoundedCompositionFamily L MonthCount MinMonthDays MaxMonthDays}
      Rank = {ChooseRank {AskBowl StructureSauce 3 SealMonthLengths} {Family.count}}
   in
      {Family.unrank1 Rank}
   end

   fun {ChooseMonthWeaving StructureSauce Lengths}
      Family = {MakeWeavingFamily Lengths}
      Rank = {ChooseRank {AskBowl StructureSauce 4 SealMonthWeaving} {Family.count}}
   in
      {Family.unrank1 Rank}
   end

   fun {ChooseMonthNameIndices StructureSauce MonthCount}
      N = {FallingFactorial Catalog.monthCount MonthCount}
      Rank = {ChooseRank {AskBowl StructureSauce 5 SealMonthNames} N}
   in
      {UnrankDistinctIndices Catalog.monthCount MonthCount Rank}
   end

   fun {BuildYearStructure CalculationDay Year Engine}
      FirstDay = Year.openGateDay+1
      R = {Sauce CalculationDay FirstDay}
      CutletCount = {ChooseCutletCount R Year}
      Partition = {ChooseCutletPartition CalculationDay R Year CutletCount Engine}
      CutletNames = {ChooseCutletNameIndices R CutletCount}
      Cutlets = {MaterializeCutlets Year Partition CutletNames Engine}
      MonthCount = {ChooseMonthCount R Year}
      MonthLengths = {ChooseMonthLengths R Year MonthCount}
      Weave = {ChooseMonthWeaving R MonthLengths}
      MonthNames = {ChooseMonthNameIndices R MonthCount}
   in
      yearStructure(cutletCount:CutletCount cutletPartition:Partition
                    cutletNameIndices:CutletNames cutlets:Cutlets
                    monthCount:MonthCount monthLengths:MonthLengths
                    monthWeaving:Weave monthNameIndices:MonthNames)
   end

   fun {FindCutlet Cutlets TargetDay Index}
      case Cutlets
      of nil then raise targetOutsideCutlets(TargetDay) end
      [] C|Cr then
         if C.firstDay =< TargetDay andthen TargetDay =< C.lastDay then pair(index:Index cutlet:C)
         else {FindCutlet Cr TargetDay Index+1}
         end
      end
   end

   fun {CountOccurrencesPrefix Xs Wanted Limit}
      fun {Loop Ys Position Acc}
         if Position > Limit then Acc
         else
            case Ys
            of nil then Acc
            [] X|Xr then {Loop Xr Position+1 if X == Wanted then Acc+1 else Acc end}
            end
         end
      end
   in
      {Loop Xs 1 0}
   end

   fun {CalendarDate CalculationDay TargetDay}
      if not {Int.is CalculationDay} orelse not {Int.is TargetDay} then
         raise nonIntegerDay(CalculationDay TargetDay) end
      else
         Engine = {MakeGateEngine}
         Year = {FindTargetYear CalculationDay TargetDay Engine}
         Structure = {BuildYearStructure CalculationDay Year Engine}
         CInfo = {FindCutlet Structure.cutlets TargetDay 1}
         DayInCutlet = TargetDay-CInfo.cutlet.firstDay+1
         Offset0 = TargetDay-(Year.openGateDay+1)
         MonthId = {List.nth Structure.monthWeaving Offset0+1}
         MonthNameIndex = {List.nth Structure.monthNameIndices MonthId}
         DayInMonth = {CountOccurrencesPrefix Structure.monthWeaving MonthId Offset0+1}
      in
         result(yearNumber:Year.number
                cutletName:{Catalog.cutletName CInfo.cutlet.nameIndex}
                dayInCutlet:DayInCutlet
                monthName:{Catalog.monthName MonthNameIndex}
                dayInMonth:DayInMonth)
      end
   end
end
