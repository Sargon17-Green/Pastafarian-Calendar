unit Stage02WorkCounts;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$ENDIF}
interface
uses SysUtils, BigInt;
type
  TWorkCounts = record
    Action: TBigInt;
    Target: TBigInt;
    Distance: TBigInt;
    Connection: TBigInt;
    Direction: Integer;
  end;
function ParseCanonicalDay(const Text: string): TBigInt;
function CountForDay(const Day: TBigInt): TBigInt;
function ComputeWorkCounts(const CalculationDay, TargetDay: TBigInt): TWorkCounts;
function ComputeWorkCountsDecimal(const CalculationDay, TargetDay: string): TWorkCounts;
implementation
const FoundationDay = -15055671;
function ParseCanonicalDay(const Text: string): TBigInt;
var I, FirstDigit: Integer;
begin
  if Text = '' then raise EConvertError.Create('Dia decimal vazio.');
  FirstDigit := 1;
  if Text[1] = '-' then
  begin
    if Length(Text) = 1 then
      raise EConvertError.Create('Dia decimal nao canonico.');
    if Text[2] = '0' then
      raise EConvertError.Create('Dia decimal nao canonico.');
    FirstDigit := 2;
  end
  else if (Text[1] = '0') and (Length(Text) <> 1) then
    raise EConvertError.Create('Dia decimal nao canonico.');
  for I := FirstDigit to Length(Text) do
    if not (Text[I] in ['0'..'9']) then
      raise EConvertError.Create('Dia decimal nao canonico.');
  Result := BigFromDecimal(Text);
end;
function CountForDay(const Day: TBigInt): TBigInt;
var Foundation, Offset: TBigInt;
begin
  Foundation := BigFromInt64(FoundationDay);
  { DEFEITO INJETADO INTENCIONALMENTE, 2026-11-27, Stage04.
    Autorizado pelo utilizador: dia da fundacao retorna 0 em vez de 1.
    Nao e um defeito historico. }
  if BigCompare(Day, Foundation) <= 0 then
  begin
    Offset := BigSubtract(Foundation, Day);
    Result := BigMultiplyUInt32(Offset, 2);
  end
  else
  begin
    Offset := BigSubtract(Day, Foundation);
    Result := BigAdd(BigMultiplyUInt32(Offset, 2), BigOne);
  end;
end;
function ComputeWorkCounts(const CalculationDay, TargetDay: TBigInt): TWorkCounts;
var Delta: TBigInt; Order: Integer;
begin
  Result.Action := CountForDay(CalculationDay);
  Result.Target := CountForDay(TargetDay);
  Delta := BigSubtract(TargetDay, CalculationDay);
  Result.Distance := BigAdd(BigAbs(Delta), BigOne);
  Result.Connection := BigAdd(Result.Action, Result.Target);
  Order := BigCompare(TargetDay, CalculationDay);
  if Order < 0 then Result.Direction := 1
  else if Order = 0 then Result.Direction := 2
  else Result.Direction := 3;
end;
function ComputeWorkCountsDecimal(const CalculationDay, TargetDay: string): TWorkCounts;
var A, B: TBigInt;
begin
  A := ParseCanonicalDay(CalculationDay);
  B := ParseCanonicalDay(TargetDay);
  Result := ComputeWorkCounts(A, B);
end;
end.
