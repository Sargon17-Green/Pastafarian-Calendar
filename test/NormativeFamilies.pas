unit NormativeFamilies;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

interface

uses
  SysUtils, BigInt, NormativeOracle;

type
  TBoundedCompositionFamily = class
  private
    FTotal: Integer;
    FSlots: Integer;
    FLo: Integer;
    FHi: Integer;
    FKnown: array of Boolean;
    FMemo: array of TBigInt;
    function MemoIndex(Remaining, Slots: Integer): Integer;
    function CountSuffix(Remaining, Slots: Integer): TBigInt;
  public
    constructor Create(Total, Slots, LoValue, HiValue: Integer);
    function CountAll: TBigInt;
    function Unrank1(const Rank1: TBigInt): TIntArray;
  end;

  TCutletPartitionFamily = class
  private
    FG: Integer;
    FK: Integer;
    FRequired: Integer;
    FKnown: array of Boolean;
    FMemo: array of TBigInt;
    function MemoIndex(Remaining, Slots, Cumulative: Integer; HitBoundary: Boolean): Integer;
    function CountState(Remaining, Slots, Cumulative: Integer; HitBoundary: Boolean): TBigInt;
  public
    constructor Create(G, K, RequiredBoundaryOrMinusOne: Integer);
    function CountAll: TBigInt;
    function Unrank1(const Rank1: TBigInt): TIntArray;
  end;

  TWeavingFamily = class
  private type
    TMemoEntry = record
      Used: Boolean;
      Key: RawByteString;
      Value: TBigInt;
    end;
  private
    FLengths: TIntArray;
    FMemo: array of TMemoEntry;
    FMemoCount: Integer;
    function StateKey(const Remaining: TIntArray; OpenedUpTo, ClosedUpTo: Integer): RawByteString;
    function HashKey(const Key: RawByteString): UInt64;
    function FindSlot(const Key: RawByteString; ForInsert: Boolean): Integer;
    procedure GrowMemo;
    function MemoTryGet(const Key: RawByteString; out Value: TBigInt): Boolean;
    procedure MemoPut(const Key: RawByteString; const Value: TBigInt);
    function LegalMove(const Remaining: TIntArray; OpenedUpTo, ClosedUpTo, MonthId: Integer): Boolean;
    function CountState(const Remaining: TIntArray; OpenedUpTo, ClosedUpTo: Integer): TBigInt;
    function TotalDays: Integer;
  public
    constructor Create(const Lengths: TIntArray);
    function CountAll: TBigInt;
    function Unrank1(const Rank1: TBigInt): TIntArray;
  end;

implementation

function CloneIntArray(const A: TIntArray): TIntArray;
var
  I: Integer;
begin
  SetLength(Result, Length(A));
  for I := 0 to High(A) do Result[I] := A[I];
end;

constructor TBoundedCompositionFamily.Create(Total, Slots, LoValue, HiValue: Integer);
begin
  inherited Create;
  if (Total < 0) or (Slots < 0) or (LoValue < 0) or (HiValue < LoValue) then
    raise ERangeError.Create('Parâmetros inválidos para composição limitada.');
  FTotal := Total;
  FSlots := Slots;
  FLo := LoValue;
  FHi := HiValue;
  SetLength(FKnown, (FTotal + 1) * (FSlots + 1));
  SetLength(FMemo, Length(FKnown));
end;

function TBoundedCompositionFamily.MemoIndex(Remaining, Slots: Integer): Integer;
begin
  Result := Remaining * (FSlots + 1) + Slots;
end;

function TBoundedCompositionFamily.CountSuffix(Remaining, Slots: Integer): TBigInt;
var
  Idx, X: Integer;
begin
  if Slots = 0 then
  begin
    if Remaining = 0 then Exit(BigOne) else Exit(BigZero);
  end;
  if (Remaining < Slots * FLo) or (Remaining > Slots * FHi) then Exit(BigZero);
  if (Remaining < 0) or (Remaining > FTotal) then Exit(BigZero);
  Idx := MemoIndex(Remaining, Slots);
  if FKnown[Idx] then Exit(BigClone(FMemo[Idx]));
  Result := BigZero;
  for X := FLo to FHi do
    Result := BigAdd(Result, CountSuffix(Remaining - X, Slots - 1));
  FKnown[Idx] := True;
  FMemo[Idx] := BigClone(Result);
end;

function TBoundedCompositionFamily.CountAll: TBigInt;
begin
  Result := CountSuffix(FTotal, FSlots);
end;

function TBoundedCompositionFamily.Unrank1(const Rank1: TBigInt): TIntArray;
var
  R, Count: TBigInt;
  Remaining, Slots, Position, X: Integer;
  Chosen: Boolean;
begin
  Count := CountAll;
  if (BigCompare(Rank1, BigOne) < 0) or (BigCompare(Rank1, Count) > 0) then
    raise ERangeError.Create('Rank fora da composição limitada.');
  SetLength(Result, FSlots);
  R := BigClone(Rank1);
  Remaining := FTotal;
  Slots := FSlots;
  Position := 0;
  while Slots > 0 do
  begin
    Chosen := False;
    for X := FLo to FHi do
    begin
      Count := CountSuffix(Remaining - X, Slots - 1);
      if BigCompare(R, Count) > 0 then
        R := BigSubtract(R, Count)
      else
      begin
        Result[Position] := X;
        Remaining := Remaining - X;
        Dec(Slots);
        Inc(Position);
        Chosen := True;
        Break;
      end;
    end;
    if not Chosen then
      raise Exception.Create('Falha interna no unrank da composição limitada.');
  end;
end;

constructor TCutletPartitionFamily.Create(G, K, RequiredBoundaryOrMinusOne: Integer);
var
  Size: Int64;
begin
  inherited Create;
  if (G < 1) or (K < 1) or (K > G) then
    raise ERangeError.Create('Parâmetros inválidos para partição de costeletas.');
  if (RequiredBoundaryOrMinusOne <> -1) and
     ((RequiredBoundaryOrMinusOne <= 0) or (RequiredBoundaryOrMinusOne >= G)) then
    raise ERangeError.Create('Fronteira interna inválida para partição de costeletas.');
  FG := G;
  FK := K;
  FRequired := RequiredBoundaryOrMinusOne;
  Size := Int64(FG + 1) * Int64(FK + 1) * Int64(FG + 1) * 2;
  if Size > High(Integer) then
    raise ERangeError.Create('Tabela de memoização de partições demasiado grande.');
  SetLength(FKnown, Integer(Size));
  SetLength(FMemo, Integer(Size));
end;

function TCutletPartitionFamily.MemoIndex(Remaining, Slots, Cumulative: Integer; HitBoundary: Boolean): Integer;
var
  H: Integer;
begin
  if HitBoundary then H := 1 else H := 0;
  Result := (((Remaining * (FK + 1) + Slots) * (FG + 1) + Cumulative) * 2) + H;
end;

function TCutletPartitionFamily.CountState(Remaining, Slots, Cumulative: Integer; HitBoundary: Boolean): TBigInt;
var
  Idx, X, MaxX, NextCumulative: Integer;
  NextHit: Boolean;
begin
  if Slots = 0 then
  begin
    if Remaining <> 0 then Exit(BigZero);
    if FRequired = -1 then Exit(BigOne);
    if HitBoundary then Exit(BigOne) else Exit(BigZero);
  end;
  if Remaining < Slots then Exit(BigZero);
  if (Remaining < 0) or (Remaining > FG) or (Cumulative < 0) or (Cumulative > FG) then Exit(BigZero);
  Idx := MemoIndex(Remaining, Slots, Cumulative, HitBoundary);
  if FKnown[Idx] then Exit(BigClone(FMemo[Idx]));
  Result := BigZero;
  MaxX := Remaining - (Slots - 1);
  for X := 1 to MaxX do
  begin
    NextCumulative := Cumulative + X;
    NextHit := HitBoundary;
    if (FRequired <> -1) and not HitBoundary then
    begin
      if NextCumulative = FRequired then
        NextHit := True
      else if NextCumulative > FRequired then
        Continue;
    end;
    Result := BigAdd(Result, CountState(Remaining - X, Slots - 1, NextCumulative, NextHit));
  end;
  FKnown[Idx] := True;
  FMemo[Idx] := BigClone(Result);
end;

function TCutletPartitionFamily.CountAll: TBigInt;
begin
  Result := CountState(FG, FK, 0, False);
end;

function TCutletPartitionFamily.Unrank1(const Rank1: TBigInt): TIntArray;
var
  R, Block, Count: TBigInt;
  Remaining, Slots, Cumulative, Position, X, MaxX, NextCumulative: Integer;
  Hit, NextHit, Chosen: Boolean;
begin
  Count := CountAll;
  if (BigCompare(Rank1, BigOne) < 0) or (BigCompare(Rank1, Count) > 0) then
    raise ERangeError.Create('Rank fora da família de partições.');
  SetLength(Result, FK);
  R := BigClone(Rank1);
  Remaining := FG;
  Slots := FK;
  Cumulative := 0;
  Hit := False;
  Position := 0;
  while Slots > 0 do
  begin
    Chosen := False;
    MaxX := Remaining - (Slots - 1);
    for X := 1 to MaxX do
    begin
      NextCumulative := Cumulative + X;
      NextHit := Hit;
      if (FRequired <> -1) and not Hit then
      begin
        if NextCumulative = FRequired then
          NextHit := True
        else if NextCumulative > FRequired then
          Continue;
      end;
      Block := CountState(Remaining - X, Slots - 1, NextCumulative, NextHit);
      if BigCompare(R, Block) > 0 then
        R := BigSubtract(R, Block)
      else
      begin
        Result[Position] := X;
        Remaining := Remaining - X;
        Dec(Slots);
        Cumulative := NextCumulative;
        Hit := NextHit;
        Inc(Position);
        Chosen := True;
        Break;
      end;
    end;
    if not Chosen then
      raise Exception.Create('Falha interna no unrank da partição de costeletas.');
  end;
end;

constructor TWeavingFamily.Create(const Lengths: TIntArray);
var
  I: Integer;
begin
  inherited Create;
  if Length(Lengths) = 0 then
    raise ERangeError.Create('A tecelagem exige pelo menos um mês.');
  FLengths := CloneIntArray(Lengths);
  for I := 0 to High(FLengths) do
    if FLengths[I] <= 0 then
      raise ERangeError.Create('Comprimento de mês não positivo.');
  SetLength(FMemo, 1024);
  FMemoCount := 0;
end;

function TWeavingFamily.StateKey(const Remaining: TIntArray; OpenedUpTo, ClosedUpTo: Integer): RawByteString;
var
  I: Integer;
begin
  Result := RawByteString(IntToStr(OpenedUpTo) + '/' + IntToStr(ClosedUpTo) + ':');
  for I := 0 to High(Remaining) do
    Result := Result + RawByteString(IntToStr(Remaining[I]) + ',');
end;

function TWeavingFamily.HashKey(const Key: RawByteString): UInt64;
var
  I: Integer;
begin
  Result := UInt64($CBF29CE484222325);
  for I := 1 to Length(Key) do
  begin
    Result := Result xor Ord(Key[I]);
    Result := Result * UInt64(1099511628211);
  end;
end;

function TWeavingFamily.FindSlot(const Key: RawByteString; ForInsert: Boolean): Integer;
var
  Start, P: Integer;
begin
  if Length(FMemo) = 0 then
    raise Exception.Create('Mapa de memoização não inicializado.');
  Start := Integer(HashKey(Key) mod UInt64(Length(FMemo)));
  P := Start;
  repeat
    if not FMemo[P].Used then
    begin
      if ForInsert then Exit(P) else Exit(-1);
    end;
    if FMemo[P].Key = Key then Exit(P);
    Inc(P);
    if P = Length(FMemo) then P := 0;
  until P = Start;
  if ForInsert then
    raise Exception.Create('Mapa de memoização sem espaço.')
  else
    Result := -1;
end;

procedure TWeavingFamily.GrowMemo;
var
  Old: array of TMemoEntry;
  I, P: Integer;
begin
  Old := FMemo;
  SetLength(FMemo, Length(Old) * 2);
  for I := 0 to High(FMemo) do FMemo[I].Used := False;
  FMemoCount := 0;
  for I := 0 to High(Old) do
    if Old[I].Used then
    begin
      P := FindSlot(Old[I].Key, True);
      FMemo[P].Used := True;
      FMemo[P].Key := Old[I].Key;
      FMemo[P].Value := BigClone(Old[I].Value);
      Inc(FMemoCount);
    end;
end;

function TWeavingFamily.MemoTryGet(const Key: RawByteString; out Value: TBigInt): Boolean;
var
  P: Integer;
begin
  P := FindSlot(Key, False);
  Result := P >= 0;
  if Result then Value := BigClone(FMemo[P].Value);
end;

procedure TWeavingFamily.MemoPut(const Key: RawByteString; const Value: TBigInt);
var
  P: Integer;
begin
  if (FMemoCount + 1) * 10 >= Length(FMemo) * 7 then GrowMemo;
  P := FindSlot(Key, True);
  if not FMemo[P].Used then
  begin
    FMemo[P].Used := True;
    FMemo[P].Key := Key;
    Inc(FMemoCount);
  end;
  FMemo[P].Value := BigClone(Value);
end;

function TWeavingFamily.LegalMove(const Remaining: TIntArray; OpenedUpTo, ClosedUpTo, MonthId: Integer): Boolean;
var
  Index: Integer;
  AlreadyOpened, WillClose: Boolean;
begin
  Index := MonthId - 1;
  if (MonthId < 1) or (MonthId > Length(Remaining)) then Exit(False);
  if Remaining[Index] = 0 then Exit(False);
  AlreadyOpened := Remaining[Index] < FLengths[Index];
  if (not AlreadyOpened) and (MonthId <> OpenedUpTo + 1) then Exit(False);
  WillClose := Remaining[Index] = 1;
  if WillClose and (MonthId <> ClosedUpTo + 1) then Exit(False);
  Result := True;
end;

function TWeavingFamily.CountState(const Remaining: TIntArray; OpenedUpTo, ClosedUpTo: Integer): TBigInt;
var
  Key: RawByteString;
  I, J, NextOpened, NextClosed: Integer;
  Next: TIntArray;
  AllZero: Boolean;
  Cached: TBigInt;
begin
  AllZero := True;
  for I := 0 to High(Remaining) do
    if Remaining[I] <> 0 then
    begin
      AllZero := False;
      Break;
    end;
  if AllZero then Exit(BigOne);
  Key := StateKey(Remaining, OpenedUpTo, ClosedUpTo);
  if MemoTryGet(Key, Cached) then Exit(Cached);
  Result := BigZero;
  for J := 1 to Length(Remaining) do
    if LegalMove(Remaining, OpenedUpTo, ClosedUpTo, J) then
    begin
      Next := CloneIntArray(Remaining);
      NextOpened := OpenedUpTo;
      NextClosed := ClosedUpTo;
      if Next[J - 1] = FLengths[J - 1] then NextOpened := J;
      Dec(Next[J - 1]);
      if Next[J - 1] = 0 then NextClosed := J;
      Result := BigAdd(Result, CountState(Next, NextOpened, NextClosed));
    end;
  MemoPut(Key, Result);
end;

function TWeavingFamily.TotalDays: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(FLengths) do Inc(Result, FLengths[I]);
end;

function TWeavingFamily.CountAll: TBigInt;
var
  Remaining: TIntArray;
begin
  Remaining := CloneIntArray(FLengths);
  Result := CountState(Remaining, 0, 0);
end;

function TWeavingFamily.Unrank1(const Rank1: TBigInt): TIntArray;
var
  Count, R, Block: TBigInt;
  Remaining, Next: TIntArray;
  Opened, Closed, NextOpened, NextClosed, Position, J: Integer;
  Chosen: Boolean;
begin
  Count := CountAll;
  if (BigCompare(Rank1, BigOne) < 0) or (BigCompare(Rank1, Count) > 0) then
    raise ERangeError.Create('Rank fora da família de tecelagens.');
  Remaining := CloneIntArray(FLengths);
  SetLength(Result, TotalDays);
  R := BigClone(Rank1);
  Opened := 0;
  Closed := 0;
  for Position := 0 to High(Result) do
  begin
    Chosen := False;
    for J := 1 to Length(Remaining) do
      if LegalMove(Remaining, Opened, Closed, J) then
      begin
        Next := CloneIntArray(Remaining);
        NextOpened := Opened;
        NextClosed := Closed;
        if Next[J - 1] = FLengths[J - 1] then NextOpened := J;
        Dec(Next[J - 1]);
        if Next[J - 1] = 0 then NextClosed := J;
        Block := CountState(Next, NextOpened, NextClosed);
        if BigCompare(R, Block) > 0 then
          R := BigSubtract(R, Block)
        else
        begin
          Result[Position] := J;
          Remaining := Next;
          Opened := NextOpened;
          Closed := NextClosed;
          Chosen := True;
          Break;
        end;
      end;
    if not Chosen then
      raise Exception.Create('Falha interna no unrank da tecelagem.');
  end;
end;

end.
