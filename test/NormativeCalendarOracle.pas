unit NormativeCalendarOracle;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

interface

uses
  SysUtils, BigInt, NormativeOracle, NormativeFamilies;

const
  GATE_GAP_MIN = 42;
  GATE_GAP_MAX = 963;
  YEAR_MIN_DAYS = 252;
  YEAR_MAX_DAYS = 5778;
  MIN_CUTLETS = 6;
  MAX_CUTLETS = 17;
  MIN_MONTHS = 3;
  MAX_MONTHS = 47;
  MIN_MONTH_DAYS = 4;
  MAX_MONTH_DAYS = 123;

  SEAL_GATE_GAP = 1;
  SEAL_YEAR_5000 = 10;
  SEAL_NEXT_YEAR = 11;
  SEAL_PREVIOUS_YEAR = 12;
  SEAL_CUTLET_COUNT = 20;
  SEAL_CUTLET_PARTITION = 21;
  SEAL_CUTLET_NAMES = 22;
  SEAL_MONTH_COUNT = 30;
  SEAL_MONTH_LENGTHS = 31;
  SEAL_MONTH_WEAVING = 32;
  SEAL_MONTH_NAMES = 33;

type
  TInt64Array = array of Int64;

  TYear = record
    Number: TBigInt;
    OpenGateIndex: Int64;
    CloseGateIndex: Int64;
    OpenGateDay: TBigInt;
    CloseGateDay: TBigInt;
  end;

  TCutlet = record
    NameCanonicalIndex: Integer;
    OpenGateIndex: Int64;
    CloseGateIndex: Int64;
    FirstDay: TBigInt;
    LastDay: TBigInt;
  end;

  TCutletArray = array of TCutlet;

  TYearStructure = record
    CutletCount: Integer;
    CutletPartition: TIntArray;
    CutletNameIndices: TIntArray;
    Cutlets: TCutletArray;
    MonthCount: Integer;
    MonthLengths: TIntArray;
    MonthWeaving: TIntArray;
    MonthNameIndices: TIntArray;
  end;

  TCalendarResult = record
    YearNumber: TBigInt;
    CutletCanonicalIndex: Integer;
    DayInCutlet: Integer;
    MonthCanonicalIndex: Integer;
    DayInMonth: Integer;
  end;

  TGateCache = class
  private
    FPositive: array of TBigInt;
    FNegative: array of TBigInt;
    function PositiveGateGap(N: Int64): Integer;
    function NegativeGateGap(N: Int64): Integer;
  public
    constructor Create;
    function MinKnownIndex: Int64;
    function MaxKnownIndex: Int64;
    procedure EnsureIndex(K: Int64);
    function Gate(K: Int64): TBigInt;
    procedure EnsureCover(const LowDay, HighDay: TBigInt);
    function GateIndexAtOrBefore(const Day: TBigInt): Int64;
    function GateIndexAtOrAfter(const Day: TBigInt): Int64;
    function ExactGateIndex(const Day: TBigInt; out Index: Int64): Boolean;
  end;

  TNormativeCalendar = class
  private
    FGates: TGateCache;
    function YearLength(OpenIndex, CloseIndex: Int64): Integer;
    function ValidYearPair(OpenIndex, CloseIndex: Int64): Boolean;
    function Year5000(const CalculationDay: TBigInt): TYear;
    function NextYear(const CalculationDay: TBigInt; const KnownYear: TYear): TYear;
    function PreviousYear(const CalculationDay: TBigInt; const KnownYear: TYear): TYear;
    function FindTargetYear(const CalculationDay, TargetDay: TBigInt): TYear;
    function BuildYearStructure(const CalculationDay: TBigInt; const YearValue: TYear): TYearStructure;
  public
    constructor Create;
    destructor Destroy; override;
    function CalendarDate(const CalculationDay, TargetDay: TBigInt): TCalendarResult;
    property Gates: TGateCache read FGates;
  end;

implementation

type
  TYearPair = record
    OpenIndex: Int64;
    CloseIndex: Int64;
  end;
  TYearPairArray = array of TYearPair;

function CloneIntArrayLocal(const A: TIntArray): TIntArray;
var
  I: Integer;
begin
  SetLength(Result, Length(A));
  for I := 0 to High(A) do Result[I] := A[I];
end;

function BigDifferenceToInteger(const A, B: TBigInt): Integer;
var
  D: TBigInt;
  V: Int64;
begin
  D := BigSubtract(A, B);
  V := BigToInt64Exact(D);
  if (V < Low(Integer)) or (V > High(Integer)) then
    raise ERangeError.Create('Diferença de dias fora do intervalo interno.');
  Result := Integer(V);
end;

constructor TGateCache.Create;
begin
  inherited Create;
  SetLength(FPositive, 1);
  SetLength(FNegative, 1);
  FPositive[0] := FoundationDay;
  FNegative[0] := FoundationDay;
end;

function TGateCache.MinKnownIndex: Int64;
begin
  Result := -(Length(FNegative) - 1);
end;

function TGateCache.MaxKnownIndex: Int64;
begin
  Result := Length(FPositive) - 1;
end;

function TGateCache.PositiveGateGap(N: Int64): Integer;
var
  R: TSauceResult;
  S: TAnswerStream;
  Rank: TBigInt;
begin
  if N < 1 then raise ERangeError.Create('Índice positivo de intervalo de portal inválido.');
  R := Sauce(FoundationDay, BigAddInt64(FoundationDay, N));
  S := AskBowl(R, 1, SEAL_GATE_GAP);
  Rank := ChooseRank(S, BigFromInt64(922));
  Result := 41 + Integer(BigToInt64Exact(Rank));
end;

function TGateCache.NegativeGateGap(N: Int64): Integer;
var
  R: TSauceResult;
  S: TAnswerStream;
  Rank: TBigInt;
begin
  if N < 1 then raise ERangeError.Create('Índice negativo de intervalo de portal inválido.');
  R := Sauce(FoundationDay, BigSubtractInt64(FoundationDay, N));
  S := AskBowl(R, 1, SEAL_GATE_GAP);
  Rank := ChooseRank(S, BigFromInt64(922));
  Result := 41 + Integer(BigToInt64Exact(Rank));
end;

procedure TGateCache.EnsureIndex(K: Int64);
var
  N: Int64;
  Gap: Integer;
begin
  if K >= 0 then
  begin
    if K > High(Integer) - 1 then
      raise ERangeError.Create('Índice de portal excede a capacidade de materialização local.');
    N := Length(FPositive);
    while N <= K do
    begin
      Gap := PositiveGateGap(N);
      SetLength(FPositive, N + 1);
      FPositive[N] := BigAddInt64(FPositive[N - 1], Gap);
      Inc(N);
    end;
  end
  else
  begin
    if -K > High(Integer) - 1 then
      raise ERangeError.Create('Índice de portal excede a capacidade de materialização local.');
    N := Length(FNegative);
    while N <= -K do
    begin
      Gap := NegativeGateGap(N);
      SetLength(FNegative, N + 1);
      FNegative[N] := BigSubtractInt64(FNegative[N - 1], Gap);
      Inc(N);
    end;
  end;
end;

function TGateCache.Gate(K: Int64): TBigInt;
begin
  EnsureIndex(K);
  if K >= 0 then Result := BigClone(FPositive[K])
  else Result := BigClone(FNegative[-K]);
end;

procedure TGateCache.EnsureCover(const LowDay, HighDay: TBigInt);
var
  K: Int64;
begin
  if BigCompare(LowDay, HighDay) > 0 then
    raise ERangeError.Create('Intervalo de cobertura dos portais invertido.');
  while BigCompare(Gate(MinKnownIndex), LowDay) > 0 do
  begin
    K := MinKnownIndex - 1;
    EnsureIndex(K);
  end;
  while BigCompare(Gate(MaxKnownIndex), HighDay) < 0 do
  begin
    K := MaxKnownIndex + 1;
    EnsureIndex(K);
  end;
end;

function TGateCache.GateIndexAtOrBefore(const Day: TBigInt): Int64;
var
  Lo, Hi, Mid: Int64;
begin
  EnsureCover(Day, Day);
  Lo := MinKnownIndex;
  Hi := MaxKnownIndex;
  while Lo < Hi do
  begin
    Mid := Lo + (Hi - Lo + 1) div 2;
    if BigCompare(Gate(Mid), Day) <= 0 then Lo := Mid else Hi := Mid - 1;
  end;
  Result := Lo;
end;

function TGateCache.GateIndexAtOrAfter(const Day: TBigInt): Int64;
var
  I: Int64;
begin
  I := GateIndexAtOrBefore(Day);
  if BigCompare(Gate(I), Day) = 0 then Exit(I);
  EnsureIndex(I + 1);
  Result := I + 1;
end;

function TGateCache.ExactGateIndex(const Day: TBigInt; out Index: Int64): Boolean;
begin
  Index := GateIndexAtOrBefore(Day);
  Result := BigCompare(Gate(Index), Day) = 0;
end;

constructor TNormativeCalendar.Create;
begin
  inherited Create;
  FGates := TGateCache.Create;
end;

destructor TNormativeCalendar.Destroy;
begin
  FGates.Free;
  inherited Destroy;
end;

function TNormativeCalendar.YearLength(OpenIndex, CloseIndex: Int64): Integer;
begin
  Result := BigDifferenceToInteger(FGates.Gate(CloseIndex), FGates.Gate(OpenIndex));
end;

function TNormativeCalendar.ValidYearPair(OpenIndex, CloseIndex: Int64): Boolean;
var
  L: Integer;
begin
  if CloseIndex - OpenIndex < 6 then Exit(False);
  L := YearLength(OpenIndex, CloseIndex);
  Result := (L >= YEAR_MIN_DAYS) and (L <= YEAR_MAX_DAYS);
end;

procedure AppendYearPair(var A: TYearPairArray; OpenIndex, CloseIndex: Int64);
var
  N: Integer;
begin
  N := Length(A);
  SetLength(A, N + 1);
  A[N].OpenIndex := OpenIndex;
  A[N].CloseIndex := CloseIndex;
end;

function PairComesAfter(const Gates: TGateCache; const A, B: TYearPair): Boolean;
var
  LA, LB: Integer;
begin
  LA := BigDifferenceToInteger(Gates.Gate(A.CloseIndex), Gates.Gate(A.OpenIndex));
  LB := BigDifferenceToInteger(Gates.Gate(B.CloseIndex), Gates.Gate(B.OpenIndex));
  if LA <> LB then Exit(LA > LB);
  Result := BigCompare(Gates.Gate(A.OpenIndex), Gates.Gate(B.OpenIndex)) > 0;
end;

procedure SortYearPairs(const Gates: TGateCache; var A: TYearPairArray);
var
  I, J: Integer;
  Key: TYearPair;
begin
  for I := 1 to High(A) do
  begin
    Key := A[I];
    J := I - 1;
    while (J >= 0) and PairComesAfter(Gates, A[J], Key) do
    begin
      A[J + 1] := A[J];
      Dec(J);
    end;
    A[J + 1] := Key;
  end;
end;

function TNormativeCalendar.Year5000(const CalculationDay: TBigInt): TYear;
var
  LowDay, HighDay: TBigInt;
  I, J: Int64;
  Candidates: TYearPairArray;
  R: TSauceResult;
  A: TAnswerStream;
  Rank: Integer;
  P: TYearPair;
begin
  LowDay := BigSubtractInt64(CalculationDay, YEAR_MAX_DAYS);
  HighDay := BigAddInt64(CalculationDay, YEAR_MAX_DAYS);
  FGates.EnsureCover(LowDay, HighDay);
  SetLength(Candidates, 0);
  I := FGates.MinKnownIndex;
  while I < FGates.MaxKnownIndex do
  begin
    J := I + 6;
    while J <= FGates.MaxKnownIndex do
    begin
      if YearLength(I, J) > YEAR_MAX_DAYS then Break;
      if ValidYearPair(I, J) and
         (BigCompare(FGates.Gate(I), CalculationDay) < 0) and
         (BigCompare(CalculationDay, FGates.Gate(J)) <= 0) then
        AppendYearPair(Candidates, I, J);
      Inc(J);
    end;
    Inc(I);
  end;
  if Length(Candidates) = 0 then
    raise Exception.Create('Nenhum candidato para o ano 5000.');
  SortYearPairs(FGates, Candidates);
  R := Sauce(CalculationDay, CalculationDay);
  A := AskBowl(R, 1, SEAL_YEAR_5000);
  Rank := Integer(BigToInt64Exact(ChooseRank(A, BigFromInt64(Length(Candidates))))) - 1;
  P := Candidates[Rank];
  Result.Number := BigFromInt64(5000);
  Result.OpenGateIndex := P.OpenIndex;
  Result.CloseGateIndex := P.CloseIndex;
  Result.OpenGateDay := FGates.Gate(P.OpenIndex);
  Result.CloseGateDay := FGates.Gate(P.CloseIndex);
end;

procedure AppendInt64(var A: TInt64Array; V: Int64);
var
  N: Integer;
begin
  N := Length(A);
  SetLength(A, N + 1);
  A[N] := V;
end;

procedure StableSortGateCandidatesByLength(const Gates: TGateCache; FixedIndex: Int64; IsNext: Boolean; var A: TInt64Array);
var
  I, J: Integer;
  Key: Int64;
  LK, LJ: Integer;
begin
  for I := 1 to High(A) do
  begin
    Key := A[I];
    if IsNext then LK := BigDifferenceToInteger(Gates.Gate(Key), Gates.Gate(FixedIndex))
    else LK := BigDifferenceToInteger(Gates.Gate(FixedIndex), Gates.Gate(Key));
    J := I - 1;
    while J >= 0 do
    begin
      if IsNext then LJ := BigDifferenceToInteger(Gates.Gate(A[J]), Gates.Gate(FixedIndex))
      else LJ := BigDifferenceToInteger(Gates.Gate(FixedIndex), Gates.Gate(A[J]));
      if LJ <= LK then Break;
      A[J + 1] := A[J];
      Dec(J);
    end;
    A[J + 1] := Key;
  end;
end;

function TNormativeCalendar.NextYear(const CalculationDay: TBigInt; const KnownYear: TYear): TYear;
var
  OpenIndex, CloseIndex: Int64;
  Candidates: TInt64Array;
  R: TSauceResult;
  A: TAnswerStream;
  Rank: Integer;
begin
  OpenIndex := KnownYear.CloseGateIndex;
  FGates.EnsureCover(FGates.Gate(OpenIndex), BigAddInt64(FGates.Gate(OpenIndex), YEAR_MAX_DAYS));
  SetLength(Candidates, 0);
  CloseIndex := OpenIndex + 1;
  while True do
  begin
    FGates.EnsureIndex(CloseIndex);
    if YearLength(OpenIndex, CloseIndex) > YEAR_MAX_DAYS then Break;
    if ValidYearPair(OpenIndex, CloseIndex) then AppendInt64(Candidates, CloseIndex);
    Inc(CloseIndex);
  end;
  StableSortGateCandidatesByLength(FGates, OpenIndex, True, Candidates);
  R := Sauce(CalculationDay, FGates.Gate(OpenIndex));
  A := AskBowl(R, 1, SEAL_NEXT_YEAR);
  Rank := Integer(BigToInt64Exact(ChooseRank(A, BigFromInt64(Length(Candidates))))) - 1;
  CloseIndex := Candidates[Rank];
  Result.Number := BigAddInt64(KnownYear.Number, 1);
  Result.OpenGateIndex := OpenIndex;
  Result.CloseGateIndex := CloseIndex;
  Result.OpenGateDay := FGates.Gate(OpenIndex);
  Result.CloseGateDay := FGates.Gate(CloseIndex);
end;

function TNormativeCalendar.PreviousYear(const CalculationDay: TBigInt; const KnownYear: TYear): TYear;
var
  CloseIndex, OpenIndex: Int64;
  Candidates: TInt64Array;
  R: TSauceResult;
  A: TAnswerStream;
  Rank: Integer;
begin
  CloseIndex := KnownYear.OpenGateIndex;
  FGates.EnsureCover(BigSubtractInt64(FGates.Gate(CloseIndex), YEAR_MAX_DAYS), FGates.Gate(CloseIndex));
  SetLength(Candidates, 0);
  OpenIndex := CloseIndex - 1;
  while True do
  begin
    FGates.EnsureIndex(OpenIndex);
    if YearLength(OpenIndex, CloseIndex) > YEAR_MAX_DAYS then Break;
    if ValidYearPair(OpenIndex, CloseIndex) then AppendInt64(Candidates, OpenIndex);
    Dec(OpenIndex);
  end;
  StableSortGateCandidatesByLength(FGates, CloseIndex, False, Candidates);
  R := Sauce(CalculationDay, FGates.Gate(CloseIndex));
  A := AskBowl(R, 1, SEAL_PREVIOUS_YEAR);
  Rank := Integer(BigToInt64Exact(ChooseRank(A, BigFromInt64(Length(Candidates))))) - 1;
  OpenIndex := Candidates[Rank];
  Result.Number := BigSubtractInt64(KnownYear.Number, 1);
  Result.OpenGateIndex := OpenIndex;
  Result.CloseGateIndex := CloseIndex;
  Result.OpenGateDay := FGates.Gate(OpenIndex);
  Result.CloseGateDay := FGates.Gate(CloseIndex);
end;

function TNormativeCalendar.FindTargetYear(const CalculationDay, TargetDay: TBigInt): TYear;
begin
  Result := Year5000(CalculationDay);
  while BigCompare(TargetDay, Result.CloseGateDay) > 0 do
    Result := NextYear(CalculationDay, Result);
  while BigCompare(TargetDay, Result.OpenGateDay) <= 0 do
    Result := PreviousYear(CalculationDay, Result);
  if not ((BigCompare(Result.OpenGateDay, TargetDay) < 0) and
          (BigCompare(TargetDay, Result.CloseGateDay) <= 0)) then
    raise Exception.Create('O ano encontrado não contém o dia alvo no intervalo (aberto, fechado].');
end;

function CeilDivInt(A, B: Integer): Integer;
begin
  if (A < 0) or (B < 1) then raise ERangeError.Create('ceilDiv inteiro fora do domínio.');
  Result := (A + B - 1) div B;
end;

function TNormativeCalendar.BuildYearStructure(const CalculationDay: TBigInt; const YearValue: TYear): TYearStructure;
var
  R: TSauceResult;
  A: TAnswerStream;
  GapCount, K, N, I, RequiredBoundary, MonthCount, L, LowM, HighM: Integer;
  PossibleK: TIntArray;
  Rank: TBigInt;
  ExactIndex: Int64;
  PartitionFamily: TCutletPartitionFamily;
  MonthFamily: TBoundedCompositionFamily;
  WeaveFamily: TWeavingFamily;
  CursorGate, CloseGate: Int64;
begin
  R := Sauce(CalculationDay, BigAddInt64(YearValue.OpenGateDay, 1));

  GapCount := Integer(YearValue.CloseGateIndex - YearValue.OpenGateIndex);
  SetLength(PossibleK, 0);
  for K := MIN_CUTLETS to MAX_CUTLETS do
    if K <= GapCount then
    begin
      N := Length(PossibleK);
      SetLength(PossibleK, N + 1);
      PossibleK[N] := K;
    end;
  A := AskBowl(R, 2, SEAL_CUTLET_COUNT);
  Rank := ChooseRank(A, BigFromInt64(Length(PossibleK)));
  Result.CutletCount := PossibleK[Integer(BigToInt64Exact(Rank)) - 1];

  RequiredBoundary := -1;
  if FGates.ExactGateIndex(CalculationDay, ExactIndex) and
     (ExactIndex > YearValue.OpenGateIndex) and (ExactIndex < YearValue.CloseGateIndex) then
    RequiredBoundary := Integer(ExactIndex - YearValue.OpenGateIndex);

  PartitionFamily := TCutletPartitionFamily.Create(GapCount, Result.CutletCount, RequiredBoundary);
  try
    A := AskBowl(R, 2, SEAL_CUTLET_PARTITION);
    Rank := ChooseRank(A, PartitionFamily.CountAll);
    Result.CutletPartition := PartitionFamily.Unrank1(Rank);
  finally
    PartitionFamily.Free;
  end;

  A := AskBowl(R, 5, SEAL_CUTLET_NAMES);
  Rank := ChooseRank(A, FallingFactorial(17, Result.CutletCount));
  Result.CutletNameIndices := UnrankDistinctIndices(17, Result.CutletCount, Rank);

  SetLength(Result.Cutlets, Result.CutletCount);
  CursorGate := YearValue.OpenGateIndex;
  for I := 0 to Result.CutletCount - 1 do
  begin
    CloseGate := CursorGate + Result.CutletPartition[I];
    Result.Cutlets[I].NameCanonicalIndex := Result.CutletNameIndices[I];
    Result.Cutlets[I].OpenGateIndex := CursorGate;
    Result.Cutlets[I].CloseGateIndex := CloseGate;
    Result.Cutlets[I].FirstDay := BigAddInt64(FGates.Gate(CursorGate), 1);
    Result.Cutlets[I].LastDay := FGates.Gate(CloseGate);
    CursorGate := CloseGate;
  end;

  L := BigDifferenceToInteger(YearValue.CloseGateDay, YearValue.OpenGateDay);
  LowM := CeilDivInt(L, MAX_MONTH_DAYS);
  HighM := L div MIN_MONTH_DAYS;
  if HighM > MAX_MONTHS then HighM := MAX_MONTHS;
  if (LowM < MIN_MONTHS) or (LowM > HighM) or (HighM > MAX_MONTHS) then
    raise Exception.Create('Limites normativos do número de meses inconsistentes.');
  A := AskBowl(R, 3, SEAL_MONTH_COUNT);
  Rank := ChooseRank(A, BigFromInt64(HighM - LowM + 1));
  MonthCount := LowM + Integer(BigToInt64Exact(Rank)) - 1;
  Result.MonthCount := MonthCount;

  MonthFamily := TBoundedCompositionFamily.Create(L, MonthCount, MIN_MONTH_DAYS, MAX_MONTH_DAYS);
  try
    A := AskBowl(R, 3, SEAL_MONTH_LENGTHS);
    Rank := ChooseRank(A, MonthFamily.CountAll);
    Result.MonthLengths := MonthFamily.Unrank1(Rank);
  finally
    MonthFamily.Free;
  end;

  WeaveFamily := TWeavingFamily.Create(Result.MonthLengths);
  try
    A := AskBowl(R, 4, SEAL_MONTH_WEAVING);
    Rank := ChooseRank(A, WeaveFamily.CountAll);
    Result.MonthWeaving := WeaveFamily.Unrank1(Rank);
  finally
    WeaveFamily.Free;
  end;

  A := AskBowl(R, 5, SEAL_MONTH_NAMES);
  Rank := ChooseRank(A, FallingFactorial(47, MonthCount));
  Result.MonthNameIndices := UnrankDistinctIndices(47, MonthCount, Rank);
end;

function TNormativeCalendar.CalendarDate(const CalculationDay, TargetDay: TBigInt): TCalendarResult;
var
  Y: TYear;
  S: TYearStructure;
  I, ChosenCutlet, Offset0, MonthId, P: Integer;
begin
  Y := FindTargetYear(CalculationDay, TargetDay);
  S := BuildYearStructure(CalculationDay, Y);
  ChosenCutlet := -1;
  for I := 0 to High(S.Cutlets) do
    if (BigCompare(S.Cutlets[I].FirstDay, TargetDay) <= 0) and
       (BigCompare(TargetDay, S.Cutlets[I].LastDay) <= 0) then
    begin
      ChosenCutlet := I;
      Break;
    end;
  if ChosenCutlet < 0 then
    raise Exception.Create('Nenhuma costeleta contém o dia alvo.');
  Result.YearNumber := BigClone(Y.Number);
  Result.CutletCanonicalIndex := S.Cutlets[ChosenCutlet].NameCanonicalIndex;
  Result.DayInCutlet := BigDifferenceToInteger(TargetDay, S.Cutlets[ChosenCutlet].FirstDay) + 1;

  Offset0 := BigDifferenceToInteger(TargetDay, BigAddInt64(Y.OpenGateDay, 1));
  if (Offset0 < 0) or (Offset0 > High(S.MonthWeaving)) then
    raise Exception.Create('Deslocamento do dia alvo fora da tecelagem anual.');
  MonthId := S.MonthWeaving[Offset0];
  Result.MonthCanonicalIndex := S.MonthNameIndices[MonthId - 1];
  Result.DayInMonth := 0;
  for P := 0 to Offset0 do
    if S.MonthWeaving[P] = MonthId then Inc(Result.DayInMonth);
end;

end.
