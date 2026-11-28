unit Stage09SeededLegacy;
{$mode objfpc}{$H+}
interface
uses BigInt, PastafariCalendar;
function StoneSnapshotSeededLegacy: TStoneSnapshotTable;
implementation

function StoneSnapshotSeededLegacy: TStoneSnapshotTable;
const
  Seeds: array[1..5] of Integer = (17, 29, 43, 71, 101);
  Coefficients: array[1..5] of Integer = (3, 5, 7, 11, 13);
var
  Row, Kind, Neighbour: Integer;
  Current: TStoneSnapshot;
  Extra, Raw: TBigInt;
begin
  { Deliberate Stage08 seed: each cell reads the progressively updated row.
    The contract requires the immutable preceding row instead. }
  for Kind := 1 to 5 do
    Current[Kind] := BigFromInt64(Seeds[Kind]);
  Result[1] := Current;
  for Row := 2 to 46 do
  begin
    for Kind := 1 to 5 do
    begin
      Neighbour := (Kind mod 5) + 1;
      if Kind = 1 then
        Extra := BigFromInt64(Row)
      else
        Extra := Current[Kind - 1];
      Raw := BigAdd(BigAdd(BigSquare(Current[Kind]),
        BigMultiplyInt64(Current[Neighbour], Coefficients[Kind])), Extra);
      Current[Kind] := BigSave(Raw);
    end;
    Result[Row] := Current;
  end;
end;

end.
