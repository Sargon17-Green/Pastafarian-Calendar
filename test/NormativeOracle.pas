unit NormativeOracle;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

interface

uses
  SysUtils, BigInt;

const
  TABLETS_DAY_DECIMAL = '-278522';
  FOUNDATION_DAY_DECIMAL = '-15055671';
  M_DECIMAL = '170141183460469231731687303715884105727';

  WHEAT = 1;
  BARLEY = 2;
  SALT = 3;
  BITTER = 4;
  RED = 5;

type
  TWorkCounts = record
    Action: TBigInt;
    Target: TBigInt;
    Distance: TBigInt;
    Connection: TBigInt;
    Direction: TBigInt;
  end;

  TStone = array[1..5] of TBigInt;
  TStoneTable = array[1..46] of TStone;
  THiddenDrops = array[1..7] of TBigInt;
  TVisibleDrops = array[1..46] of TBigInt;
  TBowls = array[1..6] of TBigInt;
  TBowlOrder = array[1..6] of Integer;

  TSauceResult = record
    Bowls: TBowls;
    OrderAtDrop46: TBowlOrder;
  end;

  TAnswerStream = record
    First: TBigInt;
    DirectionStep: Integer;
  end;

  TIntArray = array of Integer;

function NormativeM: TBigInt;
function FoundationDay: TBigInt;
function TabletsDay: TBigInt;
function NormativeSave(const X: TBigInt): TBigInt;
function DayCount(const Day: TBigInt): TBigInt;
function WorkCounts(const CalculationDay, TargetDay: TBigInt): TWorkCounts;
function BuildStones: TStoneTable;
function BuildHiddenDrops(const Counts: TWorkCounts; const Stones: TStoneTable): THiddenDrops;
function BuildVisibleDrops(const Counts: TWorkCounts; const Stones: TStoneTable; const Hidden: THiddenDrops): TVisibleDrops;
function BowlOrderFromNumber(OrderNumber: Integer): TBowlOrder;
function BowlOrderFromDrop(const DropValue: TBigInt): TBowlOrder;
function InitialBowls(const Counts: TWorkCounts): TBowls;
procedure ApplyVisibleDropsToBowls(var Bowls: TBowls; const Visible: TVisibleDrops; const Stones: TStoneTable; out OrderAtDrop46: TBowlOrder);
procedure PostStir12(var Bowls: TBowls);
function Sauce(const CalculationDay, TargetDay: TBigInt): TSauceResult;
function NextBowlInDrop46Order(const SauceResult: TSauceResult; QueriedBowlId: Integer): Integer;
function AskBowl(const SauceResult: TSauceResult; QueriedBowlId, Seal: Integer): TAnswerStream;
function AnswerAt(const Stream: TAnswerStream; const K: TBigInt): TBigInt;
function ChooseRankShort(const Stream: TAnswerStream; const N: TBigInt): TBigInt;
function ChooseRankWide(const Stream: TAnswerStream; const N: TBigInt): TBigInt;
function ChooseRank(const Stream: TAnswerStream; const N: TBigInt): TBigInt;
function FallingFactorial(N, K: Integer): TBigInt;
function UnrankDistinctIndices(MasterCount, K: Integer; const Rank1: TBigInt): TIntArray;

implementation

const
  HIDDEN_COEFF: array[1..7, 1..4] of Integer = (
    (3, 4, 6, 8),
    (5, 7, 10, 12),
    (7, 10, 14, 16),
    (9, 13, 18, 20),
    (11, 16, 22, 24),
    (13, 19, 26, 28),
    (15, 22, 30, 32)
  );

  HIDDEN_GRIND_STONE: array[1..7] of Integer = (
    WHEAT, BARLEY, SALT, BITTER, RED, WHEAT, BARLEY
  );

  VISIBLE_GRINDS: array[1..11, 1..5] of Integer = (
    (3, 5, 7, 11, WHEAT),
    (5, 7, 11, 13, BARLEY),
    (7, 11, 13, 17, SALT),
    (11, 13, 17, 19, BITTER),
    (13, 17, 19, 23, RED),
    (17, 19, 23, 29, WHEAT),
    (19, 23, 29, 31, BARLEY),
    (23, 29, 31, 37, SALT),
    (29, 31, 37, 41, BITTER),
    (31, 37, 41, 43, RED),
    (37, 41, 43, 47, WHEAT)
  );

  BOWL_PRIME: array[1..6] of Integer = (17, 19, 23, 29, 31, 37);
  BOWL_STIR_STONE_BY_POSITION: array[1..6] of Integer = (WHEAT, BARLEY, SALT, BITTER, RED, WHEAT);

function NormativeM: TBigInt;
begin
  Result := BigFromDecimal(M_DECIMAL);
end;

function FoundationDay: TBigInt;
begin
  Result := BigFromDecimal(FOUNDATION_DAY_DECIMAL);
end;

function TabletsDay: TBigInt;
begin
  Result := BigFromDecimal(TABLETS_DAY_DECIMAL);
end;

function NormativeSave(const X: TBigInt): TBigInt;
var
  M: TBigInt;
begin
  M := NormativeM;
  Result := BigAddInt64(BigRegularModPositive(BigSubtractInt64(X, 1), M), 1);
end;

function DayCount(const Day: TBigInt): TBigInt;
var
  F, Delta: TBigInt;
  C: Integer;
begin
  F := FoundationDay;
  C := BigCompare(Day, F);
  if C = 0 then
    Exit(BigOne);
  if C > 0 then
  begin
    Delta := BigSubtract(Day, F);
    Exit(BigAddInt64(BigMultiplyInt64(Delta, 2), 1));
  end;
  Delta := BigSubtract(F, Day);
  Result := BigMultiplyInt64(Delta, 2);
end;

function WorkCounts(const CalculationDay, TargetDay: TBigInt): TWorkCounts;
var
  Delta: TBigInt;
  C: Integer;
begin
  Result.Action := DayCount(CalculationDay);
  Result.Target := DayCount(TargetDay);
  Delta := BigAbs(BigSubtract(TargetDay, CalculationDay));
  Result.Distance := BigAddInt64(Delta, 1);
  Result.Connection := BigAdd(Result.Action, Result.Target);
  C := BigCompare(TargetDay, CalculationDay);
  if C < 0 then Result.Direction := BigFromInt64(1)
  else if C = 0 then Result.Direction := BigFromInt64(2)
  else Result.Direction := BigFromInt64(3);
end;

function BuildStones: TStoneTable;
var
  I: Integer;
  Old: TStone;
begin
  Result[1][WHEAT] := BigFromInt64(17);
  Result[1][BARLEY] := BigFromInt64(29);
  Result[1][SALT] := BigFromInt64(43);
  Result[1][BITTER] := BigFromInt64(71);
  Result[1][RED] := BigFromInt64(101);
  for I := 2 to 46 do
  begin
    Old := Result[I - 1];
    Result[I][WHEAT] := NormativeSave(BigAddInt64(BigAdd(BigSquare(Old[WHEAT]), BigMultiplyInt64(Old[BARLEY], 3)), I));
    Result[I][BARLEY] := NormativeSave(BigAdd(BigAdd(BigSquare(Old[BARLEY]), BigMultiplyInt64(Old[SALT], 5)), Old[WHEAT]));
    Result[I][SALT] := NormativeSave(BigAdd(BigAdd(BigSquare(Old[SALT]), BigMultiplyInt64(Old[BITTER], 7)), Old[BARLEY]));
    Result[I][BITTER] := NormativeSave(BigAdd(BigAdd(BigSquare(Old[BITTER]), BigMultiplyInt64(Old[RED], 11)), Old[SALT]));
    Result[I][RED] := NormativeSave(BigAdd(BigAdd(BigSquare(Old[RED]), BigMultiplyInt64(Old[WHEAT], 13)), Old[BITTER]));
  end;
end;

function BuildHiddenDrops(const Counts: TWorkCounts; const Stones: TStoneTable): THiddenDrops;
var
  K, G, Kind: Integer;
  X, OldX: TBigInt;
begin
  for K := 1 to 7 do
  begin
    X := BigClone(Counts.Action);
    X := BigAdd(X, BigMultiplyInt64(Counts.Target, HIDDEN_COEFF[K, 1]));
    X := BigAdd(X, BigMultiplyInt64(Counts.Distance, HIDDEN_COEFF[K, 2]));
    X := BigAdd(X, BigMultiplyInt64(Counts.Connection, HIDDEN_COEFF[K, 3]));
    X := BigAdd(X, BigMultiplyInt64(Counts.Direction, HIDDEN_COEFF[K, 4]));
    for Kind := WHEAT to RED do
      X := BigAdd(X, Stones[K][Kind]);
    X := NormativeSave(X);
    for G := 1 to 7 do
    begin
      OldX := X;
      X := BigSquare(OldX);
      X := BigAdd(X, BigMultiplyInt64(OldX, 3));
      X := BigAdd(X, Stones[K][HIDDEN_GRIND_STONE[G]]);
      X := BigAddInt64(X, G);
      X := NormativeSave(X);
    end;
    Result[K] := X;
  end;
end;

function TimelinePrior(const Visible: TVisibleDrops; const Hidden: THiddenDrops; I, Back: Integer): TBigInt;
var
  Slot, K: Integer;
begin
  Slot := I - Back;
  if Slot >= 1 then
    Exit(BigClone(Visible[Slot]));
  K := 1 - Slot;
  Result := BigClone(Hidden[K]);
end;

function BuildVisibleDrops(const Counts: TWorkCounts; const Stones: TStoneTable; const Hidden: THiddenDrops): TVisibleDrops;
var
  I, G: Integer;
  P1, P3, P7, X, OldX: TBigInt;
begin
  for I := 1 to 46 do
  begin
    P1 := TimelinePrior(Result, Hidden, I, 1);
    P3 := TimelinePrior(Result, Hidden, I, 3);
    P7 := TimelinePrior(Result, Hidden, I, 7);
    X := BigMultiply(Stones[I][WHEAT], Counts.Action);
    X := BigAdd(X, BigMultiply(Stones[I][BARLEY], Counts.Target));
    X := BigAdd(X, BigMultiply(Stones[I][SALT], Counts.Distance));
    X := BigAdd(X, BigMultiply(Stones[I][BITTER], Counts.Connection));
    X := BigAdd(X, BigMultiply(Stones[I][RED], Counts.Direction));
    X := BigAdd(X, P1);
    X := BigAdd(X, BigMultiplyInt64(P3, 3));
    X := BigAdd(X, BigMultiplyInt64(P7, 5));
    X := BigAddInt64(X, I);
    X := NormativeSave(X);
    for G := 1 to 11 do
    begin
      OldX := X;
      X := BigSquare(OldX);
      X := BigAdd(X, BigMultiplyInt64(OldX, VISIBLE_GRINDS[G, 1]));
      X := BigAdd(X, BigMultiplyInt64(P1, VISIBLE_GRINDS[G, 2]));
      X := BigAdd(X, BigMultiplyInt64(P3, VISIBLE_GRINDS[G, 3]));
      X := BigAdd(X, BigMultiplyInt64(P7, VISIBLE_GRINDS[G, 4]));
      X := BigAdd(X, Stones[I][VISIBLE_GRINDS[G, 5]]);
      X := NormativeSave(X);
    end;
    Result[I] := X;
  end;
end;

function FactorialSmall(N: Integer): Integer;
var
  I: Integer;
begin
  Result := 1;
  for I := 2 to N do Result := Result * I;
end;

function BowlOrderFromNumber(OrderNumber: Integer): TBowlOrder;
var
  Remaining: array[1..6] of Integer;
  RemainingCount, Position, SlotsLeft, BlockSize, Q, Rank0, I: Integer;
begin
  if (OrderNumber < 1) or (OrderNumber > 720) then
    raise ERangeError.Create('Número de ordem de taças fora do intervalo.');
  for I := 1 to 6 do Remaining[I] := I;
  RemainingCount := 6;
  Rank0 := OrderNumber - 1;
  Position := 1;
  for SlotsLeft := 6 downto 1 do
  begin
    BlockSize := FactorialSmall(SlotsLeft - 1);
    Q := Rank0 div BlockSize;
    Rank0 := Rank0 mod BlockSize;
    Result[Position] := Remaining[Q + 1];
    for I := Q + 1 to RemainingCount - 1 do
      Remaining[I] := Remaining[I + 1];
    Dec(RemainingCount);
    Inc(Position);
  end;
end;

function BowlOrderFromDrop(const DropValue: TBigInt): TBowlOrder;
var
  R: TBigInt;
  N: Integer;
begin
  R := BigRegularModPositive(BigSubtractInt64(DropValue, 1), BigFromInt64(720));
  N := Integer(BigToInt64Exact(R)) + 1;
  Result := BowlOrderFromNumber(N);
end;

function InitialBowls(const Counts: TWorkCounts): TBowls;
var
  BowlId: Integer;
  S: TBigInt;
begin
  for BowlId := 1 to 6 do
  begin
    S := BigClone(Counts.Action);
    S := BigAdd(S, BigMultiplyInt64(Counts.Target, BowlId));
    S := BigAdd(S, Counts.Distance);
    S := BigAdd(S, Counts.Connection);
    S := BigAdd(S, Counts.Direction);
    S := BigAddInt64(S, BOWL_PRIME[BowlId] * BOWL_PRIME[BowlId]);
    Result[BowlId] := NormativeSave(BigAddInt64(BigSquare(S), BowlId));
  end;
end;

function Wrap1(Position, Size: Integer): Integer;
begin
  Result := ((Position - 1) mod Size + Size) mod Size + 1;
end;

procedure ApplyVisibleDropsToBowls(var Bowls: TBowls; const Visible: TVisibleDrops; const Stones: TStoneTable; out OrderAtDrop46: TBowlOrder);
var
  I, Position, BowlId, PrevId, NextId: Integer;
  Order: TBowlOrder;
  Old, NextBowls: TBowls;
  Pour: array[1..6] of TBigInt;
  S, X: TBigInt;
begin
  for I := 1 to 46 do
  begin
    Order := BowlOrderFromDrop(Visible[I]);
    Old := Bowls;
    Pour[1] := NormativeSave(BigAddInt64(BigAdd(BigSquare(Visible[I]), BigMultiply(Stones[I][WHEAT], Old[Order[1]])), 3 * I));
    Pour[2] := NormativeSave(BigAddInt64(BigAdd(BigSquare(Visible[I]), BigMultiply(Stones[I][BARLEY], Old[Order[2]])), 5 * I));
    Pour[3] := NormativeSave(BigAddInt64(BigAdd(BigSquare(Visible[I]), BigMultiply(Stones[I][SALT], Old[Order[3]])), 7 * I));
    Pour[4] := BigZero;
    Pour[5] := BigZero;
    Pour[6] := BigZero;
    for Position := 1 to 6 do
    begin
      BowlId := Order[Position];
      PrevId := Order[Wrap1(Position - 1, 6)];
      NextId := Order[Wrap1(Position + 1, 6)];
      S := BigClone(Old[BowlId]);
      S := BigAdd(S, BigMultiplyInt64(Old[PrevId], 2));
      S := BigAdd(S, BigMultiplyInt64(Old[NextId], 3));
      S := BigAdd(S, Pour[Position]);
      S := BigAdd(S, Visible[I]);
      S := BigAdd(S, Stones[I][BOWL_STIR_STONE_BY_POSITION[Position]]);
      X := BigSquare(S);
      X := BigAdd(X, BigMultiplyInt64(BigMultiply(Old[PrevId], Old[NextId]), 5));
      X := BigAddInt64(X, I * Position);
      NextBowls[BowlId] := NormativeSave(X);
    end;
    Bowls := NextBowls;
    if I = 46 then OrderAtDrop46 := Order;
  end;
end;

procedure PostStir12(var Bowls: TBowls);
var
  Stir, Position, BowlId, PrevId, NextId, OrderNumber: Integer;
  Old, NextBowls: TBowls;
  SavedBowlSum, S, X: TBigInt;
  Order: TBowlOrder;
begin
  for Stir := 1 to 12 do
  begin
    Old := Bowls;
    SavedBowlSum := BigZero;
    for BowlId := 1 to 6 do
      SavedBowlSum := BigAdd(SavedBowlSum, Old[BowlId]);
    SavedBowlSum := NormativeSave(BigAddInt64(SavedBowlSum, 149 * Stir));
    OrderNumber := Integer(BigToInt64Exact(BigRegularModPositive(BigSubtractInt64(SavedBowlSum, 1), BigFromInt64(720)))) + 1;
    Order := BowlOrderFromNumber(OrderNumber);
    for Position := 1 to 6 do
    begin
      BowlId := Order[Position];
      PrevId := Order[Wrap1(Position - 1, 6)];
      NextId := Order[Wrap1(Position + 1, 6)];
      S := BigClone(Old[BowlId]);
      S := BigAdd(S, BigMultiplyInt64(Old[PrevId], 3));
      S := BigAdd(S, BigMultiplyInt64(Old[NextId], 5));
      S := BigAdd(S, SavedBowlSum);
      S := BigAddInt64(S, Stir + Position * Position);
      X := BigSquare(S);
      X := BigAdd(X, BigMultiplyInt64(BigMultiply(Old[PrevId], Old[NextId]), 7));
      NextBowls[BowlId] := NormativeSave(X);
    end;
    Bowls := NextBowls;
  end;
end;

function Sauce(const CalculationDay, TargetDay: TBigInt): TSauceResult;
var
  Counts: TWorkCounts;
  Stones: TStoneTable;
  Hidden: THiddenDrops;
  Visible: TVisibleDrops;
  Bowls: TBowls;
begin
  Counts := WorkCounts(CalculationDay, TargetDay);
  Stones := BuildStones;
  Hidden := BuildHiddenDrops(Counts, Stones);
  Visible := BuildVisibleDrops(Counts, Stones, Hidden);
  Bowls := InitialBowls(Counts);
  ApplyVisibleDropsToBowls(Bowls, Visible, Stones, Result.OrderAtDrop46);
  PostStir12(Bowls);
  Result.Bowls := Bowls;
end;

function NextBowlInDrop46Order(const SauceResult: TSauceResult; QueriedBowlId: Integer): Integer;
var
  P: Integer;
begin
  if (QueriedBowlId < 1) or (QueriedBowlId > 6) then
    raise ERangeError.Create('Identificador de taça fora do intervalo.');
  for P := 1 to 6 do
    if SauceResult.OrderAtDrop46[P] = QueriedBowlId then
      Exit(SauceResult.OrderAtDrop46[Wrap1(P + 1, 6)]);
  raise Exception.Create('Taça consultada não encontrada na ordem da gota 46.');
end;

function AskBowl(const SauceResult: TSauceResult; QueriedBowlId, Seal: Integer): TAnswerStream;
var
  NextId: Integer;
  X, DirectionNumber, R2: TBigInt;
begin
  NextId := NextBowlInDrop46Order(SauceResult, QueriedBowlId);
  X := BigAddInt64(SauceResult.Bowls[QueriedBowlId], Seal + 181);
  X := BigSquare(X);
  X := BigAdd(X, BigMultiplyInt64(SauceResult.Bowls[NextId], 179));
  X := BigAddInt64(X, Seal);
  Result.First := NormativeSave(X);

  DirectionNumber := BigAddInt64(Result.First, Seal + 1 + 193);
  DirectionNumber := BigSquare(DirectionNumber);
  DirectionNumber := BigAdd(DirectionNumber, BigMultiplyInt64(Result.First, 193));
  DirectionNumber := BigAdd(DirectionNumber, BigMultiplyInt64(SauceResult.Bowls[6], 197));
  DirectionNumber := NormativeSave(DirectionNumber);
  R2 := BigRegularModPositive(DirectionNumber, BigFromInt64(2));
  if BigToInt64Exact(R2) = 1 then Result.DirectionStep := 1 else Result.DirectionStep := -1;
end;

function AnswerAt(const Stream: TAnswerStream; const K: TBigInt): TBigInt;
var
  X, M: TBigInt;
begin
  M := NormativeM;
  X := BigSubtractInt64(Stream.First, 1);
  X := BigAdd(X, BigMultiplyInt64(K, Stream.DirectionStep));
  Result := BigAddInt64(BigRegularModPositive(X, M), 1);
end;

function ChooseRankShort(const Stream: TAnswerStream; const N: TBigInt): TBigInt;
var
  M, Q, Limit, K, X: TBigInt;
begin
  M := NormativeM;
  if (N.Sign <= 0) or (BigCompare(N, M) > 0) then
    raise ERangeError.Create('Escolha curta recebeu N inválido.');
  Q := BigFloorDivPositive(M, N);
  Limit := BigMultiply(Q, N);
  K := BigZero;
  while True do
  begin
    X := AnswerAt(Stream, K);
    if BigCompare(X, Limit) <= 0 then
      Exit(BigAddInt64(BigRegularModPositive(BigSubtractInt64(X, 1), N), 1));
    K := BigAddInt64(K, 1);
  end;
end;

function ChooseRankWide(const Stream: TAnswerStream; const N: TBigInt): TBigInt;
var
  M, Space, Wide, Weight, Digit, Limit, Q: TBigInt;
  Places, J: Integer;
begin
  M := NormativeM;
  if BigCompare(N, M) <= 0 then
    raise ERangeError.Create('Escolha larga recebeu N curto.');
  Places := 1;
  Space := BigClone(M);
  while BigCompare(Space, N) < 0 do
  begin
    Inc(Places);
    Space := BigMultiply(Space, M);
  end;
  Wide := BigOne;
  Weight := BigOne;
  for J := 0 to Places - 1 do
  begin
    Digit := BigSubtractInt64(AnswerAt(Stream, BigFromInt64(J)), 1);
    Wide := BigAdd(Wide, BigMultiply(Digit, Weight));
    Weight := BigMultiply(Weight, M);
  end;
  Q := BigFloorDivPositive(Space, N);
  Limit := BigMultiply(Q, N);
  while BigCompare(Wide, Limit) > 0 do
  begin
    Wide := BigAddInt64(Wide, Stream.DirectionStep);
    Wide := BigAddInt64(BigRegularModPositive(BigSubtractInt64(Wide, 1), Space), 1);
  end;
  Result := BigAddInt64(BigRegularModPositive(BigSubtractInt64(Wide, 1), N), 1);
end;

function ChooseRank(const Stream: TAnswerStream; const N: TBigInt): TBigInt;
begin
  if N.Sign <= 0 then
    raise ERangeError.Create('Escolha recebeu família vazia.');
  if BigCompare(N, NormativeM) <= 0 then
    Result := ChooseRankShort(Stream, N)
  else
    Result := ChooseRankWide(Stream, N);
end;

function FallingFactorial(N, K: Integer): TBigInt;
var
  J: Integer;
begin
  if (K < 0) or (K > N) then
    raise ERangeError.Create('Fatorial descendente fora do domínio.');
  Result := BigOne;
  for J := 0 to K - 1 do
    Result := BigMultiplyInt64(Result, N - J);
end;

function UnrankDistinctIndices(MasterCount, K: Integer; const Rank1: TBigInt): TIntArray;
var
  Remaining: TIntArray;
  Position, Candidate, I, ChosenIndex, RemainingCount, SuffixLength: Integer;
  R, Block: TBigInt;
begin
  if (K < 0) or (K > MasterCount) then
    raise ERangeError.Create('Comprimento de nomes distintos fora do domínio.');
  if (BigCompare(Rank1, BigOne) < 0) or (BigCompare(Rank1, FallingFactorial(MasterCount, K)) > 0) then
    raise ERangeError.Create('Rank de nomes distintos fora do domínio.');
  SetLength(Remaining, MasterCount);
  for I := 0 to MasterCount - 1 do Remaining[I] := I + 1;
  RemainingCount := MasterCount;
  SetLength(Result, K);
  R := BigClone(Rank1);
  for Position := 0 to K - 1 do
  begin
    SuffixLength := K - Position - 1;
    Block := FallingFactorial(RemainingCount - 1, SuffixLength);
    ChosenIndex := -1;
    for Candidate := 0 to RemainingCount - 1 do
    begin
      if BigCompare(R, Block) > 0 then
        R := BigSubtract(R, Block)
      else
      begin
        ChosenIndex := Candidate;
        Break;
      end;
    end;
    if ChosenIndex < 0 then
      raise Exception.Create('Falha interna no unrank de nomes distintos.');
    Result[Position] := Remaining[ChosenIndex];
    for I := ChosenIndex to RemainingCount - 2 do
      Remaining[I] := Remaining[I + 1];
    Dec(RemainingCount);
    SetLength(Remaining, RemainingCount);
  end;
end;

end.
