program stage09_stone_snapshot_probe;
{$mode objfpc}{$H+}
uses SysUtils, BigInt, PastafariCalendar, Stage09SeededLegacy;
var
  Values: TStoneSnapshotTable;
  Expected: TextFile;
  Line, Reference: string;
  Row, Kind: Integer;
  AnyMismatch: Boolean;
begin
  if ParamCount <> 2 then Halt(2);
  if (ParamStr(2) <> 'production') and (ParamStr(2) <> 'seeded-legacy') then Halt(2);
  AssignFile(Expected, ParamStr(1));
  Reset(Expected);
  ReadLn(Expected, Reference);
  if Reference <> 'i'#9'wheat'#9'barley'#9'salt'#9'bitter'#9'red' then Halt(2);
  WriteLn(Reference);
  if ParamStr(2) = 'production' then
    Values := StoneSnapshot
  else
    Values := StoneSnapshotSeededLegacy;
  AnyMismatch := False;
  for Row := 1 to 46 do
  begin
    if EOF(Expected) then Halt(2);
    ReadLn(Expected, Reference);
    Line := IntToStr(Row);
    for Kind := 1 to 5 do
      Line := Line + #9 + BigToDecimal(Values[Row][Kind]);
    WriteLn(Line);
    if Line <> Reference then AnyMismatch := True;
  end;
  if not EOF(Expected) then Halt(2);
  CloseFile(Expected);
  if AnyMismatch then Halt(1);
  Halt(0);
end.
