unit Stage07SeededLegacy;
{$MODE OBJFPC}{$H+}
interface
uses BigInt, Stage02WorkCounts;
{ Test-only snapshot of the authorized Stage06 fault; not historical. }
function ComputeWorkCountsSeededLegacy(const CalculationDay, TargetDay: TBigInt): TWorkCounts;
implementation
function ComputeWorkCountsSeededLegacy(const CalculationDay, TargetDay: TBigInt): TWorkCounts;
var Delta: TBigInt; Order: Integer;
begin
  Result.Action := CountForDay(CalculationDay);
  Result.Target := CountForDay(TargetDay);
  Delta := BigSubtract(TargetDay, CalculationDay);
  { DEFEITO INJETADO INTENCIONALMENTE, Stage06, 2026-11-27.
    Autorizado pelo utilizador; fator 2 incorreto. Nao historico. }
  Result.Distance := BigAdd(BigMultiplyUInt32(BigAbs(Delta), 2), BigOne);
  Result.Connection := BigAdd(Result.Action, Result.Target);
  Order := BigCompare(TargetDay, CalculationDay);
  if Order < 0 then Result.Direction := 1
  else if Order = 0 then Result.Direction := 2
  else Result.Direction := 3;
end;
end.
