program stage10_hidden_drop_order_probe;
{$mode objfpc}{$H+}
uses SysUtils, BigInt, Stage02WorkCounts, PastafariCalendar;
var
  Expected: TextFile;
  RefLine, Line, C, T, Tail: string;
  Pos1, Pos2, K, R, P: Integer;
  Trace: THiddenDropTrace;
  History: THiddenDropHistory;
  Mismatch: Boolean;
  Count: Integer;
begin
  if ParamCount <> 1 then Halt(2);
  AssignFile(Expected, ParamStr(1));
  Reset(Expected);
  if EOF(Expected) then Halt(2);
  ReadLn(Expected, RefLine);
  if Copy(RefLine,1,4) <> 'c'#9't'#9 then Halt(2);
  WriteLn(RefLine);
  Mismatch := False;
  Count := 0;
  while not EOF(Expected) do
  begin
    ReadLn(Expected, RefLine);
    Pos1 := Pos(#9, RefLine);
    if Pos1 = 0 then Halt(2);
    C := Copy(RefLine, 1, Pos1-1);
    Tail := Copy(RefLine, Pos1+1, Length(RefLine));
    Pos2 := Pos(#9, Tail);
    if Pos2 = 0 then Halt(2);
    T := Copy(Tail, 1, Pos2-1);
    History := HiddenDropHistory(ParseCanonicalDay(C), ParseCanonicalDay(T), Trace);
    Line := C + #9 + T;
    for K := 1 to 7 do
      for R := 0 to 7 do
        Line := Line + #9 + BigToDecimal(Trace[K][R]);
    for P := -6 to 0 do
      Line := Line + #9 + BigToDecimal(History[P]);
    WriteLn(Line);
    if Line <> RefLine then Mismatch := True;
    Inc(Count);
  end;
  CloseFile(Expected);
  if Count <> 100 then Halt(2);
  if Mismatch then Halt(1);
  Halt(0);
end.
