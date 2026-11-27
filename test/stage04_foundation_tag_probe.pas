program stage04_foundation_tag_probe;
{$MODE OBJFPC}{$H+}
uses SysUtils, Classes, BigInt, Stage02WorkCounts, PastafariCalendar, MonsterBootstrap;
const Header = 'day'#9'tag'#9'inverse_day'#9'side';
var Lines, Fields: TStringList;
    I, Cases, Mismatches: Integer;
    D: TBigInt;
    A, B: TWorkCounts;
    C: TMonsterContext;
    DirectTag, A1, A2, B1, B2, Expected: string;
begin
  if ParamCount <> 1 then Halt(2);
  Cases := 0; Mismatches := 0;
  Lines := TStringList.Create;
  Fields := TStringList.Create;
  try
    Lines.LoadFromFile(ParamStr(1));
    if (Lines.Count <> 1073) or (Lines[0] <> Header) then Halt(2);
    Fields.Delimiter := #9; Fields.StrictDelimiter := True;
    for I := 1 to Lines.Count - 1 do
    begin
      Fields.DelimitedText := Lines[I];
      if Fields.Count <> 4 then Halt(2);
      D := ParseCanonicalDay(Fields[0]);
      Expected := Fields[1];
      DirectTag := BigToDecimal(CountForDay(D));
      A := ComputeWorkCountsDecimal(Fields[0], Fields[0]);
      C := TMonsterContext.Create(D, D);
      try
        B := WorkCountsForContext(C);
      finally
        C.Free;
      end;
      A1 := BigToDecimal(A.Action); A2 := BigToDecimal(A.Target);
      B1 := BigToDecimal(B.Action); B2 := BigToDecimal(B.Target);
      Inc(Cases);
      if (DirectTag <> Expected) or (A1 <> Expected) or (A2 <> Expected)
        or (B1 <> Expected) or (B2 <> Expected) then
      begin
        Inc(Mismatches);
        Writeln('MISMATCH day=', Fields[0], ' expected=', Expected,
          ' direct=', DirectTag, ' decimal=', A1, '/', A2, ' context=', B1, '/', B2);
      end;
    end;
  finally
    Fields.Free; Lines.Free;
  end;
  Writeln('STAGE04_CASES=', Cases);
  Writeln('STAGE04_TAG_COMPARISONS=', Cases*5);
  Writeln('STAGE04_MISMATCH_ROWS=', Mismatches);
  if Mismatches <> 0 then Halt(1);
end.
